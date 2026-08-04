const test = require('node:test');
const assert = require('node:assert/strict');

const SERVICE_PATH = '../src/services/call/iceServers.service';

function withEnv(envPatch, fn) {
  const saved = {};
  for (const [k, v] of Object.entries(envPatch)) {
    saved[k] = process.env[k];
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
  try {
    delete require.cache[require.resolve(SERVICE_PATH)];
    const svc = require(SERVICE_PATH);
    return fn(svc);
  } finally {
    for (const [k, v] of Object.entries(saved)) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
    delete require.cache[require.resolve(SERVICE_PATH)];
  }
}

test('iceServersFromEnv — empty env returns public STUN fallback', () => {
  withEnv(
    {
      WEBRTC_ICE_SERVERS_JSON: undefined,
      TURN_URL: undefined,
      TURN_USERNAME: undefined,
      TURN_CREDENTIAL: undefined,
    },
    ({ iceServersFromEnv }) => {
      const out = iceServersFromEnv();
      assert.equal(out.length, 1);
      assert.equal(out[0].urls, 'stun:stun.l.google.com:19302');
    },
  );
});

test('iceServersFromEnv — TURN_URL/USER/CREDENTIAL builds STUN + TURN', () => {
  withEnv(
    {
      WEBRTC_ICE_SERVERS_JSON: undefined,
      TURN_URL: 'turn:example.com:3478',
      TURN_USERNAME: 'user',
      TURN_CREDENTIAL: 'pass',
    },
    ({ iceServersFromEnv }) => {
      assert.deepEqual(iceServersFromEnv(), [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'turn:example.com:3478', username: 'user', credential: 'pass' },
      ]);
    },
  );
});

test('iceServersFromEnv — JSON env wins over TURN_* vars', () => {
  withEnv(
    {
      WEBRTC_ICE_SERVERS_JSON: JSON.stringify([
        { urls: 'stun:stun.l.google.com:19302' },
      ]),
      TURN_URL: 'turn:example.com:3478',
      TURN_USERNAME: 'u',
      TURN_CREDENTIAL: 'p',
    },
    ({ iceServersFromEnv }) => {
      const out = iceServersFromEnv();
      assert.equal(out.length, 1);
      assert.equal(out[0].urls, 'stun:stun.l.google.com:19302');
    },
  );
});

test('iceServersFromEnv — malformed JSON falls back to TURN_* vars', () => {
  withEnv(
    {
      WEBRTC_ICE_SERVERS_JSON: 'not valid {json',
      TURN_URL: 'turn:fallback.example.com:3478',
      TURN_USERNAME: 'u',
      TURN_CREDENTIAL: 'p',
    },
    ({ iceServersFromEnv }) => {
      const out = iceServersFromEnv();
      assert.equal(out.length, 2);
      assert.equal(out[0].urls, 'stun:stun.l.google.com:19302');
      assert.ok(out[1].urls.includes('fallback.example.com'));
    },
  );
});
