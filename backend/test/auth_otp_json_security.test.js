const test = require('node:test');
const assert = require('node:assert/strict');

/**
 * Regression coverage for the 2026-08-01 finding: live production returned
 * the actual OTP code in the `request-otp` JSON response whenever Twilio
 * wasn't configured (or RETURN_OTP_IN_JSON was set), letting anyone log in
 * as any phone number without ever touching the device — confirmed live via
 * a real request against the production API. The fix makes this closed by
 * construction: `otpVisibleInResponse()` only checks NODE_ENV, so no other
 * env var (RETURN_OTP_IN_JSON, Twilio config, etc.) can reopen it in
 * production.
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

test('otpVisibleInResponse is false in production even with RETURN_OTP_IN_JSON=1 and no Twilio', () => {
  const { otpVisibleInResponse } = require('../src/controllers/auth.controller');
  withEnv(
    {
      NODE_ENV: 'production',
      RETURN_OTP_IN_JSON: '1',
      TWILIO_ACCOUNT_SID: undefined,
      TWILIO_AUTH_TOKEN: undefined,
    },
    () => {
      assert.equal(otpVisibleInResponse(), false);
    },
  );
});

test('otpVisibleInResponse is false in production even with Twilio configured and RETURN_OTP_IN_JSON=1', () => {
  const { otpVisibleInResponse } = require('../src/controllers/auth.controller');
  withEnv(
    {
      NODE_ENV: 'production',
      RETURN_OTP_IN_JSON: '1',
      TWILIO_ACCOUNT_SID: 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      TWILIO_AUTH_TOKEN: 'sometoken',
    },
    () => {
      assert.equal(otpVisibleInResponse(), false);
    },
  );
});

test('otpVisibleInResponse is true outside production (dev/CI/E2E)', () => {
  const { otpVisibleInResponse } = require('../src/controllers/auth.controller');
  withEnv(
    {
      NODE_ENV: 'test',
      RETURN_OTP_IN_JSON: '1',
    },
    () => {
      assert.equal(otpVisibleInResponse(), true);
    },
  );
});
