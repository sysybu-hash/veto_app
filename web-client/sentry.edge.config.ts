import * as Sentry from "@sentry/nextjs";

const dsn = process.env.SENTRY_DSN?.trim();

Sentry.init({
  dsn: dsn || undefined,
  enabled: Boolean(dsn),
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.15 : 1,
});
