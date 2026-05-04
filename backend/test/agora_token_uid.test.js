const test = require('node:test');
const assert = require('node:assert/strict');

const { mongoIdToAgoraUid } = require('../src/services/agoraToken.service');

test('mongoIdToAgoraUid hashes the full ObjectId, not just timestamp prefix', () => {
  const first = mongoIdToAgoraUid('674a1b2c0000000000000001');
  const second = mongoIdToAgoraUid('674a1b2c0000000000000002');

  assert.notEqual(first, second);
  assert.ok(first >= 1);
  assert.ok(second >= 1);
  assert.ok(first <= 4294967294);
  assert.ok(second <= 4294967294);
});

test('mongoIdToAgoraUid is deterministic for equivalent ObjectId casing', () => {
  assert.equal(
    mongoIdToAgoraUid('674A1B2C00000000000000AF'),
    mongoIdToAgoraUid('674a1b2c00000000000000af'),
  );
});
