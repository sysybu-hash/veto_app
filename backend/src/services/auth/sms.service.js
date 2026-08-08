// ============================================================
//  sms.service.js
//  Sends SMS via Twilio. The OTP path is the only *required* delivery
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

/** Shared sender resolution — messaging service wins over a bare number. */
function senderFields() {
  const messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID || undefined;
  const from = process.env.TWILIO_FROM_NUMBER || undefined;
  if (!messagingServiceSid && !from) {
    throw new Error(
      'Set TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM_NUMBER to send SMS.',
    );
  }
  return messagingServiceSid ? { messagingServiceSid } : { from };
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

  await client.messages.create({
    to: toE164Phone,
    body: `קוד האימות שלך ל-VETO: ${otp}\nהקוד בתוקף ל-10 דקות. אל תשתפו קוד זה עם אף אחד.`,
    ...senderFields(),
  });
}

/**
 * Non-OTP transactional SMS (family invites, membership changes).
 *
 * Unlike the OTP path this NEVER throws: a family member not getting a text
 * is worth logging, but it must not roll back the membership change the owner
 * just made. Returns whether it went out so the caller can report honestly.
 */
async function sendTransactionalSms(toE164Phone, body) {
  const logger = require('../../lib/logger');
  try {
    const client = getClient();
    if (!client) return { sent: false, reason: 'twilio_not_configured' };
    await client.messages.create({ to: toE164Phone, body, ...senderFields() });
    return { sent: true };
  } catch (err) {
    logger.warn(
      { err: String(err?.message || err), to: String(toE164Phone).slice(-4) },
      '[sms] transactional send failed',
    );
    return { sent: false, reason: 'send_failed' };
  }
}

module.exports = {
  twilioConfigured,
  sendOtpSms,
  sendTransactionalSms,
};
