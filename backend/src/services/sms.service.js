// ============================================================
//  sms.service.js — Twilio Verify integration
//  Requires env vars:
//    TWILIO_ACCOUNT_SID        – from Twilio Console
//    TWILIO_AUTH_TOKEN         – from Twilio Console
//    TWILIO_VERIFY_SERVICE_SID – from Twilio Verify Services
// ============================================================

const twilio = require('twilio');

function getClient() {
  const sid   = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (!sid || !token) throw new Error('Twilio credentials not configured.');
  return twilio(sid, token);
}

/**
 * Send OTP via Twilio Verify to any phone number worldwide.
 * @param {string} to – E.164 format (+972xxxxxxxxx)
 */
async function sendOTP(to) {
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
  if (!serviceSid) {
    console.warn('[SMS] TWILIO_VERIFY_SERVICE_SID not set – SMS skipped.');
    return;
  }
  const client = getClient();
  await client.verify.v2.services(serviceSid).verifications.create({ to, channel: 'sms' });
  console.log(`[SMS] Verify OTP sent to ${to}`);
}

/**
 * Check OTP via Twilio Verify.
 * @param {string} to   – E.164 format
 * @param {string} code – 6-digit code from user
 * @returns {boolean} true if approved
 */
async function checkOTP(to, code) {
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
  if (!serviceSid) {
    console.warn('[SMS] TWILIO_VERIFY_SERVICE_SID not set – check skipped.');
    return false;
  }
  const client = getClient();
  const result = await client.verify.v2.services(serviceSid)
    .verificationChecks.create({ to, code });
  return result.status === 'approved';
}

module.exports = { sendOTP, checkOTP };
