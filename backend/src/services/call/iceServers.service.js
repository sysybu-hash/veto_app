// ============================================================
//  iceServers.service.js
//  Reads ICE/TURN credentials out of env so the call.controller
//  stays focused on HTTP wiring. Secrets never ship to the
//  Flutter or Web bundles — they're served via /api/calls/ice-config.
// ============================================================

/**
 * Returns the configured extra ICE servers, in WebRTC RTCConfiguration shape:
 *   [{ urls, username?, credential? }, ...]
 *
 * Priority:
 *   1) WEBRTC_ICE_SERVERS_JSON — JSON array of full entries.
 *   2) TURN_URL + TURN_USERNAME + TURN_CREDENTIAL — a single TURN entry.
 *
 * @returns {Array<Object>}
 */
const DEFAULT_STUN = { urls: 'stun:stun.l.google.com:19302' };

function hasTurnEntry(servers) {
  return servers.some((s) => {
    const u = s?.urls;
    const list = Array.isArray(u) ? u : [u];
    return list.some((x) => typeof x === 'string' && /^turns?:/i.test(x));
  });
}

/**
 * Returns ICE servers for WebRTC.
 * Priority: WEBRTC_ICE_SERVERS_JSON → TURN_* → public STUN fallback.
 * Production should still set TURN_* for NAT reliability (STUN alone is not enough).
 */
function iceServersFromEnv() {
  const raw = process.env.WEBRTC_ICE_SERVERS_JSON;
  if (raw && String(raw).trim()) {
    try {
      const parsed = JSON.parse(String(raw).trim());
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    } catch (_) {
      /* fall through */
    }
  }
  const url = process.env.TURN_URL;
  const user = process.env.TURN_USERNAME;
  const pass = process.env.TURN_CREDENTIAL;
  if (url && user && pass) {
    return [DEFAULT_STUN, { urls: url, username: user, credential: pass }];
  }
  return [DEFAULT_STUN];
}

function turnConfigured() {
  return hasTurnEntry(iceServersFromEnv()) || Boolean(
    process.env.TURN_URL && process.env.TURN_USERNAME && process.env.TURN_CREDENTIAL,
  );
}

module.exports = { iceServersFromEnv, turnConfigured, DEFAULT_STUN };
