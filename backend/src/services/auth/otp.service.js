// ============================================================
//  otp.service.js
//  Cryptographically-safe OTP generation and expiry helpers.
//  Currently a 6-digit code valid for 10 minutes — both values
//  are centralised here so changing them is a one-line edit.
// ============================================================

const crypto = require('crypto');

const OTP_LIFETIME_MS = 10 * 60 * 1000;

/** Returns a 6-digit OTP as a string, drawn from `crypto.randomInt`. */
function generateOTP() {
  return String(crypto.randomInt(100000, 1000000));
}

/** Returns a `Date` 10 minutes in the future. */
function otpExpiry() {
  return new Date(Date.now() + OTP_LIFETIME_MS);
}

module.exports = {
  generateOTP,
  otpExpiry,
  OTP_LIFETIME_MS,
};
