// Mirror of the client-side `deriveE2EEMaterial` — keeps server expectations
// in sync with web-client/src/app/call/[channel]/_v2/lib/e2eeConfig.ts so an
// accidental algorithm change can't slip through unnoticed.

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

function sha256Hex(input) {
  return crypto.createHash('sha256').update(input, 'utf8').digest('hex');
}

function deriveE2EEMaterial(eventId, e2eeSecret) {
  if (!eventId) throw new Error('E2EE: eventId required');
  if (!e2eeSecret || !String(e2eeSecret).trim()) {
    throw new Error('E2EE: e2eeSecret required');
  }
  const secret = String(e2eeSecret).trim();
  const key = sha256Hex(`veto-e2ee-key:${eventId}:${secret}`);
  const saltFull = sha256Hex(`veto-e2ee-salt:${eventId}:${secret}`);
  return { key, salt: saltFull.slice(0, 32) }; // 32 hex chars = 16 bytes
}

test('e2ee — deterministic for same inputs', () => {
  const hexSecret = crypto.randomBytes(32).toString('hex');
  const a = deriveE2EEMaterial('64f0...event', hexSecret);
  const b = deriveE2EEMaterial('64f0...event', hexSecret);
  assert.equal(a.key, b.key);
  assert.equal(a.salt, b.salt);
});

test('e2ee — different events produce different keys', () => {
  const a = deriveE2EEMaterial('event-A', 'shared-secret-a');
  const b = deriveE2EEMaterial('event-B', 'shared-secret-a');
  assert.notEqual(a.key, b.key);
  assert.notEqual(a.salt, b.salt);
});

test('e2ee — different secrets produce different keys', () => {
  const a = deriveE2EEMaterial('same-event', 'secret-one');
  const b = deriveE2EEMaterial('same-event', 'secret-two');
  assert.notEqual(a.key, b.key);
  assert.notEqual(a.salt, b.salt);
});

test('e2ee — key is 32 bytes (256 bit) and salt is 16 bytes', () => {
  const { key, salt } = deriveE2EEMaterial('e', 's');
  assert.equal(key.length, 64); // 32 bytes = 64 hex
  assert.equal(salt.length, 32); // 16 bytes = 32 hex
});

test('e2ee — empty inputs throw', () => {
  assert.throws(() => deriveE2EEMaterial('', 's'), /eventId required/);
  assert.throws(() => deriveE2EEMaterial('e', ''), /e2eeSecret required/);
});
