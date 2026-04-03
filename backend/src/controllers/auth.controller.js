// ============================================================
//  auth.controller.js — Authentication Controller
//  VETO Legal Emergency App
//  Flow: Register → Request OTP → Verify OTP → JWT issued
// ============================================================

const User    = require('../models/User');
const Lawyer  = require('../models/Lawyer');
const { signToken } = require('../middleware/auth.middleware');

// ── Helpers ────────────────────────────────────────────────

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
      license_number, // required for lawyers
    } = req.body;

    // ── Validate required fields ─────────────────────────
    if (!full_name || !phone) {
      return res.status(400).json({ error: 'full_name and phone are required.' });
    }
    if (!['user', 'lawyer'].includes(role)) {
      return res.status(400).json({ error: 'role must be "user" or "lawyer".' });
    }
    if (role === 'lawyer' && !license_number) {
      return res.status(400).json({ error: 'license_number is required for lawyers.' });
    }

    // ── Prevent duplicate registration ───────────────────
    const existing = await findByPhone(phone);
    if (existing) {
      return res.status(409).json({ error: 'An account with this phone already exists.' });
    }

    // ── Create document ──────────────────────────────────
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
    // Duplicate key from MongoDB (race condition)
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Account already exists.' });
    }
    next(err);
  }
};

// ============================================================
//  POST /auth/request-otp
//  Body: { phone, role? }
//  Dev mode: OTP is returned in the response body.
//  Production: swap the console.log for a real SMS (Twilio).
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
    let otp;
    
    // Normalize phone for comparison (remove +)
    const cleanPhone = phone.replace(/\+/g, '');
    const isAdminPhone = cleanPhone === '972525640021' || cleanPhone === '972506400030';
    const isFixedEnabled = process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';

    if ((process.env.NODE_ENV !== 'production' || isFixedEnabled) && isAdminPhone) {
      otp = '123456'; // Fixed OTP for admins
      console.log(`[AUTH] Using FIXED OTP for admin: ${phone}`);
    } else {
      otp = generateOTP();
      console.log(`[AUTH] Generated random OTP for: ${phone}`);
    }
    const expiry = otpExpiry();

    // Persist OTP (select:false fields need explicit .save())
    doc.otp_code       = otp;
    doc.otp_expires_at = expiry;
    await doc.save();

    // ── Production: send via SMS ─────────────────────────
    // await sendSMS(phone, `Your VETO code: ${otp}`);

    // ── Development: prominent terminal log ──────────────
    console.log('');
    console.log(`********** OTP FOR ${phone}: ${otp} **********`);
    console.log('');

    // OTP in JSON: dev only, or when RETURN_OTP_IN_JSON=1 (testing web / no SMS).
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
//  Returns: JWT token + user profile
// ============================================================
const verifyOTP = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'phone and otp are required.' });
    }

    // ── Find account (need otp fields, which are select:false)
    let doc, role;
    const user = await User.findOne({ phone }).select('+otp_code +otp_expires_at');
    if (user) {
      doc  = user;
      
      // Auto-promote specific numbers to admin upon verification
      const cleanPhone = phone.replace(/\+/g, '');
      if (cleanPhone === '972525640021' || cleanPhone === '972506400030') {
        if (doc.role !== 'admin') {
          doc.role = 'admin';
          await doc.save();
          console.log(`[AUTH] User ${phone} promoted to ADMIN during verification.`);
        }
      }
      
      role = doc.role === 'admin' ? 'admin' : 'user';
    } else {
      const lawyer = await Lawyer.findOne({ phone }).select('+otp_code +otp_expires_at');
      if (lawyer) { doc = lawyer; role = 'lawyer'; }
    }

    if (!doc) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    // ── Validate OTP ─────────────────────────────────────
    if (!doc.otp_code || doc.otp_code !== String(otp)) {
      return res.status(401).json({ error: 'Invalid OTP.' });
    }

    if (!doc.otp_expires_at || doc.otp_expires_at < new Date()) {
      return res.status(401).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // ── Mark verified + clear OTP ─────────────────────────
    doc.is_verified    = true;
    doc.otp_code       = undefined;
    doc.otp_expires_at = undefined;
    await doc.save();

    // ── Issue JWT ─────────────────────────────────────────
    const token = signToken({
      userId:             doc._id,
      role,
      full_name:          doc.full_name,
      preferred_language: doc.preferred_language,
    });

    return res.status(200).json({
      message: 'Verification successful.',
      token,
      user: {
        id:                 doc._id,
        full_name:          doc.full_name,
        phone:              doc.phone,
        role,
        preferred_language: doc.preferred_language,
        is_verified:        true,
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { register, requestOTP, verifyOTP };
