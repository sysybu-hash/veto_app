const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizePhoneForVeto,
  cleanPhone,
  isAdminPhone,
} = require('../src/services/auth/phone.service');

test('normalizePhoneForVeto — Israeli local format becomes E.164 +972', () => {
  assert.equal(normalizePhoneForVeto('0501234567'), '+972501234567');
  assert.equal(normalizePhoneForVeto('050-123-4567'), '+972501234567');
  assert.equal(normalizePhoneForVeto('(050) 123 4567'), '+972501234567');
});

test('normalizePhoneForVeto — bare 9-digit IL mobile gets +972 prefix', () => {
  assert.equal(normalizePhoneForVeto('501234567'), '+972501234567');
});

test('normalizePhoneForVeto — already-E.164 input is preserved', () => {
  assert.equal(normalizePhoneForVeto('+972525640021'), '+972525640021');
  assert.equal(normalizePhoneForVeto('972525640021'), '+972525640021');
});

test('normalizePhoneForVeto — international numbers are accepted', () => {
  assert.equal(normalizePhoneForVeto('+14155552671'), '+14155552671');
});

test('normalizePhoneForVeto — junk input returns null', () => {
  assert.equal(normalizePhoneForVeto(''), null);
  assert.equal(normalizePhoneForVeto('   '), null);
  assert.equal(normalizePhoneForVeto('abc'), null);
  assert.equal(normalizePhoneForVeto('+0'), null);
  assert.equal(normalizePhoneForVeto(null), null);
});

test('cleanPhone — strips the leading + for comparisons', () => {
  assert.equal(cleanPhone('+972525640021'), '972525640021');
  assert.equal(cleanPhone('972525640021'), '972525640021');
});

test('isAdminPhone — recognises the two hard-coded admins', () => {
  assert.equal(isAdminPhone('+972525640021'), true);
  assert.equal(isAdminPhone('+972506400030'), true);
  assert.equal(isAdminPhone('+972500000000'), false);
});
