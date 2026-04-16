const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

test('crypto.randomInt produces 6-digit OTP range', () => {
  for (let i = 0; i < 100; i++) {
    const n = crypto.randomInt(100000, 1000000);
    assert.ok(n >= 100000 && n <= 999999, `out of range: ${n}`);
  }
});
