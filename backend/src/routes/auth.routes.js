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
const {
  register,
  requestOTP,
  verifyOTP,
  googleAuth,
} = require('../controllers/auth.controller');

const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many OTP requests. Please wait 10 minutes.' },
});

router.post('/register',    register);
router.post('/request-otp', otpLimiter, requestOTP);
router.post('/verify-otp',  verifyOTP);
router.post('/google',      googleAuth);

module.exports = router;
