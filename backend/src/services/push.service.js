// ============================================================
//  push.service.js — Web Push Notification Service
//  VETO Legal Emergency App
//
//  Required env vars:
//    VAPID_PUBLIC_KEY
//    VAPID_PRIVATE_KEY
//    VAPID_SUBJECT  (mailto:admin@veto-legal.com)
//
//  Usage:
//    const push = require('./push.service');
//    await push.sendToLawyer(lawyerDoc, { title, body, data });
// ============================================================

const webpush = require('web-push');
const logger = require('../lib/logger');

let _configured = false;

function configure() {
  if (_configured) return true;
  const pub  = process.env.VAPID_PUBLIC_KEY;
  const priv = process.env.VAPID_PRIVATE_KEY;
  const subj = process.env.VAPID_SUBJECT || 'mailto:admin@veto-legal.com';
  if (!pub || !priv) return false;
  webpush.setVapidDetails(subj, pub, priv);
  _configured = true;
  return true;
}

/**
 * Deep-link so tapping a SOS notification opens the lawyer dashboard on that event
 * (calls tab), not a blank overview.
 * @param {Record<string, unknown>} data
 */
function lawyerSosDeepLink(data = {}) {
  if (typeof data.url === 'string' && data.url.trim()) return data.url.trim();
  const params = new URLSearchParams({ tab: 'calls' });
  if (data.eventId) params.set('eventId', String(data.eventId));
  if (data.userId != null) params.set('userId', String(data.userId));
  if (data.userName) params.set('userName', String(data.userName));
  if (data.language) params.set('language', String(data.language));
  if (data.timestamp) params.set('ts', String(data.timestamp));
  const loc = data.location;
  if (loc && typeof loc === 'object') {
    const lat = Number(loc.lat);
    const lng = Number(loc.lng);
    if (Number.isFinite(lat)) params.set('lat', String(lat));
    if (Number.isFinite(lng)) params.set('lng', String(lng));
  }
  return `/dashboard?${params.toString()}`;
}

/**
 * Send a push notification to a single lawyer.
 * @param {Object} lawyer - Mongoose Lawyer document (must have push_subscription field)
 * @param {{ title: string, body: string, data?: object }} payload
 */
async function sendToLawyer(lawyer, { title, body, data = {} }) {
  if (!configure())       return { sent: false, reason: 'VAPID not configured' };
  if (!lawyer.push_subscription) return { sent: false, reason: 'no subscription' };

  const url = lawyerSosDeepLink(data);

  try {
    await webpush.sendNotification(
      lawyer.push_subscription,
      JSON.stringify({ title, body, url, ...data, data }),
    );
    return { sent: true };
  } catch (err) {
    if (err.statusCode === 410 || err.statusCode === 404) {
      // Subscription expired — clear it
      const Lawyer = require('../models/Lawyer');
      await Lawyer.findByIdAndUpdate(lawyer._id, { $unset: { push_subscription: 1 } });
    }
    logger.error({ err, lawyerId: lawyer._id }, '[PUSH] Failed for lawyer');
    return { sent: false, reason: err.message };
  }
}

/**
 * Send push to all lawyers in an array.
 * Silently ignores lawyers without subscriptions.
 */
async function sendToMany(lawyers, payload) {
  if (!configure()) return;
  return Promise.allSettled(
    lawyers
      .filter(l => l.push_subscription)
      .map(l => sendToLawyer(l, payload)),
  );
}

/**
 * @param {Object} user - Mongoose User document (select +push_subscription)
 */
async function sendToUser(user, { title, body, data = {} }) {
  if (!configure()) return { sent: false, reason: 'VAPID not configured' };
  if (!user || !user.push_subscription) return { sent: false, reason: 'no subscription' };
  const User = require('../models/User');
  const url =
    typeof data.url === 'string' && data.url.trim()
      ? data.url.trim()
      : '/hub';
  try {
    await webpush.sendNotification(
      user.push_subscription,
      JSON.stringify({ title, body, url, ...data, data }),
    );
    return { sent: true };
  } catch (err) {
    if (err.statusCode === 410 || err.statusCode === 404) {
      await User.findByIdAndUpdate(user._id, { $unset: { push_subscription: 1 } });
    }
    logger.error({ err, userId: user._id }, '[PUSH] Failed for user');
    return { sent: false, reason: err.message };
  }
}

module.exports = {
  sendToLawyer,
  sendToMany,
  sendToUser,
  lawyerSosDeepLink,
  VAPID_PUBLIC_KEY: () => process.env.VAPID_PUBLIC_KEY,
};
