// ============================================================
//  instrument.js — Sentry Early Initialization
//  MUST be require()'d as the very first line of server.js
//  DSN is read from SENTRY_DSN environment variable.
// ============================================================
const Sentry = require('@sentry/node');

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: 0.2,
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
}

module.exports = Sentry;
