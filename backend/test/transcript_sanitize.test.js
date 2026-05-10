const test = require('node:test');
const assert = require('node:assert/strict');

const {
  sanitizeTranscript,
} = require('../src/services/call/transcript.service');

test('sanitizeTranscript — empty / non-string input is returned as empty string', () => {
  assert.equal(sanitizeTranscript(''), '');
  assert.equal(sanitizeTranscript(null), '');
  assert.equal(sanitizeTranscript(undefined), '');
  assert.equal(sanitizeTranscript(42), '');
});

test('sanitizeTranscript — strips emoji and stage directions', () => {
  const raw = '[laughter] Hello there 😀 — how are you? 🚀';
  const cleaned = sanitizeTranscript(raw);
  assert.ok(!cleaned.includes('😀'));
  assert.ok(!cleaned.includes('🚀'));
  assert.ok(!cleaned.includes('[laughter]'));
  assert.ok(cleaned.includes('Hello there'));
});

test('sanitizeTranscript — collapses whitespace runs', () => {
  const cleaned = sanitizeTranscript('one    two\n\n\n\nthree');
  assert.equal(cleaned, 'one two\n\nthree');
});

test('sanitizeTranscript — removes bare "emoji" descriptions in he/en', () => {
  const cleaned = sanitizeTranscript('זה סמיילי של חיוך and an emoji of joy');
  assert.ok(!/סמיילי/.test(cleaned));
  assert.ok(!/\bemoji\b/i.test(cleaned));
});

test('sanitizeTranscript — strips markdown code fences', () => {
  const cleaned = sanitizeTranscript('```\nfoo\n```');
  assert.ok(!cleaned.includes('```'));
  assert.ok(cleaned.includes('foo'));
});
