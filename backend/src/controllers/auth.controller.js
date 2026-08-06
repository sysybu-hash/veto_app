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
  normalizePhoneForVeto,
  isAdminPhone,
  shouldUseFixedAdminOtp,
} = require('../services/auth/phone.service');
const { generateOTP, otpExpiry } = require('../services/auth/otp.service');
const { twilioConfigured, sendOtpSms } = require('../services/auth/sms.service');
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

    // A family-plan owner may have reserved a seat for this number before the
    // person had an account. Claim it now so the owner does not have to come
    // back and add them by hand. Best-effort: never fail a registration over
    // it — the service swallows its own errors and returns null.
    let joinedFamilyPlan = false;
    if (role === 'user') {
      const { claimInviteForNewUser } = require('../services/familyPlan.service');
      joinedFamilyPlan = Boolean(await claimInviteForNewUser(newDoc));
    }

    logEvent({ phone: normalizedPhone, email: email || null, role, event: 'register', success: true, user_id: newDoc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    return res.status(201).json({
      message: 'Account created. Please verify your phone.',
      id:      newDoc._id,
      role,
      joinedFamilyPlan,
    });
  } catch (err) {
    if (err.code === 11000) {
      logEvent({ phone: req.body.phone, role: req.body.role, event: 'register', success: false, error_msg: 'duplicate', ip: req.ip, user_agent: req.headers['user-agent'] });
      return res.status(409).json({ error: 'Account already exists.' });
    }
    next(err);
  }
};

// Never true in production, regardless of any env var — closed by construction
// after the 2026-08-01 finding that RETURN_OTP_IN_JSON (meant for local/CI use,
// since SMS delivery isn't implemented at all) was leaking live OTP codes back
// to any caller in production. Only non-production environments (local dev,
// CI, the E2E suite) see the OTP in the response.
function otpVisibleInResponse() {
  return process.env.NODE_ENV !== 'production';
}

// ============================================================
//  POST /auth/request-otp
//  Admin phones → fixed OTP 123456 in DB
//  Others → random 6-digit in DB; SMS via Twilio when TWILIO_* env is set.
//  In production, the OTP is never returned in the response — see
//  otpVisibleInResponse() above. Without Twilio configured, phone/OTP login
//  has no way to deliver the code to the user until SMS is wired up.
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
    // Fixed admin OTP only outside production (never ENABLE_FIXED_OTP_FOR_ADMINS for all users).
    const useFixed = shouldUseFixedAdminOtp(normalizedPhone);

    const otp = useFixed ? '123456' : generateOTP();
    doc.otp_code       = otp;
    doc.otp_expires_at = otpExpiry();
    await doc.save();

    logger.info({ phone: normalizedPhone, role }, '[AUTH] OTP requested');

    logEvent({ phone: normalizedPhone, role, event: 'otp_request', success: true, user_id: doc._id, ip: req.ip, user_agent: req.headers['user-agent'] });

    const isProd = process.env.NODE_ENV === 'production';
    const includeOtpInResponse = otpVisibleInResponse();

    if (includeOtpInResponse) {
      logger.debug({ phone: normalizedPhone, otp }, '[AUTH] OTP value (non-production only)');
    }

    if (twilioConfigured()) {
      try {
        await sendOtpSms(normalizedPhone, otp);
      } catch (smsErr) {
        logger.error({ err: smsErr, phone: normalizedPhone }, '[AUTH] Failed to send OTP via SMS');
        // Without SMS, there's no other delivery channel for this code —
        // surface a real error instead of silently succeeding with a code
        // the user has no way to receive (see the 2026-08-01 finding above).
        if (!includeOtpInResponse) {
          return res.status(502).json({
            error: 'Could not send the verification code. Please try again shortly.',
          });
        }
      }
    } else if (isProd) {
      logger.warn(
        '[AUTH] Twilio not configured in production — OTP cannot be delivered to the user at all until SMS is wired up. Phone/OTP login is effectively unusable in production until then.',
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

    const normalizedEmail = email
      ? String(email).trim().toLowerCase()
      : null;

    let doc;
    doc = await User.findOne({ google_id: googleId });
    if (!doc && normalizedEmail) {
      doc = await User.findOne({ email: normalizedEmail });
    }

    if (doc) {
      let dirty = false;
      if (!doc.google_id) {
        doc.google_id = googleId;
        dirty = true;
      }
      if (normalizedEmail && !doc.email) {
        doc.email = normalizedEmail;
        dirty = true;
      }
      if (dirty) await doc.save();
    } else {
      // Google-only users have no phone. Mongoose `save()` can still persist
      // `phone: null`, which collides on the legacy sparse unique index. Insert
      // via the native driver (omit phone entirely) and repair old null phones.
      const unsetNullPhones = async () => {
        const result = await User.updateMany(
          { $or: [{ phone: null }, { phone: '' }] },
          { $unset: { phone: '' } },
        );
        if (result.modifiedCount > 0) {
          logger.warn(
            { modifiedCount: result.modifiedCount },
            '[AUTH] Unset null/empty phone fields to repair sparse unique index',
          );
        }
        return result.modifiedCount || 0;
      };

      const insertGoogleOnlyUser = async () => {
        const now = new Date();
        const payload = {
          full_name:
            name ||
            (normalizedEmail ? normalizedEmail.split('@')[0] : 'VETO User'),
          google_id: googleId,
          role: 'user',
          preferred_language,
          is_verified: true,
          createdAt: now,
          updatedAt: now,
        };
        if (normalizedEmail) payload.email = normalizedEmail;
        // Do not set phone at all — missing ≠ null for unique indexes.
        const inserted = await User.collection.insertOne(payload);
        return User.findById(inserted.insertedId);
      };

      const resolveDup = async (err, depth = 0) => {
        if (depth > 2) return null;
        const field = Object.keys(err.keyValue || {})[0] || 'email';
        const dupVal = err.keyValue ? err.keyValue[field] : undefined;
        logger.warn(
          { field, dupVal, googleId, email: normalizedEmail, depth },
          '[AUTH] Google user create hit duplicate key',
        );
        if (field === 'google_id') {
          return User.findOne({ google_id: googleId });
        }
        if (field === 'email' && normalizedEmail) {
          return User.findOne({ email: normalizedEmail });
        }
        if (
          field === 'phone' &&
          (dupVal === null || dupVal === undefined || dupVal === '')
        ) {
          await unsetNullPhones();
          try {
            return await insertGoogleOnlyUser();
          } catch (retryErr) {
            if (retryErr && retryErr.code === 11000) {
              return resolveDup(retryErr, depth + 1);
            }
            throw retryErr;
          }
        }
        return null;
      };

      await unsetNullPhones();
      try {
        doc = await insertGoogleOnlyUser();
      } catch (createErr) {
        if (createErr && createErr.code === 11000) {
          doc = await resolveDup(createErr);
          if (doc) {
            if (!doc.google_id) {
              doc.google_id = googleId;
              await doc.save();
            }
          } else {
            const field = Object.keys(createErr.keyValue || {})[0] || 'email';
            const dupVal = createErr.keyValue
              ? createErr.keyValue[field]
              : undefined;
            if (
              field === 'phone' &&
              (dupVal === null || dupVal === undefined || dupVal === '')
            ) {
              return res.status(503).json({
                error:
                  'Account create is blocked by a phone-index repair. Please try Google sign-in again in a moment.',
                code: 'PHONE_INDEX_REPAIR',
              });
            }
            if (field === 'phone') {
              return res.status(409).json({
                error: 'An account with this phone already exists.',
                code: 'DUPLICATE_PHONE',
              });
            }
            return res.status(409).json({
              error:
                'An account with this Google email already exists. Try signing in again.',
              code: 'DUPLICATE_EMAIL',
            });
          }
        } else {
          throw createErr;
        }
      }
    }

    if (!doc) {
      return res.status(500).json({ error: 'Could not create or load Google account.' });
    }

    const userRole = doc.role === 'admin' ? 'admin' : 'user';
    // Owner flag: lets one specific, real Google-verified identity switch
    // between citizen/lawyer/admin views via POST /auth/view-as, replacing
    // the old shared-password dev-login bypass (see viewAs below).
    const ownerEmail = process.env.OWNER_EMAIL;
    const isOwner = Boolean(
      ownerEmail && doc.email && doc.email.toLowerCase() === ownerEmail.toLowerCase(),
    );
    const token    = signToken({
      userId:             doc._id.toString(),
      role:               userRole,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
      isOwner,
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
        is_owner:            isOwner,
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
 * Shadow accounts for role-switching — real Mongo ids so /api/users/me and
 * PUT work. Used both by dev-login (local/CI only) and by the owner-only
 * /auth/view-as endpoint below. Override phones via env if +1000… conflicts
 * with your data.
 */
async function getOrCreateShadowAccount(appRole) {
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
//  Gate is deliberately default-closed and has NO production override:
//  unlike the old `ALLOW_DEV_LOGIN` flag (which could — and on 2026-07-29,
//  did — leave this reachable on live production via a misconfigured env
//  var), this can NEVER run when NODE_ENV==='production', regardless of
//  any other env var. Real production role-switching goes through the
//  Google-authenticated /auth/view-as endpoint below instead.
const devLogin = async (req, res) => {
  const devLoginAllowed =
    process.env.NODE_ENV !== 'production' && process.env.DEV_LOGIN_ENABLED === '1';

  if (!devLoginAllowed) {
    return res.status(403).json({ error: 'Dev login is disabled.' });
  }

  const expectedUsername = process.env.DEV_LOGIN_USERNAME?.trim().toUpperCase();
  const expectedPassword = process.env.DEV_LOGIN_PASSWORD?.trim();
  if (!expectedUsername || !expectedPassword) {
    return res.status(503).json({
      error: 'Dev login is enabled but DEV_LOGIN_USERNAME/DEV_LOGIN_PASSWORD are not set.',
    });
  }

  const {
    username = '',
    password = '',
    role = 'admin',
  } = req.body || {};

  const normalizedUsername = String(username).trim().toUpperCase();

  if (normalizedUsername !== expectedUsername || String(password).trim() !== expectedPassword) {
    return res.status(401).json({ error: 'שם משתמש או סיסמה לא נכונים' });
  }

  const normalizedRole = ['admin', 'lawyer', 'user', 'citizen'].includes(String(role))
    ? String(role)
    : 'admin';
  const appRole = normalizedRole === 'citizen' ? 'user' : normalizedRole;

  try {
    const { doc, jwtRole } = await getOrCreateShadowAccount(appRole);
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
    logger.error({ err }, '[AUTH] dev-login getOrCreateShadowAccount failed');
    return res.status(500).json({
      error: 'Could not prepare dev session. Check MongoDB and shadow phone uniqueness.',
    });
  }
};

// ============================================================
//  POST /auth/view-as
//  Body: { role: 'citizen' | 'lawyer' | 'admin' }
//  Owner-only role switcher: replaces the old dev-login bypass for real
//  production use. Requires a real, Google-verified `isOwner` JWT (see
//  googleAuth above, gated by the OWNER_EMAIL env var) — not a shared
//  password. Issues a new JWT for the requested role, itself still carrying
//  `isOwner: true`, so the owner can keep switching from any view without
//  returning to the original token.
// ============================================================
const viewAs = async (req, res) => {
  if (!req.user?.isOwner) {
    return res.status(403).json({ error: 'Only the owner account can switch views.' });
  }

  const { role = 'citizen' } = req.body || {};
  const normalizedRole = ['admin', 'lawyer', 'user', 'citizen'].includes(String(role))
    ? String(role)
    : 'citizen';
  const appRole = normalizedRole === 'citizen' ? 'user' : normalizedRole;

  try {
    const { doc, jwtRole } = await getOrCreateShadowAccount(appRole);
    const fullName =
      doc.full_name ||
      (jwtRole === 'lawyer' ? 'Dev Lawyer' : jwtRole === 'admin' ? 'Dev Admin' : 'Dev User');

    const token = signToken({
      userId: doc._id.toString(),
      role: jwtRole,
      full_name: fullName,
      preferred_language: doc.preferred_language || 'he',
      isOwner: true,
      viewingAs: true,
    });

    return res.status(200).json({
      message: 'Viewing as ' + jwtRole + '.',
      token,
      role: jwtRole,
    });
  } catch (err) {
    logger.error({ err }, '[AUTH] view-as getOrCreateShadowAccount failed');
    return res.status(500).json({
      error: 'Could not prepare view-as session.',
    });
  }
};

module.exports = {
  register,
  requestOTP,
  otpVisibleInResponse,
  verifyOTP,
  googleAuth,
  devLogin,
  viewAs,
  passkeyRegisterOptions,
  passkeyRegisterVerify,
  passkeyLoginOptions,
  passkeyLoginVerify,
};
