// ============================================================
//  instrument.js — Sentry Early Initialization
//  MUST be require()'d as the very first line of server.js
//  DSN is read from SENTRY_DSN environment variable.
// ============================================================
const Sentry = require('@sentry/node');

/** Sentry DSN must look like: https://<publicKey>@o<digits>.ingest.(de.)sentry.io/<projectId> */
function sentryDsnLooksValid(dsn) {
  if (!dsn || typeof dsn !== 'string') return false;
  const s = dsn.trim();
  if (!s.startsWith('https://')) return false;
  // Public key and ingest host are separated by a single '@'
  const at = s.indexOf('@');
  if (at <= 'https://'.length) return false;
  if (!/\.ingest\.(de\.)?sentry\.io\//i.test(s)) return false;
  return true;
}

if (process.env.SENTRY_DSN && sentryDsnLooksValid(process.env.SENTRY_DSN)) {
  // Sample rates can be tuned with SENTRY_TRACES_SAMPLE_RATE (default 0.2)
  // and SENTRY_ERROR_SAMPLE_RATE (default 1.0). The first launch week
  // ships with full error capture and 100% traces on the call paths via
  // sentryTracing.middleware.js (`forceTransaction: true`).
  const tracesSampleRate = Math.max(
    0,
    Math.min(1, Number(process.env.SENTRY_TRACES_SAMPLE_RATE ?? 0.2)),
  );
  const sampleRate = Math.max(
    0,
    Math.min(1, Number(process.env.SENTRY_ERROR_SAMPLE_RATE ?? 1.0)),
  );

  Sentry.init({
    dsn: process.env.SENTRY_DSN.trim(),
    environment: process.env.NODE_ENV || 'development',
    release: process.env.SENTRY_RELEASE || process.env.RENDER_GIT_COMMIT || undefined,
    tracesSampleRate,
    sampleRate,
    // Scrub sensitive fields from breadcrumbs/events
    beforeSend(event) {
      if (event.request && event.request.data) {
        const data = event.request.data;
        if (data.otp)      delete data.otp;
        if (data.password) delete data.password;
      }
      return event;
    },
  });
  Sentry.__vetoInstrumented = true;
} else if (process.env.SENTRY_DSN) {
  console.warn(
    '⚠️  SENTRY_DSN is set but ignored: invalid format (missing @ between key and host). ' +
      'Copy the full DSN from Sentry → Settings → Client Keys (DSN).',
  );
}

module.exports = Sentry;
