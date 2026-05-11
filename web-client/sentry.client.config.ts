import * as Sentry from "@sentry/nextjs";

/** Browser bundle — רק NEXT_PUBLIC_* זמין בצד לקוח */
const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN?.trim();

Sentry.init({
  dsn: dsn || undefined,
  enabled: Boolean(dsn),
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.15 : 1,
});
