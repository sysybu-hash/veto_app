// ============================================================
//  notificationDispatcher.js — Web (VAPID) + FCM in one call
// ============================================================

const User = require('../models/User');
const Lawyer = require('../models/Lawyer');
const webPush = require('./push.service');
const fcm = require('./fcm.service');

/**
 * @param {{ accountId: import('mongoose').Types.ObjectId, accountRole: 'user'|'admin'|'lawyer', title: string, body: string, data?: object }} p
 */
async function notifyAccount({ accountId, accountRole, title, body, data = {} }) {
  if (accountRole === 'lawyer') {
    const lawyer = await Lawyer.findById(accountId).select('+push_subscription fcm_token');
    if (!lawyer) return { vapid: { sent: false }, fcm: { sent: false } };
    const v = await webPush.sendToLawyer(
      { ...lawyer.toObject ? lawyer.toObject() : lawyer, push_subscription: lawyer.push_subscription },
      { title, body, data },
    );
    let f = { sent: false, reason: 'not configured' };
    if (lawyer.fcm_token) {
      f = await fcm.sendToFcmToken(lawyer.fcm_token, { title, body, data });
      if (f.shouldClear) {
        await Lawyer.findByIdAndUpdate(accountId, { fcm_token: null });
        f = { sent: f.sent, cleared: true };
      }
    }
    return { vapid: v, fcm: f };
  }
  const user = await User.findById(accountId).select('+push_subscription fcm_token');
  if (!user) return { vapid: { sent: false }, fcm: { sent: false } };
  const v = await webPush.sendToUser(user, { title, body, data });
  let f = { sent: false, reason: 'no fcm' };
  if (user.fcm_token) {
    f = await fcm.sendToFcmToken(user.fcm_token, { title, body, data });
    if (f.shouldClear) {
      await User.findByIdAndUpdate(accountId, { fcm_token: null });
    }
  }
  return { vapid: v, fcm: f };
}

module.exports = { notifyAccount };
