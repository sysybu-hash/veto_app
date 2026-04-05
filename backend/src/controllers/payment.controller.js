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

const FRONTEND_URL =
  process.env.FRONTEND_URL || 'https://frontend-nine-silk-72.vercel.app';

// ── POST /api/payments/subscription ─────────────────────────
exports.createSubscriptionOrder = async (req, res) => {
  try {
    const { orderId, approveUrl } = await createOrder(
      '5.50',
      'USD',
      'VETO Legal — מנוי חודשי ₪19.90',
      `${FRONTEND_URL}/?payment=success&type=subscription`,
      `${FRONTEND_URL}/?payment=cancel`,
    );
    res.json({ orderId, approveUrl });
  } catch (err) {
    console.error('[payment] subscription create:', err.message);
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
      `${FRONTEND_URL}/?payment=success&type=consultation`,
      `${FRONTEND_URL}/?payment=cancel`,
    );
    res.json({ orderId, approveUrl });
  } catch (err) {
    console.error('[payment] consultation create:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ── POST /api/payments/capture ───────────────────────────────
// Body: { orderId: string, type: "subscription"|"consultation", userId?: string }
exports.capturePayment = async (req, res) => {
  const { orderId, type, userId } = req.body;
  if (!orderId) return res.status(400).json({ error: 'orderId is required' });

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
    res.status(500).json({ error: err.message });
  }
};
