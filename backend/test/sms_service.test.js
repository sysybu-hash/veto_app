const test = require('node:test');
const assert = require('node:assert/strict');

/**
 * Unit coverage for `sms.service.js` — the real SMS delivery channel added
 * to close the "phone/OTP login has no way to deliver a code in production"
 * gap from the 2026-08-01 OTP-in-JSON finding. Only tests config-detection
 * and input validation; never calls the real Twilio API (no live
 * credentials in this environment, and it shouldn't send real SMS from a
 * test run either way).
 */

function withEnv(overrides, fn) {
  const saved = {};
  for (const key of Object.keys(overrides)) {
    saved[key] = process.env[key];
    if (overrides[key] === undefined) delete process.env[key];
    else process.env[key] = overrides[key];
  }
  try {
    return fn();
  } finally {
    for (const key of Object.keys(saved)) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
  }
}

test('twilioConfigured is false when either credential is missing', () => {
  const { twilioConfigured } = require('../src/services/auth/sms.service');
  withEnv(
    { TWILIO_ACCOUNT_SID: undefined, TWILIO_AUTH_TOKEN: undefined },
    () => assert.equal(twilioConfigured(), false),
  );
  withEnv(
    { TWILIO_ACCOUNT_SID: 'ACxxx', TWILIO_AUTH_TOKEN: undefined },
    () => assert.equal(twilioConfigured(), false),
  );
  withEnv(
    { TWILIO_ACCOUNT_SID: undefined, TWILIO_AUTH_TOKEN: 'token' },
    () => assert.equal(twilioConfigured(), false),
  );
});

test('twilioConfigured is true once both credentials are present', () => {
  const { twilioConfigured } = require('../src/services/auth/sms.service');
  withEnv(
    { TWILIO_ACCOUNT_SID: 'ACxxx', TWILIO_AUTH_TOKEN: 'token' },
    () => assert.equal(twilioConfigured(), true),
  );
});

test('sendOtpSms rejects when Twilio is not configured', async () => {
  const { sendOtpSms } = require('../src/services/auth/sms.service');
  await withEnv(
    { TWILIO_ACCOUNT_SID: undefined, TWILIO_AUTH_TOKEN: undefined },
    () => assert.rejects(() => sendOtpSms('+972500000001', '123456')),
  );
});

test('sendOtpSms rejects when configured but no sender (messaging service / from number) is set', async () => {
  const { sendOtpSms } = require('../src/services/auth/sms.service');
  await withEnv(
    {
      TWILIO_ACCOUNT_SID: 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      TWILIO_AUTH_TOKEN: 'token',
      TWILIO_MESSAGING_SERVICE_SID: undefined,
      TWILIO_FROM_NUMBER: undefined,
    },
    () => assert.rejects(() => sendOtpSms('+972500000001', '123456')),
  );
});
