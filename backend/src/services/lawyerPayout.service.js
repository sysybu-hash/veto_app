const mongoose = require('mongoose');
const EmergencyEvent = require('../models/EmergencyEvent');
const Lawyer = require('../models/Lawyer');
const LawyerEarning = require('../models/LawyerEarning');
const LawyerPayoutBatch = require('../models/LawyerPayoutBatch');
const {
  CONSULTATION_ILS,
  LAWYER_CALL_FEE_ILS,
  LAWYER_OVERTIME_SHARE,
} = require('../config/pricing');
const logger = require('../lib/logger');

function round2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

function asObjectId(id) {
  if (!id) return null;
  if (id instanceof mongoose.Types.ObjectId) return id;
  const s = String(id);
  if (!mongoose.Types.ObjectId.isValid(s)) return null;
  return new mongoose.Types.ObjectId(s);
}

function resolveRates(lawyerDoc) {
  const payout = lawyerDoc?.payout || {};
  const baseFee =
    payout.custom_call_fee_ils != null && Number.isFinite(Number(payout.custom_call_fee_ils))
      ? Number(payout.custom_call_fee_ils)
      : LAWYER_CALL_FEE_ILS;
  const overtimeShare =
    payout.custom_overtime_share != null && Number.isFinite(Number(payout.custom_overtime_share))
      ? Number(payout.custom_overtime_share)
      : LAWYER_OVERTIME_SHARE;
  return { baseFee: round2(baseFee), overtimeShare };
}

/**
 * Upsert a LawyerEarning from a completed EmergencyEvent with assigned lawyer.
 */
async function upsertEarningFromEvent(event, lawyerDoc = null) {
  if (!event?._id || !event.assigned_lawyer_id) return null;
  const status = String(event.status || '');
  if (!['completed', 'closed'].includes(status) && !event.completed_at) {
    return null;
  }

  let lawyer = lawyerDoc;
  if (!lawyer) {
    lawyer = await Lawyer.findById(event.assigned_lawyer_id).select('payout').lean();
  }
  const { baseFee, overtimeShare } = resolveRates(lawyer);

  const chargeIls = round2(event.charge_amount_ils);
  const chargeStatus = event.charge_status || 'none';
  // Count overtime share once the citizen charge is pending or paid (not waived).
  const overtimeShareIls =
    chargeStatus === 'paid' || chargeStatus === 'pending'
      ? round2(chargeIls * overtimeShare)
      : 0;

  const lawyerAmount = round2(baseFee + overtimeShareIls);
  // `charge_amount_ils` on the event is the OVERTIME charge only — the base
  // consultation is covered by the citizen's plan. `waived` means the account is
  // payment-exempt (admin / manually_added), so no consultation revenue was
  // recognised for this call at all. Booking CONSULTATION_ILS unconditionally
  // would inflate reported platform profit on every white-glove call.
  const consultationRevenueIls = chargeStatus === 'waived' ? 0 : CONSULTATION_ILS;
  const platformGross = round2(consultationRevenueIls + chargeIls);
  // Deliberately NOT clamped at 0: an exempt call really does cost the platform
  // the lawyer's base fee, and that loss must stay visible in the report.
  const platformAmount = round2(platformGross - lawyerAmount);

  const existing = await LawyerEarning.findOne({
    emergency_event_id: event._id,
  });
  if (existing && (existing.status === 'paid' || existing.status === 'included_in_payout')) {
    // Don't rewrite locked earnings; only refresh charge snapshot lightly.
    existing.charge_amount_ils = chargeIls;
    existing.charge_status = chargeStatus;
    await existing.save();
    return existing;
  }

  const payload = {
    lawyer_id: event.assigned_lawyer_id,
    emergency_event_id: event._id,
    user_id: event.user_id || null,
    call_completed_at: event.completed_at || event.updatedAt || new Date(),
    call_duration_seconds: Number(event.call_duration_seconds) || 0,
    call_type: event.call_type || null,
    charge_amount_ils: chargeIls,
    charge_status: chargeStatus,
    base_fee_ils: baseFee,
    overtime_share_ils: overtimeShareIls,
    lawyer_amount_ils: lawyerAmount,
    consultation_revenue_ils: consultationRevenueIls,
    platform_amount_ils: platformAmount,
    commission_rate: overtimeShare,
  };

  // Atomic upsert keyed on the unique emergency_event_id. finishCallBilling and
  // capturePayment can both land here for the same event concurrently; a
  // findOne-then-create would race into an E11000 duplicate-key error.
  // `status` goes in $setOnInsert so a manual `void` is never resurrected.
  return LawyerEarning.findOneAndUpdate(
    { emergency_event_id: event._id },
    { $set: payload, $setOnInsert: { status: 'pending' } },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );
}

async function syncEarningsFromEvents({ limit = 500 } = {}) {
  const events = await EmergencyEvent.find({
    assigned_lawyer_id: { $ne: null },
    $or: [
      { status: { $in: ['completed', 'closed'] } },
      { completed_at: { $ne: null } },
    ],
  })
    .sort({ completed_at: -1, createdAt: -1 })
    .limit(limit)
    .lean();

  let upserted = 0;
  for (const ev of events) {
    try {
      const row = await upsertEarningFromEvent(ev);
      if (row) upserted += 1;
    } catch (err) {
      logger.warn({ err, eventId: String(ev._id) }, '[payout] sync earn failed');
    }
  }
  return { scanned: events.length, upserted };
}

async function listLawyerFinanceSummary() {
  const lawyers = await Lawyer.find({ is_approved: true })
    .select('full_name phone email is_active payout total_cases_handled')
    .lean();

  const agg = await LawyerEarning.aggregate([
    {
      $group: {
        _id: { lawyer_id: '$lawyer_id', status: '$status' },
        amount: { $sum: '$lawyer_amount_ils' },
        calls: { $sum: 1 },
        seconds: { $sum: '$call_duration_seconds' },
      },
    },
  ]);

  const byLawyer = new Map();
  for (const row of agg) {
    const id = String(row._id.lawyer_id);
    if (!byLawyer.has(id)) {
      byLawyer.set(id, {
        pendingAmount: 0,
        pendingCalls: 0,
        paidAmount: 0,
        paidCalls: 0,
        includedAmount: 0,
        includedCalls: 0,
        totalSeconds: 0,
      });
    }
    const bucket = byLawyer.get(id);
    bucket.totalSeconds += Number(row.seconds) || 0;
    if (row._id.status === 'pending') {
      bucket.pendingAmount += row.amount;
      bucket.pendingCalls += row.calls;
    } else if (row._id.status === 'paid') {
      bucket.paidAmount += row.amount;
      bucket.paidCalls += row.calls;
    } else if (row._id.status === 'included_in_payout') {
      bucket.includedAmount += row.amount;
      bucket.includedCalls += row.calls;
    }
  }

  return lawyers.map((l) => {
    const id = String(l._id);
    const s = byLawyer.get(id) || {
      pendingAmount: 0,
      pendingCalls: 0,
      paidAmount: 0,
      paidCalls: 0,
      includedAmount: 0,
      includedCalls: 0,
      totalSeconds: 0,
    };
    return {
      id,
      fullName: l.full_name || '',
      phone: l.phone || '',
      email: l.email || '',
      isActive: l.is_active !== false,
      totalCasesHandled: l.total_cases_handled || 0,
      payout: l.payout || null,
      pendingAmountIls: round2(s.pendingAmount),
      pendingCalls: s.pendingCalls,
      inPayoutAmountIls: round2(s.includedAmount),
      inPayoutCalls: s.includedCalls,
      paidAmountIls: round2(s.paidAmount),
      paidCalls: s.paidCalls,
      activitySeconds: s.totalSeconds,
      rates: resolveRates(l),
    };
  }).sort((a, b) => b.pendingAmountIls - a.pendingAmountIls);
}

async function listEarningsForLawyer(lawyerId, { status, from, to, limit = 100 } = {}) {
  const oid = asObjectId(lawyerId);
  if (!oid) {
    const err = new Error('מזהה עורך דין לא תקין.');
    err.status = 400;
    throw err;
  }
  const q = { lawyer_id: oid };
  if (status) q.status = status;
  if (from || to) {
    q.call_completed_at = {};
    if (from) q.call_completed_at.$gte = from;
    if (to) q.call_completed_at.$lte = to;
  }
  const rows = await LawyerEarning.find(q)
    .sort({ call_completed_at: -1 })
    .limit(limit)
    .lean();
  return rows.map((e) => ({
    id: String(e._id),
    eventId: String(e.emergency_event_id),
    callCompletedAt: e.call_completed_at,
    durationSeconds: e.call_duration_seconds || 0,
    callType: e.call_type,
    chargeAmountIls: e.charge_amount_ils || 0,
    chargeStatus: e.charge_status,
    baseFeeIls: e.base_fee_ils || 0,
    overtimeShareIls: e.overtime_share_ils || 0,
    lawyerAmountIls: e.lawyer_amount_ils || 0,
    status: e.status,
    payoutBatchId: e.payout_batch_id ? String(e.payout_batch_id) : null,
    notes: e.notes || '',
  }));
}

async function createPayoutBatch({
  lawyerId,
  earningIds,
  adminId,
  notes = '',
  paymentMethod = 'manual',
}) {
  const lawyerOid = asObjectId(lawyerId);
  if (!lawyerOid) {
    const err = new Error('מזהה עורך דין לא תקין.');
    err.status = 400;
    throw err;
  }
  const method = [
    'bank_transfer',
    'paypal',
    'bit',
    'cash',
    'manual',
    'other',
  ].includes(paymentMethod)
    ? paymentMethod
    : 'manual';

  // Only ever claim earnings that are still unattached. Anything already
  // carrying a payout_batch_id belongs to another batch.
  const claimQuery = {
    lawyer_id: lawyerOid,
    status: 'pending',
    payout_batch_id: null,
  };
  if (Array.isArray(earningIds) && earningIds.length > 0) {
    const ids = earningIds.map(asObjectId).filter(Boolean);
    if (ids.length === 0) {
      const err = new Error('לא נבחרו זכאויות תקינות לתשלום.');
      err.status = 400;
      throw err;
    }
    claimQuery._id = { $in: ids };
  }

  if (!(await LawyerEarning.exists(claimQuery))) {
    const err = new Error('אין זכאויות ממתינות לתשלום עבור עורך דין זה.');
    err.status = 400;
    throw err;
  }

  const adminOid = asObjectId(adminId);

  // Claim-then-total, never total-then-claim. The batch is opened as `draft`
  // (no payable amount), the claim is a single atomic updateMany that can only
  // take earnings nobody else holds, and the amount is derived from what was
  // ACTUALLY claimed. A concurrent second call therefore claims nothing and
  // fails — paying the same call twice is not reachable. If the finalise step
  // below throws, the batch stays `draft` with its earnings claimed: visible,
  // not payable, and recoverable by cancelling it.
  const batch = await LawyerPayoutBatch.create({
    lawyer_id: lawyerOid,
    status: 'draft',
    amount_ils: 0,
    payment_method: method,
    created_by_admin_id: adminOid,
    notes: String(notes || '').slice(0, 1000),
  });

  try {
    await LawyerEarning.updateMany(claimQuery, {
      $set: { status: 'included_in_payout', payout_batch_id: batch._id },
    });

    const claimed = await LawyerEarning.find({ payout_batch_id: batch._id })
      .select('_id lawyer_amount_ils call_completed_at')
      .lean();

    if (claimed.length === 0) {
      // Lost the race to a concurrent batch — nothing claimed, nothing owed.
      await LawyerPayoutBatch.deleteOne({ _id: batch._id });
      const err = new Error('הזכאויות שנבחרו כבר שויכו לתשלום אחר. רעננו ונסו שוב.');
      err.status = 409;
      throw err;
    }

    const amount = round2(
      claimed.reduce((sum, e) => sum + (Number(e.lawyer_amount_ils) || 0), 0),
    );
    const dates = claimed
      .map((e) => e.call_completed_at)
      .filter(Boolean)
      .map((d) => new Date(d).getTime());

    batch.earning_ids = claimed.map((e) => e._id);
    batch.calls_count = claimed.length;
    batch.amount_ils = amount;
    batch.period_from = dates.length ? new Date(Math.min(...dates)) : null;
    batch.period_to = dates.length ? new Date(Math.max(...dates)) : null;
    batch.status = 'pending';
    await batch.save();
    return batch;
  } catch (err) {
    if (err.status === 409) throw err;
    logger.error(
      { err, batchId: String(batch._id) },
      '[payout] batch left in draft after claim failure — cancel it to release earnings',
    );
    throw err;
  }
}

async function markPayoutPaid(batchId, { paymentRef = '', notes } = {}) {
  const batch = await LawyerPayoutBatch.findById(batchId);
  if (!batch) {
    const err = new Error('אצוות תשלום לא נמצאה.');
    err.status = 404;
    throw err;
  }
  if (batch.status === 'cancelled') {
    const err = new Error('לא ניתן לסמן אצווה מבוטלת כשולמה.');
    err.status = 400;
    throw err;
  }
  if (batch.status === 'draft') {
    // Never finalised — its amount is not trustworthy. Cancel and rebuild.
    const err = new Error('אצווה זו לא הושלמה (draft). בטלו אותה וצרו תשלום מחדש.');
    err.status = 409;
    throw err;
  }
  if (batch.status === 'paid') {
    return batch; // idempotent — a double click must not re-stamp paid_at
  }
  batch.status = 'paid';
  batch.paid_at = new Date();
  if (paymentRef) batch.payment_ref = String(paymentRef).slice(0, 200);
  if (notes != null) batch.notes = String(notes).slice(0, 1000);
  await batch.save();

  // Only the earnings this batch actually pays for. A manually voided earning
  // sitting in the batch must not be flipped to `paid`.
  await LawyerEarning.updateMany(
    { payout_batch_id: batch._id, status: 'included_in_payout' },
    { $set: { status: 'paid' } },
  );
  return batch;
}

async function cancelPayoutBatch(batchId) {
  const batch = await LawyerPayoutBatch.findById(batchId);
  if (!batch) {
    const err = new Error('אצוות תשלום לא נמצאה.');
    err.status = 404;
    throw err;
  }
  if (batch.status === 'paid') {
    const err = new Error('לא ניתן לבטל אצווה שכבר שולמה.');
    err.status = 400;
    throw err;
  }
  batch.status = 'cancelled';
  await batch.save();
  await LawyerEarning.updateMany(
    { payout_batch_id: batch._id, status: 'included_in_payout' },
    { $set: { status: 'pending', payout_batch_id: null } },
  );
  return batch;
}

async function listPayoutBatches({ lawyerId, limit = 50 } = {}) {
  const q = {};
  if (lawyerId) {
    const oid = asObjectId(lawyerId);
    if (!oid) {
      const err = new Error('מזהה עורך דין לא תקין.');
      err.status = 400;
      throw err;
    }
    q.lawyer_id = oid;
  }
  const rows = await LawyerPayoutBatch.find(q)
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('lawyer_id', 'full_name phone email')
    .lean();
  return rows.map((b) => ({
    id: String(b._id),
    lawyerId: b.lawyer_id?._id ? String(b.lawyer_id._id) : String(b.lawyer_id),
    lawyerName: b.lawyer_id?.full_name || '',
    lawyerPhone: b.lawyer_id?.phone || '',
    amountIls: b.amount_ils || 0,
    callsCount: b.calls_count || 0,
    status: b.status,
    paymentMethod: b.payment_method,
    paymentRef: b.payment_ref || '',
    paidAt: b.paid_at,
    periodFrom: b.period_from,
    periodTo: b.period_to,
    notes: b.notes || '',
    createdAt: b.createdAt,
  }));
}

async function updateLawyerPayoutProfile(lawyerId, payoutPatch) {
  const lawyer = await Lawyer.findById(lawyerId);
  if (!lawyer) {
    const err = new Error('עורך דין לא נמצא.');
    err.status = 404;
    throw err;
  }
  const next = { ...(lawyer.payout?.toObject?.() || lawyer.payout || {}), ...payoutPatch };
  lawyer.payout = next;
  await lawyer.save();
  return lawyer.payout;
}

function payoutSettingsPublic() {
  return {
    callFeeIls: LAWYER_CALL_FEE_ILS,
    overtimeShare: LAWYER_OVERTIME_SHARE,
    consultationIls: CONSULTATION_ILS,
  };
}

module.exports = {
  upsertEarningFromEvent,
  syncEarningsFromEvents,
  listLawyerFinanceSummary,
  listEarningsForLawyer,
  createPayoutBatch,
  markPayoutPaid,
  cancelPayoutBatch,
  listPayoutBatches,
  updateLawyerPayoutProfile,
  payoutSettingsPublic,
  round2,
};
