// ============================================================
//  agoraToken.service.js — VETO 2026 (agora-token)
//
//  Generates short-lived Agora RTC tokens for the Flutter app.
//  Requires env:
//    AGORA_APP_ID, AGORA_APP_CERTIFICATE  (Render → Environment)
//
//  Dev mode (missing cert) → returns empty token/uid=0. The Flutter
//  engine treats empty token as "no-auth mode" and joins with uid 0,
//  which ONLY works on Agora projects configured without a certificate.
// ============================================================

const { RtcTokenBuilder, RtcRole } = require('agora-token');

const APP_ID          = process.env.AGORA_APP_ID || '';
const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';
/** Token lifetime — long enough to cover a legal consult, short enough to
 *  force a renewal if someone leaves a tab open overnight. */
const DEFAULT_TTL_SEC = 60 * 60; // 1h

/**
 * Stable 32-bit uid in [1, 2^32-2] for Agora (must be non-zero when using
 * token auth). Derived deterministically from a MongoDB ObjectId so both
 * client and server agree without round-trips.
 * @param {import('mongoose').Types.ObjectId|string} mongoId
 * @returns {number}
 */
function mongoIdToAgoraUid(mongoId) {
  const id = String(mongoId || '');
  const m  = id.match(/[0-9a-f]{24}/i);
  if (m) {
    const n = parseInt(m[0].slice(0, 8), 16) >>> 0;
    return n === 0 ? 1 : n;
  }
  let h = 2166136261 >>> 0;
  for (let i = 0; i < id.length; i++) {
    h ^= id.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  const u = h % 4294967290;
  return u === 0 ? 1 : u;
}

function normalizeRole(role) {
  return role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;
}

/**
 * Build an Agora RTC token.
 *
 * Two call styles (back-compat):
 *   1) buildRtcTokenForUid(channelName, mongoUserId)
 *   2) buildRtcTokenForUid({ channelName, uid | userMongoId, role, ttlSec })
 *
 * @returns {{ token: string, agoraUid: number, channelName: string, ttlSec: number, expiresAt: number }}
 */
function buildRtcTokenForUid(arg1, arg2) {
  let channelName;
  let uid;
  let role = RtcRole.PUBLISHER;
  let ttlSec = DEFAULT_TTL_SEC;

  if (arg1 && typeof arg1 === 'object') {
    channelName = String(arg1.channelName || '');
    uid = Number.isFinite(Number(arg1.uid))
      ? Math.trunc(Number(arg1.uid))
      : mongoIdToAgoraUid(arg1.userMongoId);
    role = normalizeRole(arg1.role);
    if (Number.isFinite(Number(arg1.ttlSec))) {
      ttlSec = Math.max(60, Math.min(24 * 60 * 60, Math.trunc(Number(arg1.ttlSec))));
    }
  } else {
    channelName = String(arg1 || '');
    uid = mongoIdToAgoraUid(arg2);
  }

  if (!channelName) {
    return { token: '', agoraUid: 0, channelName: '', ttlSec: 0, expiresAt: 0 };
  }
  if (!APP_ID || !APP_CERTIFICATE) {
    // Dev / unconfigured environment — join with uid 0 and no token.
    return { token: '', agoraUid: 0, channelName, ttlSec: 0, expiresAt: 0 };
  }

  const now = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = now + ttlSec;
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    uid,
    role,
    privilegeExpiredTs,
    privilegeExpiredTs,
  );

  return {
    token,
    agoraUid: uid,
    channelName,
    ttlSec,
    expiresAt: privilegeExpiredTs * 1000,
  };
}

module.exports = {
  mongoIdToAgoraUid,
  buildRtcTokenForUid,
};
