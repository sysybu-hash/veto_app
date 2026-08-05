const test = require('node:test');
const assert = require('node:assert/strict');

const { shouldUseFixedAdminOtp, isAdminPhone } = require('../src/services/auth/phone.service');

test('shouldUseFixedAdminOtp — false in production even for admin phones', () => {
  const prev = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  process.env.ENABLE_FIXED_OTP_FOR_ADMINS = 'true';
  try {
    assert.equal(isAdminPhone('+972525640021'), true);
    assert.equal(shouldUseFixedAdminOtp('+972525640021'), false);
    assert.equal(shouldUseFixedAdminOtp('+972501111111'), false);
  } finally {
    process.env.NODE_ENV = prev;
    delete process.env.ENABLE_FIXED_OTP_FOR_ADMINS;
  }
});

test('shouldUseFixedAdminOtp — true only for admin phones outside production', () => {
  const prev = process.env.NODE_ENV;
  process.env.NODE_ENV = 'development';
  try {
    assert.equal(shouldUseFixedAdminOtp('+972525640021'), true);
    assert.equal(shouldUseFixedAdminOtp('+972506400030'), true);
    assert.equal(shouldUseFixedAdminOtp('+972501111111'), false);
  } finally {
    process.env.NODE_ENV = prev;
  }
});
