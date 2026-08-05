// Guards the lawyer payout money math. These numbers decide what VETO actually
// owes each lawyer, so a silent regression here is a financial bug, not a UI one.
const test = require('node:test');
const assert = require('node:assert');
const Module = require('node:module');

// Stub the Mongoose models before requiring the service — this test covers the
// pure arithmetic and must not need a live database.
const originalLoad = Module._load;
const chainable = (value) => {
  const chain = {
    select: () => chain,
    sort: () => chain,
    limit: () => chain,
    populate: () => chain,
    lean: async () => value,
    then: (resolve, reject) => Promise.resolve(value).then(resolve, reject),
  };
  return chain;
};

const stubModel = () => ({
  findOne: async () => null,
  findById: () => chainable(null),
  find: () => chainable([]),
  aggregate: async () => [],
  create: async (doc) => doc,
  exists: async () => false,
  updateMany: async () => ({ modifiedCount: 0 }),
  findOneAndUpdate: async (_q, update) => ({
    ...update.$set,
    ...update.$setOnInsert,
  }),
  deleteOne: async () => ({ deletedCount: 1 }),
});

Module._load = function patched(request, parent, isMain) {
  if (
    request.endsWith('/EmergencyEvent') ||
    request.endsWith('/Lawyer') ||
    request.endsWith('/LawyerEarning') ||
    request.endsWith('/LawyerPayoutBatch')
  ) {
    return stubModel();
  }
  return originalLoad(request, parent, isMain);
};

const payout = require('../src/services/lawyerPayout.service');
const { CONSULTATION_ILS, LAWYER_CALL_FEE_ILS } = require('../src/config/pricing');

Module._load = originalLoad;

const baseEvent = {
  _id: 'event-1',
  assigned_lawyer_id: 'lawyer-1',
  status: 'completed',
  completed_at: new Date('2026-08-01T10:00:00Z'),
  call_duration_seconds: 900,
};

test('round2 — money is rounded to agorot, never left as float noise', () => {
  assert.strictEqual(payout.round2(0.1 + 0.2), 0.3);
  assert.strictEqual(payout.round2(51.935), 51.94);
  assert.strictEqual(payout.round2(undefined), 0);
});

test('a paid overtime call pays base fee plus the overtime share', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    charge_amount_ils: 10,
    charge_status: 'paid',
  });
  assert.strictEqual(earning.base_fee_ils, LAWYER_CALL_FEE_ILS);
  assert.strictEqual(earning.overtime_share_ils, payout.round2(10 * 0.7));
  assert.strictEqual(
    earning.lawyer_amount_ils,
    payout.round2(LAWYER_CALL_FEE_ILS + 10 * 0.7),
  );
});

test('a pending (not yet captured) overtime charge still accrues the share', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    charge_amount_ils: 20,
    charge_status: 'pending',
  });
  assert.strictEqual(earning.overtime_share_ils, payout.round2(20 * 0.7));
});

test('no overtime — the lawyer still earns the flat activity fee', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    charge_amount_ils: 0,
    charge_status: 'none',
  });
  assert.strictEqual(earning.overtime_share_ils, 0);
  assert.strictEqual(earning.lawyer_amount_ils, LAWYER_CALL_FEE_ILS);
});

test('a waived call books ZERO consultation revenue and a negative platform margin', async () => {
  // Regression guard: booking CONSULTATION_ILS on payment-exempt calls inflated
  // reported profit on every white-glove account.
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    charge_amount_ils: 0,
    charge_status: 'waived',
  });
  assert.strictEqual(earning.consultation_revenue_ils, 0);
  assert.strictEqual(earning.overtime_share_ils, 0);
  assert.strictEqual(earning.lawyer_amount_ils, LAWYER_CALL_FEE_ILS);
  assert.strictEqual(earning.platform_amount_ils, payout.round2(-LAWYER_CALL_FEE_ILS));
  assert.ok(
    earning.platform_amount_ils < 0,
    'an exempt call is a real cost and must not be clamped to zero',
  );
});

test('a normal call books the consultation fee as platform revenue', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    charge_amount_ils: 0,
    charge_status: 'none',
  });
  assert.strictEqual(earning.consultation_revenue_ils, CONSULTATION_ILS);
  assert.strictEqual(
    earning.platform_amount_ils,
    payout.round2(CONSULTATION_ILS - LAWYER_CALL_FEE_ILS),
  );
});

test('lawyer + platform split always reconciles to gross revenue', async () => {
  for (const [charge, status] of [
    [0, 'none'],
    [10, 'paid'],
    [37.5, 'pending'],
    [0, 'waived'],
  ]) {
    const e = await payout.upsertEarningFromEvent({
      ...baseEvent,
      charge_amount_ils: charge,
      charge_status: status,
    });
    const gross = payout.round2(e.consultation_revenue_ils + e.charge_amount_ils);
    assert.strictEqual(
      payout.round2(e.lawyer_amount_ils + e.platform_amount_ils),
      gross,
      `split must reconcile for charge=${charge} status=${status}`,
    );
  }
});

test('an event with no assigned lawyer creates nothing', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    assigned_lawyer_id: null,
  });
  assert.strictEqual(earning, null);
});

test('an unfinished call creates nothing', async () => {
  const earning = await payout.upsertEarningFromEvent({
    ...baseEvent,
    status: 'in_progress',
    completed_at: null,
  });
  assert.strictEqual(earning, null);
});

test('per-lawyer rate overrides beat the global defaults', async () => {
  const earning = await payout.upsertEarningFromEvent(
    { ...baseEvent, charge_amount_ils: 10, charge_status: 'paid' },
    { payout: { custom_call_fee_ils: 100, custom_overtime_share: 0.5 } },
  );
  assert.strictEqual(earning.base_fee_ils, 100);
  assert.strictEqual(earning.overtime_share_ils, 5);
  assert.strictEqual(earning.lawyer_amount_ils, 105);
});

test('upsert is keyed on the event so a concurrent second write cannot duplicate it', async () => {
  // The service must use an atomic findOneAndUpdate+upsert on emergency_event_id;
  // a findOne-then-create races between finishCallBilling and capturePayment.
  const src = require('node:fs').readFileSync(
    require.resolve('../src/services/lawyerPayout.service'),
    'utf8',
  );
  assert.match(src, /findOneAndUpdate\(\s*\{\s*emergency_event_id/);
  assert.match(src, /upsert:\s*true/);
});
