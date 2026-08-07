// ============================================================
//  Requesting an OTP with no SMS provider must FAIL, not pretend.
//
//  The endpoint used to return 200 "OTP generated successfully" when Twilio
//  was absent, logging a warning nobody reads. The person saw a code-entry box
//  and waited for a text that could never arrive, with nothing on screen
//  saying another sign-in method existed. Production has no Twilio account, so
//  this was the state every phone login was in.
//
//  Only production is affected: outside it `otpVisibleInResponse()` returns
//  the code in the response body, so it does reach the caller and there is
//  nothing to warn about. These tests therefore flip NODE_ENV deliberately —
//  the distinction IS the behaviour under test.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'otp-nosms-test-secret';

let server;
let baseUrl;
let User;
const ORIGINAL_NODE_ENV = process.env.NODE_ENV;

async function post(path, body) {
  const res = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  let json;
  try {
    json = await res.json();
  } catch {
    json = {};
  }
  return { status: res.status, body: json };
}

test.before(async () => {
  await startMemoryDb();
  User = require('../src/models/User');

  const app = express();
  app.use(express.json());
  app.use('/api/auth', require('../src/routes/auth.routes'));
  server = http.createServer(app);
  await new Promise((r) => server.listen(0, r));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  process.env.NODE_ENV = ORIGINAL_NODE_ENV;
  await new Promise((r) => server.close(r));
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
  delete process.env.TWILIO_ACCOUNT_SID;
  delete process.env.TWILIO_AUTH_TOKEN;
  process.env.NODE_ENV = ORIGINAL_NODE_ENV;
});

async function seedCitizen(phone) {
  return User.create({ full_name: 'אזרח', phone, role: 'user', is_active: true });
}

test('production with no SMS provider fails loudly instead of reporting success', async () => {
  process.env.NODE_ENV = 'production';
  const user = await seedCitizen('+972501234567');
  const res = await post('/api/auth/request-otp', { phone: user.phone });

  assert.equal(res.status, 503, 'must not report success for an undeliverable code');
  assert.equal(res.body.code, 'SMS_UNAVAILABLE');
  assert.match(res.body.error, /Google/, 'must name the sign-in method that does work');
  assert.equal(res.body.otp, undefined, 'never leak the code in the response');
});

test('the failure names an alternative rather than telling the user to retry', async () => {
  process.env.NODE_ENV = 'production';
  const user = await seedCitizen('+972501234568');
  const res = await post('/api/auth/request-otp', { phone: user.phone });
  assert.doesNotMatch(
    res.body.error,
    /נסו שוב|try again/i,
    'retrying cannot help when no provider is configured',
  );
});

test('outside production the code is returned in-band, so the request succeeds', async () => {
  // Local development and the CI e2e suite rely on this; the guard must not
  // break either.
  const user = await seedCitizen('+972501234569');
  const res = await post('/api/auth/request-otp', { phone: user.phone });

  assert.equal(res.status, 200);
  assert.match(String(res.body.otp), /^\d{4,8}$/, 'the code is delivered in-band');
});

test('an unknown phone is refused as not-registered, not as an outage', async () => {
  process.env.NODE_ENV = 'production';
  const res = await post('/api/auth/request-otp', { phone: '+972500000000' });
  assert.notEqual(res.status, 503, 'a missing account must not read as SMS being down');
});
