const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

describe('dispatch.socket stale-online guard', () => {
  it('source mentions last_seen cutoff for online lawyers', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../src/socket/dispatch.socket.js'),
      'utf8',
    );
    assert.match(src, /last_seen/);
    assert.match(src, /is_approved/);
  });
});
