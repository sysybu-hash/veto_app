// ============================================================
//  payment.controller.js
//  VETO Legal — plans (demo / standard / family) + consultation
//  Routes:
//    POST /api/payments/plan          { planId }   (auth)
//    POST /api/payments/consultation               (auth)
//    POST /api/payments/capture       { orderId, type, planId? } (auth)
//    GET  /api/payments/me/plan                    (auth)
// ============================================================

const crypto = require('crypto');
const { createOrder, captureOrder } = require('../services/paypal.service');
const User = require('../models/User');
const {
  PLANS,
  CONSULTATION_ILS,
  OVERTIME_ILS_PER_MIN,
  FREE_CALL_MINUTES,
  ilsToUsd,
} = require('../config/pricing');

const WEB_APP_URL = (
  process.env.WEB_APP_URL ||
  process.env.FRONTEND_URL ||
  'http://localhost:3000'
).replace(/\/$/, '');

function isPaidPlanId(id) {
  return id === 'standard' || id === 'family';
}

function planExpiry(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

// ── POST /api/payments/plan  { planId: 'demo'|'standard'|'family' }
exports.createPlanOrder = async (req, res) => {
  const planId = String(req.body?.planId || '').toLowerCase();
  const plan = PLANS[planId];
  if (!plan) return res.status(400).json({ error: 'Unknown planId' });

  // Demo activates immediately, no payment.
  if (planId === 'demo') {
    if (!req.user?.userId) {
      return res.status(401).json({ error: 'Authentication required for demo activation.' });
    }
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.demo_started_at) {
      return res.status(409).json({ error: 'Demo plan already used on this account.' });
    }
    user.subscription_plan = 'demo';
    user.is_subscribed = true;
    user.demo_started_at = new Date();
    user.subscription_expiry = planExpiry(plan.durationDays);
    user.consultations_included = 0;
    user.consultations_used = 0;
    await user.save();
    return res.json({ success: true, planId: 'demo', expiry: user.subscription_expiry });
  }

  if (!isPaidPlanId(planId)) {
    return res.status(400).json({ error: 'Plan is not purchasable.' });
  }

  try {
    const usd = ilsToUsd(plan.monthlyIls);
    const { orderId, approveUrl } = await createOrder(
      usd,
      'USD',
      `VETO Legal — מנוי ${plan.label} ₪${plan.monthlyIls}`,
      `${WEB_APP_URL}/payments/return?type=plan&planId=${planId}`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=plan&planId=${planId}`,
    );
    res.json({ orderId, approveUrl, planId, amountIls: plan.monthlyIls });
  } catch (err) {
    console.error('[payment] plan create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/consultation
exports.createConsultationOrder = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'Authentication required.' });
  try {
    const usd = ilsToUsd(CONSULTATION_ILS);
    const { orderId, approveUrl } = await createOrder(
      usd,
      'USD',
      `VETO Legal — ייעוץ עורך דין ₪${CONSULTATION_ILS}`,
      `${WEB_APP_URL}/payments/return?type=consultation`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=consultation`,
    );
    res.json({ orderId, approveUrl, amountIls: CONSULTATION_ILS });
  } catch (err) {
    console.error('[payment] consultation create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/overtime  { minutes }
exports.createOvertimeOrder = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'Authentication required.' });
  const minutes = Math.max(0, Math.ceil(Number(req.body?.minutes) || 0));
  const overMin = Math.max(0, minutes - FREE_CALL_MINUTES);
  if (overMin <= 0) {
    return res.status(400).json({ error: 'No overtime to charge.' });
  }
  const ils = +(overMin * OVERTIME_ILS_PER_MIN).toFixed(2);
  try {
    const usd = ilsToUsd(ils);
    const { orderId, approveUrl } = await createOrder(
      usd,
      'USD',
      `VETO Legal — חיוב ${overMin} דקות נוספות (₪${ils.toFixed(2)})`,
      `${WEB_APP_URL}/payments/return?type=overtime`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=overtime`,
    );
    res.json({ orderId, approveUrl, amountIls: ils, overtimeMinutes: overMin });
  } catch (err) {
    console.error('[payment] overtime create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/capture  { orderId, type, planId? }
exports.capturePayment = async (req, res) => {
  const { orderId, type, planId } = req.body || {};
  if (!orderId) return res.status(400).json({ error: 'orderId is required' });

  const role = req.user?.role;
  if (role !== 'user' && role !== 'admin') {
    return res.status(403).json({ error: 'Only citizen accounts can complete this payment.' });
  }
  const userId = req.user.userId;

  try {
    const result = await captureOrder(orderId);
    if (!result.success || !userId) {
      return res.json({ success: result.success, captureId: result.captureId, status: result.status });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (type === 'plan' || type === 'subscription') {
      const id = (planId || 'standard').toLowerCase();
      const plan = PLANS[id];
      if (!plan || !isPaidPlanId(id)) {
        return res.status(400).json({ error: 'Unsupported planId for capture.' });
      }
      user.subscription_plan = id;
      user.is_subscribed = true;
      user.subscription_expiry = planExpiry(plan.durationDays);
      user.consultations_included = plan.consultationsIncluded;
      user.consultations_used = 0;
      if (id === 'family' && !user.family_owner_id) {
        user.family_owner_id = user._id;
      }
      await user.save();
    } else if (type === 'overtime') {
      // Overtime is consumed immediately on capture; no extra state needed beyond the
      // PayPal capture record. Returning success lets the client close the summary.
      return res.json({ success: true, captureId: result.captureId, status: result.status });
    } else if (type === 'consultation') {
      const token = crypto.randomBytes(16).toString('hex');
      user.pending_consultation_token = token;
      await user.save();
      return res.json({
        success: true,
        captureId: result.captureId,
        status: result.status,
        consultationToken: token,
      });
    }

    res.json({ success: true, captureId: result.captureId, status: result.status });
  } catch (err) {
    console.error('[payment] capture:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── GET /api/payments/me/plan
exports.getMyPlan = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'auth required' });
  const user = await User.findById(req.user.userId).select(
    'subscription_plan subscription_expiry consultations_included consultations_used demo_started_at family_owner_id is_subscribed manually_added',
  );
  if (!user) return res.status(404).json({ error: 'User not found' });
  const expired =
    user.subscription_expiry && user.subscription_expiry < new Date();
  res.json({
    planId: expired ? null : user.subscription_plan,
    expiry: user.subscription_expiry,
    consultationsIncluded: user.consultations_included || 0,
    consultationsUsed: user.consultations_used || 0,
    consultationsRemaining: Math.max(
      0,
      (user.consultations_included || 0) - (user.consultations_used || 0),
    ),
    demoStartedAt: user.demo_started_at,
    isFamilyOwner:
      user.subscription_plan === 'family' &&
      String(user.family_owner_id) === String(user._id),
    paymentExempt: !!user.manually_added,
  });
};

// ── Backwards-compat: keep old /subscription endpoint pointing to standard plan.
exports.createSubscriptionOrder = (req, res) => {
  req.body = { ...(req.body || {}), planId: 'standard' };
  return exports.createPlanOrder(req, res);
};
