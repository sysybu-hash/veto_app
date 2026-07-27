// ============================================================
//  billing.controller.js — PayPal Orders (Mission 12) + User upgrade
//  Uses paypal.service (PAYPAL_CLIENT_ID / PAYPAL_CLIENT_SECRET / PAYPAL_ENV)
// ============================================================

const mongoose = require('mongoose');
const logger = require('../lib/logger');
const User = require('../models/User');
const { createJsSdkOrder, captureOrder } = require('../services/paypal.service');

const PREMIUM_DAYS = Math.max(
  1,
  Math.min(3650, Number(process.env.BILLING_PREMIUM_DAYS) || 30),
);

function jwtUserId(req) {
  const id = req.user?.userId ?? req.user?.id;
  return id != null ? String(id).trim() : '';
}

exports.createOrder = async (req, res) => {
  try {
    const { amount } = req.body || {};
    if (amount == null || amount === '') {
      return res.status(400).json({ error: 'amount is required.' });
    }
    const n = Number(amount);
    if (!Number.isFinite(n) || n <= 0) {
      return res.status(400).json({ error: 'Invalid amount.' });
    }
    const value = n.toFixed(2);
    const data = await createJsSdkOrder(value, 'ILS');
    return res.status(200).json(data);
  } catch (error) {
    if (error.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ error: 'PayPal is not configured on this server.' });
    }
    logger.error({ err: error }, 'Failed to create order');
    return res.status(500).json({ error: 'Failed to create order.' });
  }
};

exports.captureOrder = async (req, res) => {
  try {
    const userId = jwtUserId(req);
    if (!userId || !mongoose.isValidObjectId(userId)) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    const { orderID } = req.body || {};
    if (!orderID || typeof orderID !== 'string') {
      return res.status(400).json({ error: 'orderID is required.' });
    }

    const result = await captureOrder(orderID.trim());

    if (result.success) {
      const expiry = new Date();
      expiry.setDate(expiry.getDate() + PREMIUM_DAYS);
      await User.findByIdAndUpdate(userId, {
        is_subscribed: true,
        subscription_plan: 'standard',
        subscription_expiry: expiry,
      });
    }

    return res.status(200).json(result.raw);
  } catch (error) {
    if (error.code === 'PAYPAL_CONFIG_MISSING') {
      return res.status(503).json({ error: 'PayPal is not configured on this server.' });
    }
    logger.error({ err: error }, 'Failed to capture order');
    return res.status(500).json({ error: 'Failed to capture order.' });
  }
};
