import * as Sentry from "@sentry/nextjs";

/** Browser bundle — רק NEXT_PUBLIC_* זמין בצד לקוח */
const dsnRaw = process.env.NEXT_PUBLIC_SENTRY_DSN?.trim();
// A malformed DSN (e.g. missing the required "@" between the public key and
// host) makes Sentry.init() throw synchronously during client bootstrap,
// which was observed to silently break unrelated client-side effects
// elsewhere on the page (found while debugging the /pricing PayPal button
// never mounting on a hard page load). Validate before init so a bad value
// just disables Sentry instead of taking down the app.
const dsn = dsnRaw && /^https?:\/\/[^:@/]+@[^/]+\/\d+$/.test(dsnRaw) ? dsnRaw : undefined;
if (dsnRaw && !dsn) {
  console.warn("[sentry] NEXT_PUBLIC_SENTRY_DSN is malformed — Sentry disabled.");
}

Sentry.init({
  dsn,
  enabled: Boolean(dsn),
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.15 : 1,
});
