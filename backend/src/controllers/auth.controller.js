// ============================================================
//  auth.controller.js � Authentication Controller
//  VETO Legal Emergency App
//  Flow: Register → Request OTP → Verify OTP → JWT issued
// ============================================================

const logger    = require('../lib/logger');
const User      = require('../models/User');
const Lawyer    = require('../models/Lawyer');
const LoginLog  = require('../models/LoginLog');
const PasskeyChallenge = require('../models/PasskeyChallenge');
const { signToken } = require('../middleware/auth.middleware');
const {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} = require('@simplewebauthn/server');

const {
  cleanPhone,
  normalizePhoneForVeto,
  isAdminPhone,
} = require('../services/auth/phone.service');
const { generateOTP, otpExpiry } = require('../services/auth/otp.service');
const {
  findByPhone,
  modelFor,
  findAccountById,
  publicAccount,
} = require('../services/auth/account.service');
const { webauthnConfig } = require('../services/auth/webauthn.service');

// ── Helper: persist login attempt log ─────────────────────────
async function logEvent(data) {
  try {
    await LoginLog.create(data);
  } catch {
    /* ignore log failures */
  }
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

    logger.info({ phone: normalizedPhone, role }, '[AUTH] OTP requested');

    logEvent({ phone: normalizedPhone, role, event: 'otp_request', success: true, user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    const isProd = process.env.NODE_ENV === 'production';
    const twilioConfigured = !!(
      process.env.TWILIO_ACCOUNT_SID &&
      process.env.TWILIO_AUTH_TOKEN
    );
    const returnOtpInJson =
      process.env.RETURN_OTP_IN_JSON === '1' ||
      process.env.RETURN_OTP_IN_JSON === 'true';

    // Dev: always include OTP in JSON (unchanged).
    // Prod without Twilio: include OTP in JSON so hosted stacks (e.g. Render) work without SMS.
    // Prod with Twilio: omit OTP from JSON unless RETURN_OTP_IN_JSON is set (e.g. QA).
    const includeOtpInResponse =
      !isProd || !twilioConfigured || returnOtpInJson;

    // Only ever write the OTP value itself to logs on the same paths where it's also
    // returned in the JSON response (dev / no-Twilio hosts / explicit QA opt-in). When
    // Twilio is the real delivery channel, the OTP must stay out of both the response
    // AND the logs — previously this line logged it unconditionally in every case.
    if (includeOtpInResponse) {
      logger.debug({ phone: normalizedPhone, otp }, '[AUTH] OTP value (dev/no-SMS path only)');
    }

    if (isProd && !twilioConfigured) {
      logger.warn(
        '[AUTH] Twilio not configured in production — OTP is returned in JSON for login. Add Twilio when ready for SMS-only delivery.',
      );
    }

    if (isProd && twilioConfigured && returnOtpInJson) {
      logger.warn(
        '[AUTH] RETURN_OTP_IN_JSON is set while Twilio is configured — OTP is still included in JSON. Unset RETURN_OTP_IN_JSON when SMS-only is desired.',
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
        logger.info({ phone: normalizedPhone }, '[AUTH] promoted to ADMIN');
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

const passkeyRegisterOptions = async (req, res, next) => {
  try {
    const account = await findAccountById(req.user.userId, req.user.role, true);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    const { rpName, rpID } = webauthnConfig(req);
    const passkeys = account.doc.passkeys || [];
    const options = await generateRegistrationOptions({
      rpName,
      rpID,
      userID: Buffer.from(String(account.doc._id)),
      userName: account.doc.email || account.doc.phone || String(account.doc._id),
      userDisplayName: account.doc.full_name || 'VETO user',
      attestationType: 'none',
      excludeCredentials: passkeys.map((p) => ({
        id: p.credential_id,
        transports: p.transports || [],
      })),
      authenticatorSelection: {
        residentKey: 'preferred',
        userVerification: 'preferred',
      },
    });
    await PasskeyChallenge.findOneAndUpdate(
      { account_id: account.doc._id, role: account.role, purpose: 'register' },
      {
        challenge: options.challenge,
        expires_at: new Date(Date.now() + 5 * 60 * 1000),
      },
      { upsert: true, new: true },
    );
    res.json({ options });
  } catch (err) { next(err); }
};

const passkeyRegisterVerify = async (req, res, next) => {
  try {
    const account = await findAccountById(req.user.userId, req.user.role, true);
    if (!account) return res.status(404).json({ error: 'Account not found.' });
    const challengeDoc = await PasskeyChallenge.findOne({
      account_id: account.doc._id,
      role: account.role,
      purpose: 'register',
      expires_at: { $gt: new Date() },
    });
    if (!challengeDoc) return res.status(400).json({ error: 'Passkey challenge expired.' });

    const { rpID, origin } = webauthnConfig(req);
    const verification = await verifyRegistrationResponse({
      response: req.body?.response,
      expectedChallenge: challengeDoc.challenge,
      expectedOrigin: origin,
      expectedRPID: rpID,
    });
    if (!verification.verified || !verification.registrationInfo?.credential) {
      return res.status(400).json({ error: 'Passkey registration failed.' });
    }
    const credential = verification.registrationInfo.credential;
    const existing = (account.doc.passkeys || []).some((p) => p.credential_id === credential.id);
    if (!existing) {
      account.doc.passkeys.push({
        credential_id: credential.id,
        public_key: Buffer.from(credential.publicKey),
        counter: credential.counter || 0,
        transports: req.body?.response?.response?.transports || [],
        device_name: req.body?.deviceName || 'Passkey',
      });
      await account.doc.save();
    }
    await PasskeyChallenge.deleteOne({ _id: challengeDoc._id });
    res.json({ success: true, passkeyCount: account.doc.passkeys.length });
  } catch (err) { next(err); }
};

const passkeyLoginOptions = async (req, res, next) => {
  try {
    const normalizedPhone = normalizePhoneForVeto(req.body?.phone);
    if (!normalizedPhone) return res.status(400).json({ error: 'Valid phone is required.' });
    const found = await findByPhone(normalizedPhone);
    if (!found) return res.status(404).json({ error: 'Account not found.' });
    const account = await findAccountById(found.doc._id, found.role, true);
    const passkeys = account?.doc.passkeys || [];
    if (passkeys.length === 0) return res.status(404).json({ error: 'No passkey is registered for this account.' });
    const { rpID } = webauthnConfig(req);
    const options = await generateAuthenticationOptions({
      rpID,
      userVerification: 'preferred',
      allowCredentials: passkeys.map((p) => ({
        id: p.credential_id,
        transports: p.transports || [],
      })),
    });
    await PasskeyChallenge.findOneAndUpdate(
      { account_id: account.doc._id, role: account.role, purpose: 'login' },
      {
        challenge: options.challenge,
        expires_at: new Date(Date.now() + 5 * 60 * 1000),
      },
      { upsert: true, new: true },
    );
    res.json({ options, account: publicAccount(account.doc, account.role) });
  } catch (err) { next(err); }
};

const passkeyLoginVerify = async (req, res, next) => {
  try {
    const normalizedPhone = normalizePhoneForVeto(req.body?.phone);
    if (!normalizedPhone) return res.status(400).json({ error: 'Valid phone is required.' });
    const found = await findByPhone(normalizedPhone);
    if (!found) return res.status(404).json({ error: 'Account not found.' });
    const account = await findAccountById(found.doc._id, found.role, true);
    const challengeDoc = await PasskeyChallenge.findOne({
      account_id: account.doc._id,
      role: account.role,
      purpose: 'login',
      expires_at: { $gt: new Date() },
    });
    if (!challengeDoc) return res.status(400).json({ error: 'Passkey challenge expired.' });

    const credentialId = req.body?.response?.id;
    const passkey = (account.doc.passkeys || []).find((p) => p.credential_id === credentialId);
    if (!passkey) return res.status(404).json({ error: 'Passkey not found for this account.' });

    const { rpID, origin } = webauthnConfig(req);
    const verification = await verifyAuthenticationResponse({
      response: req.body?.response,
      expectedChallenge: challengeDoc.challenge,
      expectedOrigin: origin,
      expectedRPID: rpID,
      credential: {
        id: passkey.credential_id,
        publicKey: passkey.public_key,
        counter: passkey.counter || 0,
        transports: passkey.transports || [],
      },
    });
    if (!verification.verified) return res.status(400).json({ error: 'Passkey login failed.' });

    passkey.counter = verification.authenticationInfo?.newCounter || passkey.counter || 0;
    passkey.last_used_at = new Date();
    if (account.role === 'lawyer' && !account.doc.is_approved) {
      return res.status(403).json({ error: 'Lawyer account is pending admin approval.' });
    }
    await account.doc.save();
    await PasskeyChallenge.deleteOne({ _id: challengeDoc._id });
    logEvent({ phone: normalizedPhone, role: account.role, event: 'passkey_login', success: true, user_id: account.doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    const token = signToken({ userId: account.doc._id, role: account.role });
    const baseUser = publicAccount(account.doc, account.role);
    const user =
      account.role === 'user' || account.role === 'admin'
        ? {
            ...baseUser,
            onboarding_completed: account.doc.onboarding_completed ?? false,
          }
        : baseUser;
    res.json({ token, role: account.role, user });
  } catch (err) { next(err); }
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
    logger.warn(
      '[AUTH] ALLOW_DEV_LOGIN is set: POST /auth/dev-login is enabled on production. Remove for real production.',
    );
  }

  const {
    username = '',
    password = '',
    role = 'admin',
  } = req.body || {};

  const expectedUsername = (process.env.DEV_LOGIN_USERNAME || 'SYSYBU@GMAIL.COM').toUpperCase();
  const expectedPassword = process.env.DEV_LOGIN_PASSWORD || '0525640021';
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
    logger.error({ err }, '[AUTH] dev-login getOrCreateDevAccount failed');
    return res.status(500).json({
      error: 'Could not prepare dev session. Check MongoDB and shadow phone uniqueness.',
    });
  }
};

module.exports = {
  register,
  requestOTP,
  verifyOTP,
  googleAuth,
  devLogin,
  passkeyRegisterOptions,
  passkeyRegisterVerify,
  passkeyLoginOptions,
  passkeyLoginVerify,
};
