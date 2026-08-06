const payout = require('../services/lawyerPayout.service');

exports.getLawyerPayoutSettings = async (req, res, next) => {
  try {
    res.json({ status: 'success', data: payout.payoutSettingsPublic() });
  } catch (err) {
    next(err);
  }
};

exports.syncLawyerEarnings = async (req, res, next) => {
  try {
    const result = await payout.syncEarningsFromEvents({
      limit: Math.min(2000, Number(req.body?.limit) || 500),
    });
    res.json({ status: 'success', data: result });
  } catch (err) {
    next(err);
  }
};

exports.listLawyerFinance = async (req, res, next) => {
  try {
    const lawyers = await payout.listLawyerFinanceSummary();
    res.json({
      status: 'success',
      data: {
        settings: payout.payoutSettingsPublic(),
        lawyers,
      },
    });
  } catch (err) {
    next(err);
  }
};

exports.listLawyerEarnings = async (req, res, next) => {
  try {
    const { lawyerId } = req.params;
    const from = req.query.from ? new Date(req.query.from) : undefined;
    const to = req.query.to ? new Date(req.query.to) : undefined;
    const earnings = await payout.listEarningsForLawyer(lawyerId, {
      status: req.query.status || undefined,
      from: from && !Number.isNaN(from.getTime()) ? from : undefined,
      to: to && !Number.isNaN(to.getTime()) ? to : undefined,
      limit: Math.min(500, Number(req.query.limit) || 100),
    });
    res.json({ status: 'success', data: { earnings } });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.updateLawyerPayoutProfile = async (req, res, next) => {
  try {
    const allowed = [
      'method',
      'paypal_email',
      'bank_holder_name',
      'bank_name',
      'bank_iban',
      'bank_branch',
      'bank_account',
      'notes',
      'custom_call_fee_ils',
      'custom_overtime_share',
    ];
    const patch = {};
    for (const k of allowed) {
      if (req.body?.[k] !== undefined) patch[k] = req.body[k];
    }
    const updated = await payout.updateLawyerPayoutProfile(req.params.lawyerId, patch);
    res.json({ status: 'success', data: { payout: updated } });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.createLawyerPayout = async (req, res, next) => {
  try {
    const lawyerId = req.body?.lawyerId || req.params.lawyerId;
    if (!lawyerId) {
      return res.status(400).json({ error: 'lawyerId נדרש.' });
    }
    const batch = await payout.createPayoutBatch({
      lawyerId,
      earningIds: Array.isArray(req.body?.earningIds) ? req.body.earningIds : undefined,
      adminId: req.user?.userId || null,
      notes: req.body?.notes,
      paymentMethod: req.body?.paymentMethod || 'manual',
    });
    res.status(201).json({
      status: 'success',
      data: {
        id: String(batch._id),
        amountIls: batch.amount_ils,
        callsCount: batch.calls_count,
        status: batch.status,
      },
    });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.markLawyerPayoutPaid = async (req, res, next) => {
  try {
    const batch = await payout.markPayoutPaid(req.params.batchId, {
      paymentRef: req.body?.paymentRef,
      notes: req.body?.notes,
    });
    res.json({
      status: 'success',
      data: {
        id: String(batch._id),
        status: batch.status,
        paidAt: batch.paid_at,
        paymentRef: batch.payment_ref,
      },
    });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.cancelLawyerPayout = async (req, res, next) => {
  try {
    const batch = await payout.cancelPayoutBatch(req.params.batchId);
    res.json({
      status: 'success',
      data: { id: String(batch._id), status: batch.status },
    });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.listLawyerPayoutBatches = async (req, res, next) => {
  try {
    const batches = await payout.listPayoutBatches({
      lawyerId: req.query.lawyerId || undefined,
      limit: Math.min(200, Number(req.query.limit) || 50),
    });
    res.json({ status: 'success', data: { batches } });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
};

exports.exportLawyerEarningsCsv = async (req, res, next) => {
  try {
    const lawyerId = req.query.lawyerId;
    if (!lawyerId) {
      return res.status(400).json({ error: 'lawyerId נדרש.' });
    }
    const from = req.query.from ? new Date(req.query.from) : undefined;
    const to = req.query.to ? new Date(req.query.to) : undefined;
    const earnings = await payout.listEarningsForLawyer(lawyerId, {
      status: req.query.status || undefined,
      from: from && !Number.isNaN(from.getTime()) ? from : undefined,
      to: to && !Number.isNaN(to.getTime()) ? to : undefined,
      limit: 2000,
    });
    const header = [
      'earning_id',
      'event_id',
      'completed_at',
      'duration_sec',
      'base_fee_ils',
      'overtime_share_ils',
      'lawyer_amount_ils',
      'charge_status',
      'status',
      'payout_batch_id',
    ].join(',');
    const lines = earnings.map((e) =>
      [
        e.id,
        e.eventId,
        e.callCompletedAt ? new Date(e.callCompletedAt).toISOString() : '',
        e.durationSeconds,
        e.baseFeeIls,
        e.overtimeShareIls,
        e.lawyerAmountIls,
        e.chargeStatus || '',
        e.status,
        e.payoutBatchId || '',
      ].join(','),
    );
    const csv = `\uFEFF${header}\n${lines.join('\n')}`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="lawyer-earnings-${lawyerId}.csv"`,
    );
    res.send(csv);
  } catch (err) {
    next(err);
  }
};
