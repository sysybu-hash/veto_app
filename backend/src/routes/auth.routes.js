// ============================================================
//  auth.routes.js
//  VETO Legal Emergency App
//
//  POST /api/auth/register      → create account (user or lawyer)
//  POST /api/auth/request-otp   → send 6-digit OTP to phone
//  POST /api/auth/verify-otp    → validate OTP, return JWT
// ============================================================

const express = require('express');
const rateLimit = require('express-rate-limit');
const router  = express.Router();
const { protect } = require('../middleware/auth.middleware');
const {
  register,
  requestOTP,
  verifyOTP,
  googleAuth,
  devLogin,
  viewAs,
  passkeyRegisterOptions,
  passkeyRegisterVerify,
  passkeyLoginOptions,
  passkeyLoginVerify,
} = require('../controllers/auth.controller');

const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many OTP requests. Please wait 10 minutes.' },
});

// A 6-digit OTP has only 1,000,000 combinations — without this, the global apiLimiter
// (150 req/min) is loose enough to brute-force one within minutes. Key by phone number
// (falling back to IP) so an attacker can't spread guesses for one victim across IPs
// and blow past a pure-IP limiter, while still bounding a single IP hammering many phones.
const verifyOtpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 8,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => String(req.body?.phone || req.body?.phoneNumber || req.ip || 'unknown'),
  message: { error: 'Too many verification attempts. Please wait 10 minutes.' },
});

// register/google/dev-login are already covered by the mount-level `authLimiter`
// (20 req/15min/IP, applied to the whole /api/auth prefix in server.js) — no extra
// limiter needed here; only OTP endpoints need something stricter/differently-keyed.
router.post('/register',    register);
router.post('/request-otp', otpLimiter, requestOTP);
router.post('/verify-otp',  verifyOtpLimiter, verifyOTP);
router.post('/google',      googleAuth);
router.post('/dev-login',   devLogin);
router.post('/view-as',     protect, viewAs);
router.post('/passkeys/register/options', protect, passkeyRegisterOptions);
router.post('/passkeys/register/verify', protect, passkeyRegisterVerify);
router.post('/passkeys/login/options', passkeyLoginOptions);
router.post('/passkeys/login/verify', passkeyLoginVerify);

// Mission 9 — canonical WebAuthn paths (same handlers as /passkeys/*)
router.post('/webauthn/register-options', protect, passkeyRegisterOptions);
router.post('/webauthn/verify-registration', protect, passkeyRegisterVerify);
router.post('/webauthn/authentication-options', passkeyLoginOptions);
router.post('/webauthn/verify-authentication', passkeyLoginVerify);

module.exports = router;
