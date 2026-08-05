// ============================================================
//  Concurrency guarantees for lawyer payouts — against a REAL MongoDB.
//
//  lawyer_payout_service.test.js stubs Mongoose and only proves the money
//  arithmetic. It cannot prove the part that actually risks paying a lawyer
//  twice: that two overlapping createPayoutBatch calls can never both claim
//  the same earning. That needs a real server, real indexes and a real
//  updateMany, so this file uses mongodb-memory-server.
//
//  The invariant under test: for any interleaving, every pending earning ends
//  up in AT MOST ONE batch, and the sum of the batches never exceeds the sum
//  of the earnings.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

let payout;
let Lawyer;
let LawyerEarning;
let LawyerPayoutBatch;

test.before(async () => {
  await startMemoryDb();
  payout = require('../src/services/lawyerPayout.service');
  Lawyer = require('../src/models/Lawyer');
  LawyerEarning = require('../src/models/LawyerEarning');
  LawyerPayoutBatch = require('../src/models/LawyerPayoutBatch');
  await LawyerEarning.syncIndexes();
});

test.after(async () => {
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
});

async function seedLawyerWithEarnings(count, amount = 60) {
  const lawyer = await Lawyer.create({
    full_name: 'עו״ד בדיקה',
    phone: `+97250${String(Date.now()).slice(-7)}`,
    is_approved: true,
    is_active: true,
  });
  const earnings = [];
  for (let i = 0; i < count; i += 1) {
    earnings.push(
      await LawyerEarning.create({
        lawyer_id: lawyer._id,
        emergency_event_id: new mongoose.Types.ObjectId(),
        call_completed_at: new Date(Date.now() - i * 60000),
        lawyer_amount_ils: amount,
        status: 'pending',
      }),
    );
  }
  return { lawyer, earnings };
}

test('two concurrent payout batches never claim the same earning', async () => {
  const { lawyer, earnings } = await seedLawyerWithEarnings(8);
  const expectedTotal = payout.round2(8 * 60);

  const results = await Promise.allSettled([
    payout.createPayoutBatch({ lawyerId: lawyer._id, adminId: null }),
    payout.createPayoutBatch({ lawyerId: lawyer._id, adminId: null }),
  ]);

  const fulfilled = results.filter((r) => r.status === 'fulfilled');
  assert.ok(fulfilled.length >= 1, 'at least one batch must succeed');

  // No earning may carry two batch ids, and none may be left unclaimed while
  // a batch that includes it exists.
  const rows = await LawyerEarning.find({ lawyer_id: lawyer._id }).lean();
  assert.equal(rows.length, earnings.length);

  const batches = await LawyerPayoutBatch.find({
    lawyer_id: lawyer._id,
    status: { $ne: 'cancelled' },
  }).lean();

  const seen = new Map();
  for (const b of batches) {
    for (const id of b.earning_ids) {
      const k = String(id);
      assert.ok(
        !seen.has(k),
        `earning ${k} appears in two batches (${seen.get(k)} and ${b._id}) — double payment`,
      );
      seen.set(k, String(b._id));
    }
  }

  // Money conservation: batches together never promise more than is owed.
  const paidOut = payout.round2(
    batches.reduce((sum, b) => sum + (b.amount_ils || 0), 0),
  );
  assert.ok(
    paidOut <= expectedTotal,
    `batches total ${paidOut} exceeds owed ${expectedTotal}`,
  );

  // And each batch's stated amount matches the earnings it actually holds.
  for (const b of batches) {
    const held = rows.filter((r) => String(r.payout_batch_id) === String(b._id));
    assert.equal(
      b.calls_count,
      held.length,
      `batch ${b._id} claims ${b.calls_count} calls but holds ${held.length}`,
    );
    assert.equal(
      payout.round2(b.amount_ils),
      payout.round2(held.reduce((s, r) => s + r.lawyer_amount_ils, 0)),
      `batch ${b._id} amount does not match the earnings it holds`,
    );
  }
});

test('five concurrent batches still pay each earning at most once', async () => {
  const { lawyer } = await seedLawyerWithEarnings(12, 25);

  await Promise.allSettled(
    Array.from({ length: 5 }, () =>
      payout.createPayoutBatch({ lawyerId: lawyer._id, adminId: null }),
    ),
  );

  const rows = await LawyerEarning.find({ lawyer_id: lawyer._id }).lean();
  const batches = await LawyerPayoutBatch.find({ lawyer_id: lawyer._id }).lean();

  const claimed = rows.filter((r) => r.payout_batch_id);
  const uniqueBatchRefs = new Set(claimed.map((r) => String(r.payout_batch_id)));
  for (const bid of uniqueBatchRefs) {
    assert.ok(
      batches.some((b) => String(b._id) === bid),
      `earning points at batch ${bid} which no longer exists`,
    );
  }

  const totalClaimed = payout.round2(
    claimed.reduce((s, r) => s + r.lawyer_amount_ils, 0),
  );
  const totalBatched = payout.round2(
    batches.reduce((s, b) => s + (b.amount_ils || 0), 0),
  );
  assert.equal(
    totalBatched,
    totalClaimed,
    'sum of batches must equal sum of claimed earnings',
  );
  assert.ok(totalClaimed <= payout.round2(12 * 25));
});

test('an empty-claim batch is deleted, not left as a zero-amount ghost', async () => {
  const { lawyer } = await seedLawyerWithEarnings(3);
  await payout.createPayoutBatch({ lawyerId: lawyer._id, adminId: null });

  // Everything is claimed now; a second call has nothing left to take.
  await assert.rejects(
    () => payout.createPayoutBatch({ lawyerId: lawyer._id, adminId: null }),
    (err) => err.status === 400 || err.status === 409,
  );

  const batches = await LawyerPayoutBatch.find({ lawyer_id: lawyer._id }).lean();
  assert.equal(batches.length, 1, 'no empty ghost batch may survive');
  assert.equal(batches[0].status, 'pending');
});

test('a duplicate earning for the same event is impossible (unique index)', async () => {
  const { lawyer } = await seedLawyerWithEarnings(0);
  const eventId = new mongoose.Types.ObjectId();
  await LawyerEarning.create({
    lawyer_id: lawyer._id,
    emergency_event_id: eventId,
    lawyer_amount_ils: 50,
  });
  await assert.rejects(
    () =>
      LawyerEarning.create({
        lawyer_id: lawyer._id,
        emergency_event_id: eventId,
        lawyer_amount_ils: 50,
      }),
    /E11000|duplicate key/i,
  );
});

test('concurrent upserts for one event produce exactly one earning', async () => {
  // finishCallBilling and capturePayment can both credit the same event.
  const { lawyer } = await seedLawyerWithEarnings(0);
  const event = {
    _id: new mongoose.Types.ObjectId(),
    assigned_lawyer_id: lawyer._id,
    status: 'completed',
    completed_at: new Date(),
    call_duration_seconds: 900,
    charge_amount_ils: 10,
    charge_status: 'paid',
  };

  await Promise.allSettled([
    payout.upsertEarningFromEvent(event),
    payout.upsertEarningFromEvent(event),
    payout.upsertEarningFromEvent(event),
  ]);

  const rows = await LawyerEarning.find({ emergency_event_id: event._id }).lean();
  assert.equal(rows.length, 1, 'the same call must never be credited twice');
});

test('cancelling a batch returns its earnings to the pending pool exactly once', async () => {
  const { lawyer } = await seedLawyerWithEarnings(4);
  const batch = await payout.createPayoutBatch({
    lawyerId: lawyer._id,
    adminId: null,
  });
  await payout.cancelPayoutBatch(batch._id);

  const rows = await LawyerEarning.find({ lawyer_id: lawyer._id }).lean();
  assert.ok(
    rows.every((r) => r.status === 'pending' && r.payout_batch_id === null),
    'cancel must fully release every earning it held',
  );

  // They can then be re-batched, and the new batch owns all four.
  const second = await payout.createPayoutBatch({
    lawyerId: lawyer._id,
    adminId: null,
  });
  assert.equal(second.calls_count, 4);
});

test('marking a batch paid never flips a voided earning to paid', async () => {
  const { lawyer, earnings } = await seedLawyerWithEarnings(3);
  const batch = await payout.createPayoutBatch({
    lawyerId: lawyer._id,
    adminId: null,
  });
  await LawyerEarning.updateOne(
    { _id: earnings[0]._id },
    { $set: { status: 'void' } },
  );

  await payout.markPayoutPaid(batch._id, { paymentRef: 'REF-1' });

  const voided = await LawyerEarning.findById(earnings[0]._id).lean();
  assert.equal(voided.status, 'void', 'a voided earning must stay void');

  const paid = await LawyerEarning.countDocuments({
    payout_batch_id: batch._id,
    status: 'paid',
  });
  assert.equal(paid, 2);
});

test('marking paid twice does not re-stamp paid_at', async () => {
  const { lawyer } = await seedLawyerWithEarnings(2);
  const batch = await payout.createPayoutBatch({
    lawyerId: lawyer._id,
    adminId: null,
  });
  const first = await payout.markPayoutPaid(batch._id, { paymentRef: 'A' });
  const stamp = new Date(first.paid_at).getTime();
  const second = await payout.markPayoutPaid(batch._id, { paymentRef: 'B' });
  assert.equal(new Date(second.paid_at).getTime(), stamp);
  assert.equal(second.payment_ref, 'A', 'the original payment reference stands');
});
