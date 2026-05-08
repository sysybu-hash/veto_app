// ============================================================
//  payment.controller.js
//  VETO Legal Emergency App
//  Routes:
//    POST /api/payments/subscription  — create ₪19.90 order ($5.50)
//    POST /api/payments/consultation  — create ₪50 order ($13.90)
//    POST /api/payments/capture       — capture approved order
// ============================================================

const { createOrder, captureOrder } = require('../services/paypal.service');
const User = require('../models/User');

/** Public web app origin (no trailing slash) — PayPal return/cancel URLs */
const WEB_APP_URL = (
  process.env.WEB_APP_URL ||
  process.env.FRONTEND_URL ||
  'http://localhost:3000'
).replace(/\/$/, '');

// ── POST /api/payments/subscription ─────────────────────────
exports.createSubscriptionOrder = async (req, res) => {
  try {
    const { orderId, approveUrl } = await createOrder(
      '5.50',
      'USD',
      'VETO Legal — מנוי חודשי ₪19.90',
      `${WEB_APP_URL}/payments/return?type=subscription`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=subscription`,
    );
    res.json({ orderId, approveUrl });
  } catch (err) {
    console.error('[payment] subscription create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/consultation ─────────────────────────
exports.createConsultationOrder = async (req, res) => {
  try {
    const { orderId, approveUrl } = await createOrder(
      '13.90',
      'USD',
      'VETO Legal — ייעוץ עורך דין 15 דקות ₪50',
      `${WEB_APP_URL}/payments/return?type=consultation`,
      `${WEB_APP_URL}/payments/return?cancel=1&type=consultation`,
    );
    res.json({ orderId, approveUrl });
  } catch (err) {
    console.error('[payment] consultation create:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/capture ───────────────────────────────
// Body: { orderId: string, type: "subscription"|"consultation" }
// Requires JWT — userId is always taken from the token (never from body).
exports.capturePayment = async (req, res) => {
  const { orderId, type } = req.body;
  if (!orderId) return res.status(400).json({ error: 'orderId is required' });

  const role = req.user?.role;
  if (role !== 'user' && role !== 'admin') {
    return res.status(403).json({ error: 'Only citizen accounts can complete this payment.' });
  }
  const userId = req.user.userId;

  try {
    const result = await captureOrder(orderId);

    // If subscription was paid, mark user as subscribed for 31 days
    if (result.success && type === 'subscription' && userId) {
      const expiry = new Date();
      expiry.setDate(expiry.getDate() + 31);
      await User.findByIdAndUpdate(userId, {
        is_subscribed: true,
        subscription_expiry: expiry,
      });
    }

    res.json({
      success: result.success,
      captureId: result.captureId,
      status: result.status,
    });
  } catch (err) {
    console.error('[payment] capture:', err.message);
    if (err.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({
        success: false,
        message: err.message,
      });
    }
    res.status(500).json({ error: err.message });
  }
};
