// ============================================================
//  fcm.service.js — Firebase Cloud Messaging (Server)
//  Env: FIREBASE_SERVICE_ACCOUNT — JSON string of the service account
// ============================================================

let _inited;
function getAdmin() {
  if (_inited !== undefined) return _inited;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw || !String(raw).trim().startsWith('{')) {
    _inited = null;
    return _inited;
  }
  const admin = require('firebase-admin');
  try {
    const creds = JSON.parse(String(raw));
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(creds) });
    }
    _inited = admin;
  } catch (e) {
    console.error('[FCM] Init failed:', e.message);
    _inited = null;
  }
  return _inited;
}

function isConfigured() {
  return getAdmin() != null;
}

/**
 * @param {string} token
 * @param {{ title: string, body: string, data?: object }} payload
 */
async function sendToFcmToken(token, { title, body, data = {} }) {
  const admin = getAdmin();
  if (!admin || !token) return { sent: false, reason: 'not configured' };
  try {
    const dataPayload = Object.fromEntries(
      Object.entries({ title, body, ...data }).map(([k, v]) => [String(k), String(v == null ? '' : v)]),
    );
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: dataPayload,
      apns: { payload: { aps: { sound: 'default' } } },
      android: { priority: 'high' },
    });
    return { sent: true };
  } catch (e) {
    const code = e?.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      return { sent: false, reason: 'invalid token', shouldClear: true };
    }
    return { sent: false, reason: e?.message || String(e) };
  }
}

module.exports = { getAdmin, isConfigured, sendToFcmToken };
