import * as Sentry from "@sentry/nextjs";

const dsnRaw = process.env.SENTRY_DSN?.trim();
// See sentry.client.config.ts — a malformed DSN must not crash Sentry.init().
const dsn = dsnRaw && /^https?:\/\/[^:@/]+@[^/]+\/\d+$/.test(dsnRaw) ? dsnRaw : undefined;
if (dsnRaw && !dsn) {
  console.warn("[sentry] SENTRY_DSN is malformed — Sentry disabled.");
}

Sentry.init({
  dsn,
  enabled: Boolean(dsn),
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.15 : 1,
});
