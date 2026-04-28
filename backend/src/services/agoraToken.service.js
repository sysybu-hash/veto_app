// ============================================================
//  Agora RTC token — must match Flutter [kAgoraAppIdPlaceholder]
//  if using token auth. See Render env: AGORA_APP_ID, AGORA_APP_CERTIFICATE
// ============================================================

const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

/**
 * Stable 32-bit uid in 1..(2^32-2) for Agora (non-zero when using token auth).
 * @param {import('mongoose').Types.ObjectId|string} mongoId
 * @returns {number}
 */
function mongoIdToAgoraUid(mongoId) {
  const id = String(mongoId);
  const m = id.match(/[0-9a-f]{24}/i);
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

/**
 * @param {string} channelName — same as [roomId] / event id used in Flutter joinChannel
 * @param {import('mongoose').Types.ObjectId|string} userMongoId
 * @returns {{ token: string, agoraUid: number }}
 */
function buildRtcTokenForUid(channelName, userMongoId) {
  const appId = process.env.AGORA_APP_ID;
  const cert  = process.env.AGORA_APP_CERTIFICATE;
  const agoraUid = mongoIdToAgoraUid(userMongoId);

  if (!appId || !cert) {
    return { token: '', agoraUid: 0 };
  }

  const expire = Math.floor(Date.now() / 1000) + 24 * 60 * 60;
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    cert,
    String(channelName),
    agoraUid,
    RtcRole.PUBLISHER,
    expire,
  );
  return { token, agoraUid };
}

module.exports = {
  mongoIdToAgoraUid,
  buildRtcTokenForUid,
};
