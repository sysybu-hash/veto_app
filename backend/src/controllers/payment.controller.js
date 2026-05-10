// ============================================================
//  payment.controller.js
//  VETO Legal - PayPal subscriptions, one-time consultation and overtime payments
// ============================================================

const crypto = require('crypto');
const {
  createOrder,
  captureOrder,
  createBillingSubscription,
  getBillingSubscription,
  verifyWebhookSignature,
} = require('../services/paypal.service');
const User = require('../models/User');
const EmergencyEvent = require('../models/EmergencyEvent');
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

const PAYPAL_PLAN_ENV = {
  standard: 'PAYPAL_STANDARD_PLAN_ID',
  family: 'PAYPAL_FAMILY_PLAN_ID',
};

function isPaidPlanId(id) {
  return id === 'standard' || id === 'family';
}

function planExpiry(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

function paypalPlanIdFor(planId) {
  const envName = PAYPAL_PLAN_ENV[planId];
  return envName ? process.env[envName]?.trim() : '';
}

function computeOvertimeCharge(minutes) {
  const totalMinutes = Math.max(0, Math.ceil(Number(minutes) || 0));
  const overtimeMinutes = Math.max(0, totalMinutes - FREE_CALL_MINUTES);
  return {
    minutes: totalMinutes,
    overtimeMinutes,
    amountIls: +(overtimeMinutes * OVERTIME_ILS_PER_MIN).toFixed(2),
  };
}

function minutesFromEvent(event, fallbackMinutes) {
  if (event?.call_duration_seconds) {
    return Math.max(1, Math.ceil(event.call_duration_seconds / 60));
  }
  if (event?.call_started_at) {
    const end = event.completed_at || new Date();
    return Math.max(1, Math.ceil((new Date(end).getTime() - new Date(event.call_started_at).getTime()) / 60000));
  }
  return Math.max(0, Math.ceil(Number(fallbackMinutes) || 0));
}

async function activateUserPlan(user, planId, paypal = {}) {
  const plan = PLANS[planId];
  user.subscription_plan = planId;
  user.is_subscribed = true;
  user.subscription_status = paypal.status || 'ACTIVE';
  user.subscription_plan_id = paypal.planId || paypalPlanIdFor(planId) || null;
  user.paypal_subscription_id = paypal.subscriptionId || user.paypal_subscription_id || null;
  user.subscription_expiry = paypal.periodEnd || planExpiry(plan.durationDays);
  user.subscription_current_period_end = user.subscription_expiry;
  user.consultations_included = plan.consultationsIncluded;
  user.consultations_used = 0;
  if (planId === 'family' && !user.family_owner_id) {
    user.family_owner_id = user._id;
  }
  await user.save();
}

exports.createPlanOrder = async (req, res) => {
  const planId = String(req.body?.planId || '').toLowerCase();
  const plan = PLANS[planId];
  if (!plan) return res.status(400).json({ error: 'Unknown planId' });
  if (!req.user?.userId) return res.status(401).json({ error: 'Authentication required.' });

  const user = await User.findById(req.user.userId);
  if (!user) return res.status(404).json({ error: 'User not found' });

  if (planId === 'demo') {
    if (user.demo_started_at) {
      return res.status(409).json({ error: 'Demo plan already used on this account.' });
    }
    user.subscription_plan = 'demo';
    user.is_subscribed = true;
    user.subscription_status = 'DEMO';
    user.demo_started_at = new Date();
    user.subscription_expiry = planExpiry(plan.durationDays);
    user.subscription_current_period_end = user.subscription_expiry;
    user.consultations_included = 0;
    user.consultations_used = 0;
    await user.save();
    return res.json({ success: true, planId: 'demo', expiry: user.subscription_expiry });
  }

  if (!isPaidPlanId(planId)) {
    return res.status(400).json({ error: 'Plan is not purchasable.' });
  }

  const paypalPlanId = paypalPlanIdFor(planId);
  try {
    const { subscriptionId, approveUrl, status } = await createBillingSubscription({
      planId: paypalPlanId,
      customId: `${user._id}:${planId}`,
      returnUrl: `${WEB_APP_URL}/payments/return?type=plan&planId=${planId}`,
      cancelUrl: `${WEB_APP_URL}/payments/return?cancel=1&type=plan&planId=${planId}`,
    });

    user.subscription_plan = planId;
    user.paypal_subscription_id = subscriptionId;
    user.subscription_status = status || 'APPROVAL_PENDING';
    user.subscription_plan_id = paypalPlanId;
    await user.save();

    return res.json({
      subscriptionId,
      approveUrl,
      planId,
      amountIls: plan.monthlyIls,
      status,
    });
  } catch (err) {
    console.error('[payment] plan subscription create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING' || err.code === 'PAYPAL_PLAN_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    return res.status(500).json({ error: err.message });
  }
};

exports.createConsultationOrder = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'Authentication required.' });
  try {
    const usd = ilsToUsd(CONSULTATION_ILS);
    const { orderId, approveUrl } = await createOrder(
      usd,
      'USD',
      `VETO Legal - consultation ${CONSULTATION_ILS} ILS`,
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

exports.createOvertimeOrder = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'Authentication required.' });
  const eventId = req.body?.eventId ? String(req.body.eventId) : null;
  let event = null;
  if (eventId) {
    event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Call event not found.' });
    const isOwner = String(event.user_id) === String(req.user.userId);
    if (!isOwner && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not allowed to pay for this event.' });
    }
  }

  const charge = computeOvertimeCharge(minutesFromEvent(event, req.body?.minutes));
  if (charge.overtimeMinutes <= 0) return res.status(400).json({ error: 'No overtime to charge.' });

  try {
    const usd = ilsToUsd(charge.amountIls);
    const eventQuery = eventId ? `&eventId=${encodeURIComponent(eventId)}` : '';
    const { orderId, approveUrl } = await createOrder(
      usd,
      'USD',
      `VETO Legal - overtime ${charge.overtimeMinutes} minutes (${charge.amountIls.toFixed(2)} ILS)`,
      `${WEB_APP_URL}/payments/return?type=overtime${eventQuery}`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=overtime${eventQuery}`,
    );
    if (event) {
      event.charge_status = 'pending';
      event.charge_minutes = charge.minutes;
      event.charge_overtime_minutes = charge.overtimeMinutes;
      event.charge_amount_ils = charge.amountIls;
      event.charge_order_id = orderId;
      event.charge_calculated_at = new Date();
      await event.save();
    }
    res.json({
      orderId,
      approveUrl,
      amountIls: charge.amountIls,
      overtimeMinutes: charge.overtimeMinutes,
      eventId,
    });
  } catch (err) {
    console.error('[payment] overtime create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

exports.capturePayment = async (req, res) => {
  const { orderId, subscriptionId, type, planId, eventId } = req.body || {};
  const paymentId = subscriptionId || orderId;
  if (!paymentId) return res.status(400).json({ error: 'orderId or subscriptionId is required' });

  const role = req.user?.role;
  if (role !== 'user' && role !== 'admin') {
    return res.status(403).json({ error: 'Only citizen accounts can complete this payment.' });
  }

  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (type === 'plan' || type === 'subscription') {
      const id = String(planId || user.subscription_plan || 'standard').toLowerCase();
      const plan = PLANS[id];
      if (!plan || !isPaidPlanId(id)) {
        return res.status(400).json({ error: 'Unsupported planId for subscription.' });
      }
      const paypalSubId = subscriptionId || orderId || user.paypal_subscription_id;
      const sub = await getBillingSubscription(paypalSubId);
      if (!['ACTIVE', 'APPROVAL_PENDING'].includes(String(sub.status || '').toUpperCase())) {
        return res.status(409).json({ error: `PayPal subscription is ${sub.status || 'not active'}.` });
      }
      await activateUserPlan(user, id, {
        subscriptionId: sub.id || paypalSubId,
        status: sub.status,
        planId: sub.plan_id,
        periodEnd: sub.billing_info?.next_billing_time ? new Date(sub.billing_info.next_billing_time) : null,
      });
      return res.json({ success: true, subscriptionId: sub.id || paypalSubId, status: sub.status });
    }

    const result = await captureOrder(orderId);
    if (!result.success) {
      return res.json({ success: false, captureId: result.captureId, status: result.status });
    }

    if (type === 'consultation') {
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

    if (type === 'overtime') {
      const query = eventId
        ? { _id: eventId }
        : { charge_order_id: orderId };
      const event = await EmergencyEvent.findOne(query);
      if (event) {
        const isOwner = String(event.user_id) === String(req.user.userId);
        if (!isOwner && req.user.role !== 'admin') {
          return res.status(403).json({ error: 'Not allowed to capture this event payment.' });
        }
        event.charge_status = 'paid';
        event.charge_order_id = orderId || event.charge_order_id;
        event.charge_capture_id = result.captureId || null;
        event.charge_paid_at = new Date();
        await event.save();
      }
      return res.json({
        success: true,
        captureId: result.captureId,
        status: result.status,
        eventId: event?._id || eventId || null,
      });
    }

    return res.json({ success: true, captureId: result.captureId, status: result.status });
  } catch (err) {
    console.error('[payment] capture:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ success: false, message: err.message });
    }
    res.status(500).json({ error: err.message });
  }
};

exports.getMyPlan = async (req, res) => {
  if (!req.user?.userId) return res.status(401).json({ error: 'auth required' });
  const user = await User.findById(req.user.userId).select(
    'subscription_plan subscription_expiry subscription_status paypal_subscription_id consultations_included consultations_used demo_started_at family_owner_id is_subscribed manually_added',
  );
  if (!user) return res.status(404).json({ error: 'User not found' });
  const expired = user.subscription_expiry && user.subscription_expiry < new Date();
  res.json({
    planId: expired ? null : user.subscription_plan,
    expiry: user.subscription_expiry,
    subscriptionStatus: user.subscription_status,
    paypalSubscriptionId: user.paypal_subscription_id,
    consultationsIncluded: user.consultations_included || 0,
    consultationsUsed: user.consultations_used || 0,
    consultationsRemaining: Math.max(0, (user.consultations_included || 0) - (user.consultations_used || 0)),
    demoStartedAt: user.demo_started_at,
    isFamilyOwner: user.subscription_plan === 'family' && String(user.family_owner_id) === String(user._id),
    paymentExempt: !!user.manually_added,
  });
};

exports.handlePayPalWebhook = async (req, res) => {
  const event = req.body;
  try {
    const verification = await verifyWebhookSignature({
      transmissionId: req.get('paypal-transmission-id'),
      transmissionTime: req.get('paypal-transmission-time'),
      certUrl: req.get('paypal-cert-url'),
      authAlgo: req.get('paypal-auth-algo'),
      transmissionSig: req.get('paypal-transmission-sig'),
      webhookId: process.env.PAYPAL_WEBHOOK_ID,
      event,
    });
    if (
      process.env.PAYPAL_WEBHOOK_ID &&
      verification.verification_status !== 'SUCCESS'
    ) {
      return res.status(400).json({ error: 'Invalid PayPal webhook signature.' });
    }

    const resource = event?.resource || {};
    const paypalSubscriptionId = resource.id || resource.billing_agreement_id || null;
    if (!paypalSubscriptionId) return res.json({ received: true });

    const user = await User.findOne({ paypal_subscription_id: paypalSubscriptionId });
    if (!user) return res.json({ received: true, ignored: 'subscription_not_found' });

    const eventType = String(event.event_type || '');
    const nextBilling = resource.billing_info?.next_billing_time
      ? new Date(resource.billing_info.next_billing_time)
      : null;

    if (eventType.includes('ACTIVATED') || eventType.includes('PAYMENT.SALE.COMPLETED')) {
      const planId = user.subscription_plan && isPaidPlanId(user.subscription_plan)
        ? user.subscription_plan
        : 'standard';
      await activateUserPlan(user, planId, {
        subscriptionId: paypalSubscriptionId,
        status: resource.status || 'ACTIVE',
        planId: resource.plan_id || user.subscription_plan_id,
        periodEnd: nextBilling,
      });
    } else if (eventType.includes('CANCELLED') || eventType.includes('SUSPENDED') || eventType.includes('EXPIRED')) {
      user.subscription_status = resource.status || eventType.split('.').pop();
      user.is_subscribed = false;
      await user.save();
    } else {
      user.subscription_status = resource.status || user.subscription_status;
      if (nextBilling) {
        user.subscription_current_period_end = nextBilling;
        user.subscription_expiry = nextBilling;
      }
      await user.save();
    }

    res.json({ received: true });
  } catch (err) {
    console.error('[payment] webhook:', err.message);
    res.status(500).json({ error: err.message });
  }
};

exports.createSubscriptionOrder = (req, res) => {
  req.body = { ...(req.body || {}), planId: 'standard' };
  return exports.createPlanOrder(req, res);
};
