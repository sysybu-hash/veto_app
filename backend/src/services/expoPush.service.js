// ============================================================
//  expoPush.service.js — Expo Push API (mobile)
//  Tokens look like ExponentPushToken[xxxx]
// ============================================================

const logger = require('../lib/logger');

function isExpoPushToken(token) {
  return typeof token === 'string' && token.startsWith('ExponentPushToken[');
}

/**
 * @param {string} token
 * @param {{ title: string, body: string, data?: object }} payload
 */
async function sendExpoPush(token, { title, body, data = {} }) {
  if (!isExpoPushToken(token)) {
    return { sent: false, reason: 'not an Expo token' };
  }
  try {
    const res = await fetch('https://exp.host/--/api/v2/push/send', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        title,
        body,
        // Include flat fields so mobile tap handlers can deep-link without nesting.
        data: {
          ...data,
          url:
            typeof data.url === 'string'
              ? data.url
              : data.eventId
                ? `/(lawyer)/dashboard?eventId=${encodeURIComponent(String(data.eventId))}`
                : '/(lawyer)/dashboard',
        },
        sound: 'default',
        priority: 'high',
      }),
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok) {
      logger.warn({ status: res.status, json }, '[EXPO_PUSH] send failed');
      return { sent: false, reason: 'http error' };
    }
    return { sent: true, result: json };
  } catch (err) {
    logger.error({ err }, '[EXPO_PUSH] send error');
    return { sent: false, reason: err.message };
  }
}

module.exports = { isExpoPushToken, sendExpoPush };
