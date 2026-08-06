// ============================================================
//  Admin-editable pricing.
//
//  Prices used to be literals requiring a deploy. Now an admin can change what
//  a consultation costs from the console, which means three things must hold:
//  a bad value can never be saved, a saved value must reach the billing math
//  without a restart, and a price change must NOT rewrite money that was
//  already recorded.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

let pricing;
let billing;
let payout;
let LawyerEarning;

test.before(async () => {
  await startMemoryDb();
  pricing = require('../src/services/pricingSettings.service');
  billing = require('../src/services/call/billing.service');
  payout = require('../src/services/lawyerPayout.service');
  LawyerEarning = require('../src/models/LawyerEarning');
});

test.after(async () => {
  pricing.stopPricingRefresh();
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
  await pricing.loadPricing({ force: true });
});

test('with nothing saved, the code defaults are in force', async () => {
  const p = pricing.getPricing();
  const d = pricing.codeDefaults();
  assert.deepEqual(p, d);
});

test('a saved price reaches the billing math without a restart', async () => {
  const before = billing.computeChargeFromSeconds(20 * 60);
  assert.equal(before.baseIls, 79.9);
  assert.equal(before.overtimeMinutes, 5);
  assert.equal(before.overtimeIls, 2.5);

  await pricing.updatePricing({
    consultationIls: 99.9,
    overtimeIlsPerMin: 1.25,
    freeCallMinutes: 10,
  });

  const after = billing.computeChargeFromSeconds(20 * 60);
  assert.equal(after.baseIls, 99.9, 'new consultation price must apply');
  assert.equal(after.overtimeMinutes, 10, 'new free-minute window must apply');
  assert.equal(after.overtimeIls, 12.5, 'new per-minute rate must apply');
  assert.equal(after.totalIls, 112.4);
});

test('lawyer rates follow the platform setting', async () => {
  await pricing.updatePricing({ lawyerCallFeeIls: 70, lawyerOvertimeShare: 0.5 });
  const earning = await payout.upsertEarningFromEvent({
    _id: new mongoose.Types.ObjectId(),
    assigned_lawyer_id: new mongoose.Types.ObjectId(),
    status: 'completed',
    completed_at: new Date(),
    charge_amount_ils: 10,
    charge_status: 'paid',
  });
  assert.equal(earning.base_fee_ils, 70);
  assert.equal(earning.overtime_share_ils, 5);
  assert.equal(earning.lawyer_amount_ils, 75);
});

test("a lawyer's own override still beats the platform rate", async () => {
  await pricing.updatePricing({ lawyerCallFeeIls: 70, lawyerOvertimeShare: 0.5 });
  const earning = await payout.upsertEarningFromEvent(
    {
      _id: new mongoose.Types.ObjectId(),
      assigned_lawyer_id: new mongoose.Types.ObjectId(),
      status: 'completed',
      completed_at: new Date(),
      charge_amount_ils: 10,
      charge_status: 'paid',
    },
    { payout: { custom_call_fee_ils: 120, custom_overtime_share: 0.9 } },
  );
  assert.equal(earning.base_fee_ils, 120);
  assert.equal(earning.overtime_share_ils, 9);
});

test('raising a price does NOT rewrite earnings already recorded', async () => {
  const lawyerId = new mongoose.Types.ObjectId();
  const eventId = new mongoose.Types.ObjectId();
  const before = await payout.upsertEarningFromEvent({
    _id: eventId,
    assigned_lawyer_id: lawyerId,
    status: 'completed',
    completed_at: new Date(),
    charge_amount_ils: 0,
    charge_status: 'none',
  });
  const originalAmount = before.lawyer_amount_ils;

  // Settle it, then double the rate.
  const batch = await payout.createPayoutBatch({ lawyerId, adminId: null });
  await payout.markPayoutPaid(batch._id);
  await pricing.updatePricing({ lawyerCallFeeIls: 200 });

  // Re-running the sync must not touch a settled row.
  await payout.upsertEarningFromEvent({
    _id: eventId,
    assigned_lawyer_id: lawyerId,
    status: 'completed',
    completed_at: new Date(),
    charge_amount_ils: 0,
    charge_status: 'none',
  });

  const after = await LawyerEarning.findOne({ emergency_event_id: eventId }).lean();
  assert.equal(
    after.lawyer_amount_ils,
    originalAmount,
    'a settled earning must keep the rate it was earned at',
  );
  assert.equal(after.status, 'paid');
});

test('out-of-range and non-numeric values are refused', async () => {
  for (const bad of [
    { consultationIls: -1 },
    { consultationIls: 999999 },
    { overtimeIlsPerMin: 'abc' },
    { lawyerOvertimeShare: 1.5 },
    { freeCallMinutes: 2.5 },
  ]) {
    await assert.rejects(
      () => pricing.updatePricing(bad),
      (err) => err.status === 400,
      `must refuse ${JSON.stringify(bad)}`,
    );
  }
  // Nothing was persisted by the failed attempts.
  assert.deepEqual(pricing.getPricing(), pricing.codeDefaults());
});

test('a partial patch leaves the other prices alone', async () => {
  await pricing.updatePricing({ consultationIls: 120 });
  const p = pricing.getPricing();
  assert.equal(p.consultationIls, 120);
  assert.equal(p.overtimeIlsPerMin, pricing.codeDefaults().overtimeIlsPerMin);
  assert.equal(p.freeCallMinutes, pricing.codeDefaults().freeCallMinutes);
});

test('updatePricing reports exactly what changed, for the audit trail', async () => {
  const res = await pricing.updatePricing({ consultationIls: 88, overtimeIlsPerMin: 0.5 });
  assert.deepEqual(res.changed, ['consultationIls'], 'unchanged fields must not be reported');
  assert.equal(res.before.consultationIls, 79.9);
  assert.equal(res.after.consultationIls, 88);
});

test('another instance picks the change up on refresh', async () => {
  await pricing.updatePricing({ consultationIls: 55 });
  // Simulate a second process whose cache predates the write.
  const AppSetting = require('../src/models/AppSetting');
  await AppSetting.updateOne(
    { key: pricing.SETTING_KEY },
    { $set: { 'value.consultationIls': 66 } },
  );
  await pricing.loadPricing({ force: true });
  assert.equal(pricing.getPricing().consultationIls, 66);
});

test('subscription plans are exposed read-only and say where they really live', () => {
  const plans = pricing.subscriptionPlansReadOnly();
  const standard = plans.find((p) => p.id === 'standard');
  assert.ok(standard, 'standard plan must be listed');
  assert.equal(standard.paypalPlanIdEnv, 'PAYPAL_STANDARD_PLAN_ID');
  assert.ok(
    !Object.keys(pricing.FIELDS).some((k) => k.toLowerCase().includes('monthly')),
    'subscription price must NOT be an editable field — PayPal owns it',
  );
});
