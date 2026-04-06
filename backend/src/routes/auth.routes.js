// ============================================================
//  auth.routes.js
//  VETO Legal Emergency App
//
//  POST /api/auth/register      → create account (user or lawyer)
//  POST /api/auth/request-otp   → send 6-digit OTP to phone
//  POST /api/auth/verify-otp    → validate OTP, return JWT
// ============================================================

const express = require('express');
const router  = express.Router();
const {
  register,
  requestOTP,
  verifyOTP,
  googleAuth,
} = require('../controllers/auth.controller');

router.post('/register',    register);
router.post('/request-otp', requestOTP);
router.post('/verify-otp',  verifyOTP);
router.post('/google',      googleAuth);

module.exports = router;
