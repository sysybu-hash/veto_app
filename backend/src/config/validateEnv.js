// ============================================================
//  validateEnv.js — Boot-time env presence checks (non-PayPal/Twilio)
// ============================================================

const logger = require('../lib/logger');

/**
 * Warn (or optionally fail) on missing critical env for in-scope production readiness.
 * Twilio / PayPal / Render plan / Admin OTP are intentionally out of scope here.
 *
 * @param {{ failHard?: boolean }} [opts]
 */
function validateEnv(opts = {}) {
  const isProd = process.env.NODE_ENV === 'production';
  const missing = [];
  const warnings = [];

  const requireInProd = (key, label = key) => {
    if (!process.env[key]?.trim()) {
      if (isProd) missing.push(label);
      else warnings.push(`${label} (optional in non-production)`);
    }
  };

  requireInProd('MONGO_URI', 'MONGO_URI');
  requireInProd('JWT_SECRET', 'JWT_SECRET');

  const cloudinaryReady =
    process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET;
  if (!cloudinaryReady) {
    const msg = 'CLOUDINARY_CLOUD_NAME / API_KEY / API_SECRET';
    if (isProd) warnings.push(`${msg} — vault remote delete will fail`);
    else warnings.push(msg);
  }

  if (!process.env.AGORA_APP_ID?.trim() || !process.env.AGORA_APP_CERTIFICATE?.trim()) {
    warnings.push('AGORA_APP_ID / AGORA_APP_CERTIFICATE — calls will not mint tokens');
  }

  if (
    isProd &&
    !process.env.CORS_ALLOWED_ORIGINS?.trim() &&
    !process.env.FRONTEND_URL?.trim() &&
    !process.env.WEB_APP_URL?.trim()
  ) {
    warnings.push(
      'CORS_ALLOWED_ORIGINS or FRONTEND_URL — production CORS allowlist is empty',
    );
  }

  // Deferred / operator-owned — never fail boot for these
  if (!process.env.TWILIO_ACCOUNT_SID) {
    warnings.push('TWILIO_* deferred — phone OTP SMS not configured');
  }
  if (!process.env.PAYPAL_CLIENT_ID) {
    warnings.push('PAYPAL_* — billing not configured (set PAYPAL_ENV=live + Live keys for production billing)');
  } else if (isProd && process.env.PAYPAL_ENV !== 'live') {
    warnings.push('PAYPAL_ENV is not live — sandbox credentials in production');
  }
  if (process.env.PAYPAL_CLIENT_ID && !process.env.PAYPAL_WEBHOOK_ID) {
    warnings.push('PAYPAL_WEBHOOK_ID missing — subscription webhooks will not sync');
  }
  if (
    process.env.PAYPAL_CLIENT_ID &&
    (!process.env.PAYPAL_STANDARD_PLAN_ID || !process.env.PAYPAL_FAMILY_PLAN_ID)
  ) {
    warnings.push('PAYPAL_STANDARD_PLAN_ID / PAYPAL_FAMILY_PLAN_ID — plan checkout incomplete');
  }

  const turnReady =
    (process.env.TURN_URL && process.env.TURN_USERNAME && process.env.TURN_CREDENTIAL) ||
    (process.env.WEBRTC_ICE_SERVERS_JSON && /turns?:/i.test(process.env.WEBRTC_ICE_SERVERS_JSON));
  if (!turnReady) {
    warnings.push('TURN_* / WEBRTC_ICE_SERVERS_JSON — only public STUN; NAT-heavy networks may fail calls');
  }

  for (const w of warnings) {
    logger.warn({ envCheck: w }, 'env validation warning');
  }

  if (missing.length) {
    const msg = `Missing required production env: ${missing.join(', ')}`;
    logger.error({ missing }, msg);
    if (opts.failHard !== false && isProd) {
      console.error(`❌ ${msg}`);
      process.exit(1);
    }
  }

  return { missing, warnings };
}

module.exports = { validateEnv };
