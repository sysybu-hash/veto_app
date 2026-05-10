// ============================================================
//  auth.controller.js � Authentication Controller
//  VETO Legal Emergency App
//  Flow: Register → Request OTP → Verify OTP → JWT issued
// ============================================================

const crypto = require('crypto');
const User      = require('../models/User');
const Lawyer    = require('../models/Lawyer');
const LoginLog  = require('../models/LoginLog');
const { signToken } = require('../middleware/auth.middleware');

// ── Helper: persist login attempt log ─────────────────────────
async function logEvent(data) {
  try {
    await LoginLog.create(data);
  } catch {
    /* ignore log failures */
  }
}

// ── Helpers ─────────────────────────────────────────────────

/** Generate a cryptographically-safe 6-digit OTP */
function generateOTP() {
  return String(crypto.randomInt(100000, 1000000));
}

/** OTP valid for 10 minutes */
function otpExpiry() {
  return new Date(Date.now() + 10 * 60 * 1000);
}

/**
 * Find a document in both User and Lawyer collections by phone.
 * Returns { doc, role } or null.
 */
async function findByPhone(phone) {
  const user = await User.findOne({ phone });
  if (user) {
    const appRole = user.role === 'admin' ? 'admin' : 'user';
    return { doc: user, role: appRole };
  }

  const lawyer = await Lawyer.findOne({ phone });
  if (lawyer) return { doc: lawyer, role: 'lawyer' };

  return null;
}

/** Choose the right Model based on role string */
function modelFor(role) {
  if (role === 'lawyer') return Lawyer;
  return User;
}

/** Normalize phone: remove + for comparison */
function cleanPhone(phone) {
  return String(phone).replace(/\+/g, '');
}

/**
 * Normalize user input to E.164 (+...) as stored in User/Lawyer.
 * Accepts +972501111111, 972501111111, 0501111111, 501111111 (IL mobile), other intl digits.
 */
function normalizePhoneForVeto(raw) {
  if (raw == null) return null;
  const trimmed = String(raw).trim();
  if (!trimmed) return null;

  const s = trimmed.replace(/[\s\-().]/g, '');
  if (!s) return null;

  let d;
  if (s.startsWith('+')) {
    d = s.slice(1).replace(/\D/g, '');
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  d = s.replace(/\D/g, '');
  if (!d) return null;

  if (d.startsWith('972')) {
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  if (d.startsWith('0')) {
    const rest = d.slice(1);
    if (!/^[1-9]\d{6,12}$/.test(rest)) return null;
    return `+972${rest}`;
  }

  if (d.length === 9 && d.startsWith('5')) {
    return `+972${d}`;
  }

  if (/^[1-9]\d{7,14}$/.test(d)) {
    return `+${d}`;
  }

  return null;
}

/** Check if phone belongs to a hardcoded admin */
function isAdminPhone(phone) {
  const clean = cleanPhone(phone);
  return clean === '972525640021' || clean === '972506400030';
}

// ============================================================
//  POST /auth/register
//  Body: { full_name, phone, role, preferred_language,
//          email?, license_number? (lawyer only) }
// ============================================================
const register = async (req, res, next) => {
  try {
    const {
      full_name,
      phone,
      role = 'user',
      preferred_language = 'en',
      email,
      license_number,
      specializations,
      years_of_experience,
    } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({ error: 'full_name and phone are required.' });
    }
    if (!['user', 'lawyer'].includes(role)) {
      return res.status(400).json({ error: 'role must be "user" or "lawyer".' });
    }

    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      return res.status(400).json({ error: 'Invalid phone number.' });
    }

    const existing = await findByPhone(normalizedPhone);
    if (existing) {
      return res.status(409).json({ error: 'An account with this phone already exists.' });
    }

    const Model   = modelFor(role);
    const payload = { full_name, phone: normalizedPhone, preferred_language };
    if (email)          payload.email          = email;
    if (license_number) payload.license_number = license_number;
    if (role === 'lawyer') {
      if (Array.isArray(specializations)) payload.specializations = specializations;
      if (years_of_experience !== undefined) {
        payload.years_of_experience = Math.max(0, Number(years_of_experience) || 0);
      }
      payload.is_approved = false;
      payload.is_verified = false;
    }

    const newDoc = await Model.create(payload);

    logEvent({ phone: normalizedPhone, email: email || null, role, event: 'register', success: true, user_id: newDoc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    return res.status(201).json({
      message: 'Account created. Please verify your phone.',
      id:      newDoc._id,
      role,
    });
  } catch (err) {
    if (err.code === 11000) {
      logEvent({ phone: req.body.phone, role: req.body.role, event: 'register', success: false, error_msg: 'duplicate', ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(409).json({ error: 'Account already exists.' });
    }
    next(err);
  }
};

// ============================================================
//  POST /auth/request-otp
//  Admin phones → fixed OTP 123456 in DB
//  Others → random 6-digit in DB; SMS via Twilio when TWILIO_* env is set.
//  If Twilio is not configured, OTP is also returned in JSON so the app can show it (until SMS is live).
// ============================================================
const requestOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'phone is required.' });

    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      return res.status(400).json({ error: 'Invalid phone number.' });
    }

    const found = await findByPhone(normalizedPhone);
    if (!found) {
      logEvent({ phone: normalizedPhone, event: 'otp_request', success: false, error_msg: 'not_found', ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(404).json({
        error: 'No account found with this phone number. Please register first.',
      });
    }

    const { doc, role } = found;
    const useFixed = isAdminPhone(normalizedPhone) || process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';

    const otp = useFixed ? '123456' : generateOTP();
    doc.otp_code       = otp;
    doc.otp_expires_at = otpExpiry();
    await doc.save();
    console.log(`[AUTH] OTP for ${normalizedPhone}: ${otp}`);

    console.log(`[AUTH] OTP requested for ${normalizedPhone} (role: ${role})`);

    logEvent({ phone: normalizedPhone, role, event: 'otp_request', success: true, user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    const isProd = process.env.NODE_ENV === 'production';
    const twilioConfigured = !!(
      process.env.TWILIO_ACCOUNT_SID &&
      process.env.TWILIO_AUTH_TOKEN
    );
    /** Explicit opt-in (e.g. local/staging with NODE_ENV=production): return OTP in JSON */
    const returnOtpInJson =
      process.env.RETURN_OTP_IN_JSON === '1' ||
      process.env.RETURN_OTP_IN_JSON === 'true';

    // Development / staging tests: always expose OTP unless hard production without flag.
    const includeOtpInResponse = !isProd || returnOtpInJson;

    if (isProd && returnOtpInJson) {
      console.warn(
        '[AUTH] RETURN_OTP_IN_JSON is set: OTP is included in JSON responses. Turn off for real production.',
      );
    }

    if (isProd && !twilioConfigured) {
      console.warn(
        'CRITICAL: Twilio is not configured in production. SMS will not be sent.',
      );
    }

    return res.status(200).json({
      success: true,
      message: 'OTP generated successfully',
      role,
      otp: includeOtpInResponse ? otp : undefined,
      expiresIn: '5m',
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  POST /auth/verify-otp
//  Body: { phone, otp } — compared to otp_code stored on the user/lawyer document.
// ============================================================
const verifyOTP = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'phone and otp are required.' });
    }

    const normalizedPhone = normalizePhoneForVeto(phone);
    if (!normalizedPhone) {
      return res.status(400).json({ error: 'Invalid phone number.' });
    }

    let doc, role;
    const user = await User.findOne({ phone: normalizedPhone }).select('+otp_code +otp_expires_at');
    if (user) {
      doc = user;

      // Auto-promote admin phones
      if (isAdminPhone(normalizedPhone) && doc.role !== 'admin') {
        doc.role = 'admin';
        await doc.save();
        console.log(`[AUTH] ${normalizedPhone} promoted to ADMIN.`);
      }

      role = doc.role === 'admin' ? 'admin' : 'user';
    } else {
      const lawyer = await Lawyer.findOne({ phone: normalizedPhone }).select('+otp_code +otp_expires_at');
      if (lawyer) { doc = lawyer; role = 'lawyer'; }
    }

    if (!doc) {
      logEvent({ phone: normalizedPhone, event: 'otp_fail', success: false, error_msg: 'not_found', ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(404).json({ error: 'Account not found.' });
    }

    // Lawyers must be approved by admin before they can log in
    if (role === 'lawyer' && !doc.is_approved) {
      return res.status(403).json({
        error: 'חשבון עורך הדין שלך ממתין לאישור מנהל. תקבל הודעה בקרוב.',
        pending_approval: true,
      });
    }

    // ── Validate against DB OTP ────────────────────────
    if (!doc.otp_code || doc.otp_code !== String(otp)) {
      logEvent({ phone: normalizedPhone, role, event: 'otp_fail', success: false, error_msg: 'invalid_otp', user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(401).json({ error: 'Invalid OTP.' });
    }
    if (!doc.otp_expires_at || doc.otp_expires_at < new Date()) {
      logEvent({ phone: normalizedPhone, role, event: 'otp_fail', success: false, error_msg: 'otp_expired', user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(401).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // ?? Mark verified + clear OTP ?????????????????????
    doc.is_verified    = true;
    doc.otp_code       = undefined;
    doc.otp_expires_at = undefined;
    await doc.save();

    // ?? Issue JWT ??????????????????????????????????????
    const token = signToken({
      userId:             doc._id.toString(),
      role,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
    });

    // Compute payment exemption: admin, lawyer, or manually_added user
    const isPaymentExempt = role === 'admin' || role === 'lawyer' || doc.manually_added === true;
    const onboarding_completed =
      role === 'admin' || role === 'lawyer' ? true : (doc.onboarding_completed ?? false);

    logEvent({ phone: normalizedPhone, role, event: 'otp_success', success: true, user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    return res.status(200).json({
      message: 'Verification successful.',
      token,
      user: {
        id:                  doc._id,
        full_name:           doc.full_name,
        phone:               doc.phone,
        role,
        preferred_language:  doc.preferred_language,
        is_verified:         true,
        is_subscribed:       doc.is_subscribed    ?? false,
        subscription_expiry: doc.subscription_expiry ?? null,
        manually_added:      doc.manually_added   ?? false,
        is_payment_exempt:   isPaymentExempt,
        onboarding_completed: onboarding_completed,
      },
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  POST /auth/google
//  Body: { id_token, preferred_language? }
//  Verifies a Google ID token, creates or finds the user, issues JWT.
// ============================================================
const googleAuth = async (req, res, next) => {
  try {
    const { id_token, access_token, preferred_language = 'he' } = req.body;
    if (!id_token && !access_token) {
      return res.status(400).json({ error: 'id_token or access_token is required.' });
    }

    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) {
      return res.status(503).json({ error: 'Google OAuth not configured on this server.' });
    }

    let googleId, email, name;

    if (id_token) {
      // ── Verify via ID token ──────────────────────────────────
      const { OAuth2Client } = require('google-auth-library');
      const oauthClient = new OAuth2Client(clientId);
      let gPayload;
      try {
        const ticket = await oauthClient.verifyIdToken({ idToken: id_token, audience: clientId });
        gPayload = ticket.getPayload();
      } catch {
        return res.status(401).json({ error: 'Invalid Google token.' });
      }
      googleId = gPayload.sub;
      email    = gPayload.email;
      name     = gPayload.name || '';
    } else {
      // ── Verify via access token → Google Userinfo endpoint ───
      let userInfo;
      try {
        const uRes = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
          headers: { Authorization: `Bearer ${access_token}` },
        });
        if (!uRes.ok) return res.status(401).json({ error: 'Invalid Google access token.' });
        userInfo = await uRes.json();
      } catch {
        return res.status(401).json({ error: 'Could not verify Google access token.' });
      }
      googleId = userInfo.id;
      email    = userInfo.email;
      name     = userInfo.name || '';
    }

    let doc;
    doc = await User.findOne({ google_id: googleId });
    if (!doc && email) doc = await User.findOne({ email });

    if (doc) {
      if (!doc.google_id) { doc.google_id = googleId; await doc.save(); }
    } else {
      doc = await User.create({
        full_name:          name,
        email:              email || undefined,
        google_id:          googleId,
        role:               'user',
        preferred_language,
        is_verified:        true,
      });
    }

    const userRole = doc.role === 'admin' ? 'admin' : 'user';
    const token    = signToken({
      userId:             doc._id.toString(),
      role:               userRole,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
    });

    const isPaymentExempt = userRole === 'admin' || userRole === 'lawyer' || doc.manually_added === true;
    const onboarding_completed =
      userRole === 'admin' || userRole === 'lawyer' ? true : (doc.onboarding_completed ?? false);

    logEvent({ email, role: userRole, event: 'google_login', success: true, user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    return res.status(200).json({
      message: 'Google authentication successful.',
      token,
      user: {
        id:                  doc._id,
        full_name:           doc.full_name,
        email:               doc.email,
        role:                userRole,
        preferred_language:  doc.preferred_language,
        is_verified:         true,
        is_subscribed:       doc.is_subscribed    ?? false,
        subscription_expiry: doc.subscription_expiry ?? null,
        manually_added:      doc.manually_added   ?? false,
        is_payment_exempt:   isPaymentExempt,
        onboarding_completed: onboarding_completed,
      },
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  POST /auth/dev-login
//  Body: { username, password, role }
//  Development-only login for local QA role switching.
/**
 * Shadow accounts for dev-login — real Mongo ids so /api/users/me and PUT work.
 * Override phones via env if +1000… conflicts with your data.
 */
async function getOrCreateDevAccount(appRole) {
  const shadowPhoneUser =
    process.env.DEV_LOGIN_USER_PHONE?.trim() || '+10000000001';
  const shadowPhoneAdmin =
    process.env.DEV_LOGIN_ADMIN_PHONE?.trim() || '+10000000002';
  const shadowPhoneLawyer =
    process.env.DEV_LOGIN_LAWYER_PHONE?.trim() || '+10000000003';

  if (appRole === 'lawyer') {
    let doc = await Lawyer.findOne({ phone: shadowPhoneLawyer });
    if (!doc) {
      doc = await Lawyer.create({
        full_name: 'Dev Lawyer',
        phone: shadowPhoneLawyer,
        is_verified: true,
        is_approved: true,
        preferred_language: 'he',
      });
    } else if (!doc.is_approved) {
      doc.is_approved = true;
      await doc.save();
    }
    return { doc, jwtRole: 'lawyer' };
  }

  const phone =
    appRole === 'admin' ? shadowPhoneAdmin : shadowPhoneUser;
  let doc = await User.findOne({ phone });
  if (!doc) {
    doc = await User.create({
      full_name: appRole === 'admin' ? 'Dev Admin' : 'Dev User',
      phone,
      role: appRole === 'admin' ? 'admin' : 'user',
      preferred_language: 'he',
      is_verified: true,
      onboarding_completed: appRole === 'admin',
    });
  }
  const jwtRole = appRole === 'admin' ? 'admin' : 'user';
  return { doc, jwtRole };
}

// ============================================================
const devLogin = async (req, res) => {
  const allowInProd =
    process.env.ALLOW_DEV_LOGIN === '1' ||
    process.env.ALLOW_DEV_LOGIN === 'true';
  const devLoginAllowed =
    process.env.NODE_ENV !== 'production' || allowInProd;

  if (!devLoginAllowed) {
    return res.status(403).json({ error: 'Dev login is disabled in production.' });
  }

  if (process.env.NODE_ENV === 'production' && allowInProd) {
    console.warn(
      '[AUTH] ALLOW_DEV_LOGIN is set: POST /auth/dev-login is enabled on production. Remove for real production.',
    );
  }

  const {
    username = '',
    password = '',
    role = 'admin',
  } = req.body || {};

  const expectedUsername = (process.env.DEV_LOGIN_USERNAME || '***REDACTED***').toUpperCase();
  const expectedPassword = process.env.DEV_LOGIN_PASSWORD || '***REDACTED***';
  const normalizedUsername = String(username).trim().toUpperCase();

  if (normalizedUsername !== expectedUsername || String(password).trim() !== expectedPassword) {
    return res.status(401).json({ error: 'שם משתמש או סיסמה לא נכונים' });
  }

  const normalizedRole = ['admin', 'lawyer', 'user', 'citizen'].includes(String(role))
    ? String(role)
    : 'admin';
  const appRole = normalizedRole === 'citizen' ? 'user' : normalizedRole;

  try {
    const { doc, jwtRole } = await getOrCreateDevAccount(appRole);
    const fullName =
      doc.full_name ||
      (jwtRole === 'lawyer' ? 'Dev Lawyer' : jwtRole === 'admin' ? 'Dev Admin' : 'Dev User');

    const token = signToken({
      userId: doc._id.toString(),
      role: jwtRole,
      full_name: fullName,
      preferred_language: doc.preferred_language || 'he',
    });

    const onboarding_completed =
      jwtRole === 'admin' || jwtRole === 'lawyer'
        ? true
        : (doc.onboarding_completed ?? false);

    return res.status(200).json({
      message: 'Dev login successful.',
      token,
      role: jwtRole,
      user: {
        id: doc._id,
        full_name: fullName,
        phone: doc.phone,
        role: jwtRole,
        preferred_language: doc.preferred_language || 'he',
        is_verified: true,
        onboarding_completed,
      },
    });
  } catch (err) {
    console.error('[AUTH] dev-login getOrCreateDevAccount:', err?.message || err);
    return res.status(500).json({
      error: 'Could not prepare dev session. Check MongoDB and shadow phone uniqueness.',
    });
  }
};

module.exports = { register, requestOTP, verifyOTP, googleAuth, devLogin };
