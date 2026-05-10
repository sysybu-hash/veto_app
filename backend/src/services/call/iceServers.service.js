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
function iceServersFromEnv() {
  const raw = process.env.WEBRTC_ICE_SERVERS_JSON;
  if (raw && String(raw).trim()) {
    try {
      const parsed = JSON.parse(String(raw).trim());
      if (Array.isArray(parsed)) return parsed;
    } catch (_) {
      /* fall through */
    }
  }
  const url = process.env.TURN_URL;
  const user = process.env.TURN_USERNAME;
  const pass = process.env.TURN_CREDENTIAL;
  if (url && user && pass) {
    return [{ urls: url, username: user, credential: pass }];
  }
  return [];
}

module.exports = { iceServersFromEnv };
