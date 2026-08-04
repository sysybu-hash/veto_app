const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');

describe('paypal env trim', () => {
  const prev = {};

  beforeEach(() => {
    for (const k of ['PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET', 'PAYPAL_ENV']) {
      prev[k] = process.env[k];
    }
  });

  afterEach(() => {
    for (const k of Object.keys(prev)) {
      if (prev[k] === undefined) delete process.env[k];
      else process.env[k] = prev[k];
    }
    // Clear require cache so helpers re-read env
    delete require.cache[require.resolve('../src/services/paypal.service')];
  });

  it('trims trailing newlines from client id/secret', () => {
    process.env.PAYPAL_CLIENT_ID = 'cid-live\n';
    process.env.PAYPAL_CLIENT_SECRET = 'sec-live\r\n';
    process.env.PAYPAL_ENV = 'live\n';
    const paypal = require('../src/services/paypal.service');
    assert.equal(paypal._test.paypalClientId(), 'cid-live');
    assert.equal(paypal._test.paypalClientSecret(), 'sec-live');
    assert.equal(paypal._test.paypalEnv(), 'live');
  });
});
