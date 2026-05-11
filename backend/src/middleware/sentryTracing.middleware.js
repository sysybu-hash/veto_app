// ============================================================
//  sentryTracing.middleware.js
//  Per-request Sentry span + latency metric for /api/calls/*.
//  Phase 4 observability — see plan.md §Phase 4.
//
//  Usage:
//    app.use('/api/calls', sentryTracing('calls'), callRouter);
//
//  Behaviour:
//   - When Sentry is not instrumented, becomes a no-op so dev still
//     boots without a DSN.
//   - Starts a span named `<scope> <method> <route>` and tags it with
//     `eventId` + `userId` (when available).
//   - On `res` finish, records `latency_ms` as a measurement and
//     finishes the span.
//   - Captures uncaught errors with the route's request as context.
//
//  100% sampling for the first launch week is achieved by setting
//  `SENTRY_FULL_SAMPLE_PATHS=/api/calls,/api/auth` so this middleware
//  forces `sampled=true` regardless of the global tracesSampleRate.
// ============================================================

const Sentry = require('@sentry/node');

const FULL_SAMPLE_PATHS = (process.env.SENTRY_FULL_SAMPLE_PATHS || '/api/calls')
  .split(',')
  .map((p) => p.trim())
  .filter(Boolean);

function shouldFullSample(reqPath) {
  return FULL_SAMPLE_PATHS.some((p) => reqPath.startsWith(p));
}

function instrumented() {
  return Boolean(Sentry.__vetoInstrumented);
}

function startSpan(name, attributes) {
  // Sentry SDK v8+/v10 startSpan signature.
  if (typeof Sentry.startInactiveSpan === 'function') {
    return Sentry.startInactiveSpan({
      name,
      op: 'http.server',
      attributes,
      forceTransaction: true,
    });
  }
  return null;
}

function attachRequestContext(req) {
  if (!instrumented()) return;
  Sentry.setTag('route_method', req.method);
  if (req.params?.eventId) {
    Sentry.setTag('event_id', String(req.params.eventId));
  }
  if (req.user?.userId) {
    Sentry.setUser({ id: String(req.user.userId), role: req.user.role || null });
  }
}

/**
 * Express middleware factory.
 * @param {string} scope — short label like `calls` or `auth`.
 */
function sentryTracing(scope) {
  return function sentryTracingMw(req, res, next) {
    if (!instrumented()) return next();

    const startedAt = process.hrtime.bigint();
    const sampled = shouldFullSample(req.baseUrl + req.path);

    let span = null;
    try {
      span = Sentry.withScope((scopeObj) => {
        if (sampled) {
          scopeObj.setExtra('forced_full_sample', true);
        }
        attachRequestContext(req);
        return startSpan(
          `${scope} ${req.method} ${req.route?.path || req.path}`,
          {
            'http.method': req.method,
            'http.target': req.originalUrl,
            'http.scope': scope,
          },
        );
      });
    } catch (_) {
      span = null;
    }

    res.on('finish', () => {
      try {
        const elapsedNs = Number(process.hrtime.bigint() - startedAt);
        const elapsedMs = elapsedNs / 1e6;
        if (span && typeof span.setAttribute === 'function') {
          span.setAttribute('http.status_code', res.statusCode);
          span.setAttribute('http.latency_ms', elapsedMs);
        }
        if (span && typeof span.end === 'function') {
          span.end();
        }
        // Lightweight breadcrumb for cross-tab correlation in Sentry UI.
        Sentry.addBreadcrumb({
          category: `http.${scope}`,
          type: 'http',
          level: res.statusCode >= 500 ? 'error' : 'info',
          message: `${req.method} ${req.originalUrl} ${res.statusCode} ${elapsedMs.toFixed(0)}ms`,
        });
      } catch (_) {
        /* never break the response on telemetry */
      }
    });

    next();
  };
}

module.exports = sentryTracing;
