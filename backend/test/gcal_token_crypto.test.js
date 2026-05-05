'use strict';

const test = require('node:test');
const assert = require('node:assert');

test('gcalTokenCrypto roundtrip', () => {
  process.env.JWT_SECRET = 'test-secret-for-gcal-crypto-min-32-chars-long!!';
  const { encryptToken, decryptToken } = require('../src/utils/gcalTokenCrypto.util');
  const plain = '1//refresh-token-example';
  const enc = encryptToken(plain);
  assert.ok(enc && enc.length > 10);
  assert.strictEqual(decryptToken(enc), plain);
  assert.strictEqual(decryptToken(null), null);
});
