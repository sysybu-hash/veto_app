// ============================================================
//  sms.service.js
//  Sends the OTP via Twilio SMS. This is the only real delivery
//  channel for phone/OTP login — see the 2026-08-01 finding in
//  auth.controller.js: without this, production had no way to
//  deliver an OTP to the user at all.
// ============================================================

const twilioLib = require('twilio');

let cachedClient = null;

/** True once both Twilio credentials are present. */
function twilioConfigured() {
  return !!(process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN);
}

function getClient() {
  if (!twilioConfigured()) return null;
  if (!cachedClient) {
    cachedClient = twilioLib(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  }
  return cachedClient;
}

/**
 * Sends the OTP code to `toE164Phone` via SMS.
 * Throws if Twilio isn't configured, no sender (messaging service or phone
 * number) is set, or the Twilio API call itself fails — callers must treat
 * a thrown error as "the user did not receive a code", not a soft failure.
 */
async function sendOtpSms(toE164Phone, otp) {
  const client = getClient();
  if (!client) throw new Error('Twilio is not configured.');

  const messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID || undefined;
  const from = process.env.TWILIO_FROM_NUMBER || undefined;
  if (!messagingServiceSid && !from) {
    throw new Error(
      'Set TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM_NUMBER to send SMS.',
    );
  }

  await client.messages.create({
    to: toE164Phone,
    body: `קוד האימות שלך ל-VETO: ${otp}\nהקוד בתוקף ל-10 דקות. אל תשתפו קוד זה עם אף אחד.`,
    ...(messagingServiceSid ? { messagingServiceSid } : { from }),
  });
}

module.exports = {
  twilioConfigured,
  sendOtpSms,
};
