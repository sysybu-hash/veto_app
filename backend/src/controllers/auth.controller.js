// ============================================================
//  auth.controller.js � Authentication Controller
//  VETO Legal Emergency App
//  Flow: Register ? Request OTP ? Verify OTP ? JWT issued
// ============================================================

const User    = require('../models/User');
const Lawyer  = require('../models/Lawyer');
const { signToken } = require('../middleware/auth.middleware');

// ?? Helpers ????????????????????????????????????????????????

/** Generate a cryptographically-safe 6-digit OTP */
function generateOTP() {
  return String(Math.floor(100000 + Math.random() * 900000));
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
  return phone.replace(/\+/g, '');
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
    } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({ error: 'full_name and phone are required.' });
    }
    if (!['user', 'lawyer'].includes(role)) {
      return res.status(400).json({ error: 'role must be "user" or "lawyer".' });
    }

    const existing = await findByPhone(phone);
    if (existing) {
      return res.status(409).json({ error: 'An account with this phone already exists.' });
    }

    const Model   = modelFor(role);
    const payload = { full_name, phone, preferred_language };
    if (email)          payload.email          = email;
    if (license_number) payload.license_number = license_number;

    const newDoc = await Model.create(payload);

    return res.status(201).json({
      message: 'Account created. Please verify your phone.',
      id:      newDoc._id,
      role,
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Account already exists.' });
    }
    next(err);
  }
};

// ============================================================
//  POST /auth/request-otp
//  Admin phones ? fixed OTP 123456 stored in DB
//  Regular users  ? Twilio Verify sends OTP (not stored in DB)
// ============================================================
const requestOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'phone is required.' });

    const found = await findByPhone(phone);
    if (!found) {
      return res.status(404).json({
        error: 'No account found with this phone number. Please register first.',
      });
    }

    const { doc, role } = found;
    const useFixed = isAdminPhone(phone) || process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';

    const otp = useFixed ? '123456' : generateOTP();
    doc.otp_code       = otp;
    doc.otp_expires_at = otpExpiry();
    await doc.save();
    console.log(`[AUTH] OTP for ${phone}: ${otp}`);

    console.log(`[AUTH] OTP requested for ${phone} (role: ${role})`);

    const exposeOtp =
      process.env.NODE_ENV !== 'production' ||
      process.env.RETURN_OTP_IN_JSON === '1' ||
      process.env.RETURN_OTP_IN_JSON === 'true';

    return res.status(200).json({
      message: 'OTP sent.',
      role,
      ...(exposeOtp && { otp }),
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  POST /auth/verify-otp
//  Body: { phone, otp }
//  Admin ? check DB; Regular ? check via Twilio Verify
// ============================================================
const verifyOTP = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'phone and otp are required.' });
    }

    let doc, role;
    const user = await User.findOne({ phone }).select('+otp_code +otp_expires_at');
    if (user) {
      doc = user;

      // Auto-promote admin phones
      if (isAdminPhone(phone) && doc.role !== 'admin') {
        doc.role = 'admin';
        await doc.save();
        console.log(`[AUTH] ${phone} promoted to ADMIN.`);
      }

      role = doc.role === 'admin' ? 'admin' : 'user';
    } else {
      const lawyer = await Lawyer.findOne({ phone }).select('+otp_code +otp_expires_at');
      if (lawyer) { doc = lawyer; role = 'lawyer'; }
    }

    if (!doc) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    // Lawyers must be approved by admin before they can log in
    if (role === 'lawyer' && !doc.is_approved) {
      return res.status(403).json({
        error: 'חשבון עורך הדין שלך ממתין לאישור מנהל. תקבל הודעה בקרוב.',
        pending_approval: true,
      });
    }

    const useFixed = isAdminPhone(phone) || process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';

    // ── Validate against DB OTP ────────────────────────
    if (!doc.otp_code || doc.otp_code !== String(otp)) {
      return res.status(401).json({ error: 'Invalid OTP.' });
    }
    if (!doc.otp_expires_at || doc.otp_expires_at < new Date()) {
      return res.status(401).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // ?? Mark verified + clear OTP ?????????????????????
    doc.is_verified    = true;
    doc.otp_code       = undefined;
    doc.otp_expires_at = undefined;
    await doc.save();

    // ?? Issue JWT ??????????????????????????????????????
    const token = signToken({
      userId:             doc._id,
      role,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
    });

    // Compute payment exemption: admin, lawyer, or manually_added user
    const isPaymentExempt = role === 'admin' || role === 'lawyer' || doc.manually_added === true;

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
    const { id_token, preferred_language = 'he' } = req.body;
    if (!id_token) return res.status(400).json({ error: 'id_token is required.' });

    const clientId = process.env.GOOGLE_CLIENT_ID ||
      '752712664923-7loca49f7fggd514q8reljn93meatmrf.apps.googleusercontent.com';
    if (!clientId) {
      return res.status(503).json({ error: 'Google Sign-In is not configured on this server.' });
    }

    const { OAuth2Client } = require('google-auth-library');
    const oauthClient = new OAuth2Client(clientId);

    let gPayload;
    try {
      const ticket = await oauthClient.verifyIdToken({ idToken: id_token, audience: clientId });
      gPayload = ticket.getPayload();
    } catch {
      return res.status(401).json({ error: 'Invalid Google token.' });
    }

    const googleId = gPayload.sub;
    const email    = gPayload.email;
    const name     = gPayload.name || '';

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
      userId:             doc._id,
      role:               userRole,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
    });

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
        is_payment_exempt:   userRole === 'admin' || doc.manually_added === true,
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { register, requestOTP, verifyOTP, googleAuth };
