// ============================================================
//  sms.service.js — Twilio SMS integration
//  Requires env vars:
//    TWILIO_ACCOUNT_SID   – from Twilio Console
//    TWILIO_AUTH_TOKEN    – from Twilio Console
//    TWILIO_FROM_NUMBER   – Twilio phone number (e.g. +12025551234)
// ============================================================

const twilio = require('twilio');

/**
 * Send an SMS using Twilio.
 * @param {string} to   – destination phone in E.164 format (+972xxxxxxxxx)
 * @param {string} body – message text
 */
async function sendSMS(to, body) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken  = process.env.TWILIO_AUTH_TOKEN;
  const from       = process.env.TWILIO_FROM_NUMBER;

  if (!accountSid || !authToken || !from) {
    console.warn('[SMS] Twilio env vars not set – SMS skipped.');
    return;
  }

  const client = twilio(accountSid, authToken);
  const message = await client.messages.create({ body, from, to });
  console.log(`[SMS] Sent to ${to} — SID: ${message.sid}`);
}

module.exports = { sendSMS };
