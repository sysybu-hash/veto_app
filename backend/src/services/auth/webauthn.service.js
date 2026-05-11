// ============================================================
//  webauthn.service.js
//  Centralises WebAuthn (passkey) RP configuration so all four
//  passkey controller actions read from the same source.
//
//  Env (production):
//    WEB_APP_URL / FRONTEND_URL — must match the site users sign in from
//      (used for expectedOrigin in verification).
//    WEBAUTHN_RP_ID — registrable domain for passkeys (e.g. veto.example.com);
//      defaults to hostname of WEB_APP_URL. Must match the site's host.
//    WEBAUTHN_RP_NAME — human-readable RP name (default: "VETO Legal").
// ============================================================

/**
 * Builds the rpName / rpID / origin tuple for `@simplewebauthn/server`.
 * Falls back to the request host when the WEB_APP_URL env is unset
 * (handy for local development behind a tunnel).
 *
 * @param {import('express').Request} req
 */
function webauthnConfig(req) {
  const appUrl =
    process.env.WEB_APP_URL ||
    process.env.FRONTEND_URL ||
    `${req.protocol}://${req.get('host')}`;
  let origin;
  try {
    origin = new URL(appUrl).origin;
  } catch {
    origin = `${req.protocol}://${req.get('host')}`;
  }
  const rpID =
    process.env.WEBAUTHN_RP_ID?.trim() || new URL(origin).hostname;
  return {
    rpName: process.env.WEBAUTHN_RP_NAME || 'VETO Legal',
    rpID,
    origin,
  };
}

module.exports = { webauthnConfig };
