const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { lawyerSosDeepLink } = require('../src/services/push.service');

describe('lawyerSosDeepLink', () => {
  it('includes eventId without requiring GPS', () => {
    const url = lawyerSosDeepLink({ eventId: 'evt123', userName: 'Dana' });
    assert.match(url, /eventId=evt123/);
    assert.match(url, /tab=calls/);
    assert.match(url, /userName=Dana/);
    assert.doesNotMatch(url, /lat=/);
  });

  it('adds lat/lng when provided', () => {
    const url = lawyerSosDeepLink({
      eventId: 'evt9',
      location: { lat: 32.1, lng: 34.8 },
    });
    assert.match(url, /lat=32\.1/);
    assert.match(url, /lng=34\.8/);
  });

  it('respects explicit url override', () => {
    assert.equal(
      lawyerSosDeepLink({ eventId: 'x', url: '/dashboard?eventId=x&tab=calls' }),
      '/dashboard?eventId=x&tab=calls',
    );
  });
});
