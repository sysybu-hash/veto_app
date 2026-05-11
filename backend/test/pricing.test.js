const test = require('node:test');
const assert = require('node:assert/strict');

const {
  computeChargeFromSeconds,
} = require('../src/services/call/billing.service');
const {
  CONSULTATION_ILS,
  OVERTIME_ILS_PER_MIN,
  FREE_CALL_MINUTES,
} = require('../src/config/pricing');

test('computeChargeFromSeconds — 0 seconds is rounded up to a 1-minute base charge', () => {
  const c = computeChargeFromSeconds(0);
  assert.equal(c.minutes, 1);
  assert.equal(c.baseIls, CONSULTATION_ILS);
  assert.equal(c.overtimeMinutes, 0);
  assert.equal(c.overtimeIls, 0);
  assert.equal(c.totalIls, CONSULTATION_ILS);
});

test('computeChargeFromSeconds — full free window has no overtime', () => {
  const seconds = FREE_CALL_MINUTES * 60;
  const c = computeChargeFromSeconds(seconds);
  assert.equal(c.minutes, FREE_CALL_MINUTES);
  assert.equal(c.overtimeMinutes, 0);
  assert.equal(c.overtimeIls, 0);
  assert.equal(c.totalIls, CONSULTATION_ILS);
});

test('computeChargeFromSeconds — partial overtime minute is billed as a full minute', () => {
  // 1 second past the free window must round up to one overtime minute.
  const seconds = FREE_CALL_MINUTES * 60 + 1;
  const c = computeChargeFromSeconds(seconds);
  assert.equal(c.minutes, FREE_CALL_MINUTES + 1);
  assert.equal(c.overtimeMinutes, 1);
  assert.equal(c.overtimeIls, +OVERTIME_ILS_PER_MIN.toFixed(2));
  assert.equal(c.totalIls, +(CONSULTATION_ILS + OVERTIME_ILS_PER_MIN).toFixed(2));
});

test('computeChargeFromSeconds — 60-minute call charges 60 minutes total', () => {
  const c = computeChargeFromSeconds(60 * 60);
  assert.equal(c.minutes, 60);
  const expectedOvertimeMin = Math.max(0, 60 - FREE_CALL_MINUTES);
  assert.equal(c.overtimeMinutes, expectedOvertimeMin);
  assert.equal(c.overtimeIls, +(expectedOvertimeMin * OVERTIME_ILS_PER_MIN).toFixed(2));
  assert.equal(
    c.totalIls,
    +(CONSULTATION_ILS + expectedOvertimeMin * OVERTIME_ILS_PER_MIN).toFixed(2),
  );
});

test('computeChargeFromSeconds — negative input is treated as zero', () => {
  const c = computeChargeFromSeconds(-100);
  assert.equal(c.durationSeconds, 0);
  assert.equal(c.minutes, 1);
  assert.equal(c.totalIls, CONSULTATION_ILS);
});
