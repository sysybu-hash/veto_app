const test = require('node:test');
const assert = require('node:assert/strict');

/**
 * Regression coverage for the 2026-07-29 finding: ALLOW_DEV_LOGIN was set on
 * live Render production, making POST /auth/dev-login a full auth bypass via
 * hardcoded default credentials. The fix removed the production-override
 * flag entirely — these tests prove `devLogin` structurally cannot succeed
 * when NODE_ENV==='production', no matter what other env vars are set, and
 * that `viewAs` is gated on a real `isOwner` JWT claim rather than a shared
 * secret.
 */

function mockRes() {
  const res = {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
  return res;
}

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

test('devLogin always returns 403 in production, even with DEV_LOGIN_ENABLED=1 and correct credentials', async () => {
  const { devLogin } = require('../src/controllers/auth.controller');
  await withEnv(
    {
      NODE_ENV: 'production',
      DEV_LOGIN_ENABLED: '1',
      DEV_LOGIN_USERNAME: 'owner@example.com',
      DEV_LOGIN_PASSWORD: 'correct-secret',
    },
    async () => {
      const req = { body: { username: 'owner@example.com', password: 'correct-secret', role: 'admin' } };
      const res = mockRes();
      await devLogin(req, res);
      assert.equal(res.statusCode, 403);
    },
  );
});

test('devLogin returns 403 outside production when DEV_LOGIN_ENABLED is not set', async () => {
  const { devLogin } = require('../src/controllers/auth.controller');
  await withEnv(
    {
      NODE_ENV: 'test',
      DEV_LOGIN_ENABLED: undefined,
      DEV_LOGIN_USERNAME: 'owner@example.com',
      DEV_LOGIN_PASSWORD: 'correct-secret',
    },
    async () => {
      const req = { body: { username: 'owner@example.com', password: 'correct-secret', role: 'admin' } };
      const res = mockRes();
      await devLogin(req, res);
      assert.equal(res.statusCode, 403);
    },
  );
});

test('devLogin returns 503 when enabled but no username/password configured', async () => {
  const { devLogin } = require('../src/controllers/auth.controller');
  await withEnv(
    {
      NODE_ENV: 'test',
      DEV_LOGIN_ENABLED: '1',
      DEV_LOGIN_USERNAME: undefined,
      DEV_LOGIN_PASSWORD: undefined,
    },
    async () => {
      const req = { body: { username: 'anyone', password: 'anything', role: 'admin' } };
      const res = mockRes();
      await devLogin(req, res);
      assert.equal(res.statusCode, 503);
    },
  );
});

test('devLogin returns 401 for wrong credentials when properly enabled', async () => {
  const { devLogin } = require('../src/controllers/auth.controller');
  await withEnv(
    {
      NODE_ENV: 'test',
      DEV_LOGIN_ENABLED: '1',
      DEV_LOGIN_USERNAME: 'owner@example.com',
      DEV_LOGIN_PASSWORD: 'correct-secret',
    },
    async () => {
      const req = { body: { username: 'owner@example.com', password: 'wrong', role: 'admin' } };
      const res = mockRes();
      await devLogin(req, res);
      assert.equal(res.statusCode, 401);
    },
  );
});

test('viewAs returns 403 when the JWT does not carry isOwner:true', async () => {
  const { viewAs } = require('../src/controllers/auth.controller');
  const req = { user: { userId: 'x', role: 'user', isOwner: false }, body: { role: 'admin' } };
  const res = mockRes();
  await viewAs(req, res);
  assert.equal(res.statusCode, 403);
});

test('viewAs returns 403 when the JWT has no isOwner claim at all', async () => {
  const { viewAs } = require('../src/controllers/auth.controller');
  const req = { user: { userId: 'x', role: 'user' }, body: { role: 'admin' } };
  const res = mockRes();
  await viewAs(req, res);
  assert.equal(res.statusCode, 403);
});
