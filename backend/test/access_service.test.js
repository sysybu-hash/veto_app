const test = require('node:test');
const assert = require('node:assert/strict');

const { canAccessEvent } = require('../src/services/call/access.service');

const EVENT = {
  user_id: { toString: () => 'u1' },
  assigned_lawyer_id: { toString: () => 'L1' },
};

test('canAccessEvent — owner user is granted', () => {
  assert.equal(canAccessEvent(EVENT, { userId: 'u1', role: 'user' }), true);
});

test('canAccessEvent — assigned lawyer is granted', () => {
  assert.equal(canAccessEvent(EVENT, { userId: 'L1', role: 'lawyer' }), true);
});

test('canAccessEvent — admin is always granted', () => {
  assert.equal(canAccessEvent(EVENT, { userId: 'whoever', role: 'admin' }), true);
});

test('canAccessEvent — different user is denied', () => {
  assert.equal(canAccessEvent(EVENT, { userId: 'u2', role: 'user' }), false);
});

test('canAccessEvent — wrong-role lawyer is denied', () => {
  assert.equal(canAccessEvent(EVENT, { userId: 'L2', role: 'lawyer' }), false);
});

test('canAccessEvent — falsy event/user returns false', () => {
  assert.equal(canAccessEvent(null, { userId: 'u1', role: 'user' }), false);
  assert.equal(canAccessEvent(EVENT, null), false);
});
