// ============================================================
//  Google Calendar OAuth2 (Calendar API) — not Google Sign-In
// ============================================================

const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const Lawyer = require('../models/Lawyer');
const { accountFromReq } = require('../utils/calendarAccount.util');
const { encryptToken } = require('../utils/gcalTokenCrypto.util');

const SCOPE = ['https://www.googleapis.com/auth/calendar.events'];
const STATE_TTL_MS = 15 * 60 * 1000;

function jwtSecret() {
  const s = process.env.JWT_SECRET;
  if (!s) throw new Error('JWT_SECRET is not set.');
  return s;
}

function gcalOAuthConfig() {
  const clientId = process.env.GOOGLE_CALENDAR_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CALENDAR_CLIENT_SECRET;
  const redirectUri = process.env.GCAL_OAUTH_REDIRECT_URI;
  return { clientId, clientSecret, redirectUri };
}

function isGcalConfigured() {
  const { clientId, clientSecret, redirectUri } = gcalOAuthConfig();
  return !!(clientId && clientSecret && redirectUri);
}

function makeState(userId, role) {
  const payload = {
    userId: String(userId),
    role,
    exp: Date.now() + STATE_TTL_MS,
  };
  const b64 = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', jwtSecret()).update(b64).digest('base64url');
  return `${b64}.${sig}`;
}

function parseState(state) {
  if (!state || typeof state !== 'string') return null;
  const parts = state.split('.');
  if (parts.length !== 2) return null;
  const [b64, sig] = parts;
  const exp = crypto.createHmac('sha256', jwtSecret()).update(b64).digest('base64url');
  if (exp !== sig) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(b64, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (!payload.userId || !payload.role || typeof payload.exp !== 'number') return null;
  if (Date.now() > payload.exp) return null;
  if (!['user', 'admin', 'lawyer'].includes(payload.role)) return null;
  return payload;
}

async function loadGcalAccount(userId, role) {
  if (role === 'lawyer') {
    const doc = await Lawyer.findById(userId).select(
      '+gcalRefreshTokenEnc +gcalEventsSyncToken gcalCalendarId gcalLastSyncAt',
    );
    return { Model: Lawyer, doc };
  }
  const doc = await User.findById(userId).select(
    '+gcalRefreshTokenEnc +gcalEventsSyncToken gcalCalendarId gcalLastSyncAt',
  );
  return { Model: User, doc };
}

exports.status = async (req, res, next) => {
  try {
    if (!isGcalConfigured()) {
      return res.json({
        enabled: false,
        connected: false,
        message: 'Google Calendar OAuth is not configured (missing env).',
      });
    }
    const { userId, role } = req.user;
    const { doc } = await loadGcalAccount(userId, role);
    if (!doc) return res.status(404).json({ error: 'Account not found' });
    const connected = !!doc.gcalRefreshTokenEnc;
    res.json({
      enabled: true,
      connected,
      calendarId: doc.gcalCalendarId || 'primary',
      lastSyncAt: doc.gcalLastSyncAt || null,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /connect — returns { authUrl } for mobile/web to open
 */
exports.connect = async (req, res, next) => {
  try {
    const { clientId, clientSecret, redirectUri } = gcalOAuthConfig();
    if (!clientId || !clientSecret || !redirectUri) {
      return res.status(503).json({
        error: 'Google Calendar OAuth is not configured.',
        hint: 'Set GOOGLE_CALENDAR_CLIENT_ID, GOOGLE_CALENDAR_CLIENT_SECRET, GCAL_OAUTH_REDIRECT_URI.',
      });
    }
    const { accountId } = accountFromReq(req);
    const role = req.user.role;
    const state = makeState(accountId, role);
    const oauth2Client = new OAuth2Client(clientId, clientSecret, redirectUri);
    const authUrl = oauth2Client.generateAuthUrl({
      access_type: 'offline',
      prompt: 'consent',
      scope: SCOPE,
      state,
    });
    res.json({ authUrl });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /callback — public (Google redirect)
 */
exports.oauthCallback = async (req, res, next) => {
  try {
    const { code, state, error, error_description: errDesc } = req.query;
    if (error) {
      const msg = errDesc || error;
      return res.status(400).type('html')
        .send(`<!doctype html><html><body><p>Google OAuth error: ${String(msg)}</p></body></html>`);
    }
    const st = parseState(state);
    if (!st || !code) {
      return res.status(400).type('html')
        .send('<!doctype html><html><body><p>Invalid or expired state, or missing code.</p></body></html>');
    }
    const { clientId, clientSecret, redirectUri } = gcalOAuthConfig();
    if (!clientId || !clientSecret || !redirectUri) {
      return res.status(503).type('html')
        .send('<!doctype html><html><body><p>Server OAuth not configured.</p></body></html>');
    }
    const oauth2Client = new OAuth2Client(clientId, clientSecret, redirectUri);
    const { tokens } = await oauth2Client.getToken(String(code));
    const refresh = tokens.refresh_token;
    if (!refresh) {
      return res.status(400).type('html')
        .send(
          '<!doctype html><html><body><p>No refresh token received. '
            + 'Revoke VETO access in your Google account and try again (consent required).</p></body></html>',
        );
    }
    const enc = encryptToken(refresh);
    const { Model } = await loadGcalAccount(st.userId, st.role);
    await Model.findByIdAndUpdate(st.userId, {
      gcalRefreshTokenEnc: enc,
      gcalCalendarId: 'primary',
      gcalEventsSyncToken: null,
    });

    const success = process.env.GCAL_OAUTH_SUCCESS_REDIRECT;
    if (success && String(success).startsWith('http')) {
      return res.redirect(302, success);
    }
    return res.type('html').send(
      '<!doctype html><html><head><meta charset="utf-8"><title>VETO</title></head>'
        + '<body style="font-family:system-ui;padding:24px"><p>Google Calendar connected. You can close this tab.</p></body></html>',
    );
  } catch (err) {
    next(err);
  }
};

exports.disconnect = async (req, res, next) => {
  try {
    const { userId, role } = req.user;
    const { Model, doc } = await loadGcalAccount(userId, role);
    if (!doc) return res.status(404).json({ error: 'Account not found' });
    await Model.findByIdAndUpdate(userId, {
      $unset: { gcalRefreshTokenEnc: '', gcalEventsSyncToken: '' },
      $set: { gcalLastSyncAt: null },
    });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};
