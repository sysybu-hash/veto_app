// ============================================================
//  server.js — Entry Point
//  VETO Legal Emergency App — dotenv, MongoDB, CORS, Socket.io
// ============================================================

// !! Sentry MUST be first — before any other require !!
const Sentry = require('./instrument');

const path = require('path');
const fs = require('fs');

(function loadEnv() {
  const candidates = [
    path.join(__dirname, '.env'),
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), 'backend', '.env'),
  ];
  for (const envPath of candidates) {
    if (fs.existsSync(envPath)) {
      require('dotenv').config({ path: envPath });
      if (process.env.NODE_ENV !== 'production') {
        console.log(`📄 .env loaded: ${envPath}`);
      }
      const local = path.join(path.dirname(envPath), '.env.local');
      if (fs.existsSync(local)) {
        require('dotenv').config({ path: local, override: true });
        if (process.env.NODE_ENV !== 'production') {
          console.log(`📄 .env.local loaded (overrides): ${local}`);
        }
      }
      return;
    }
  }
  require('dotenv').config();
  // Render / Fly / etc. inject secrets via the platform — no repo .env file (and that is OK).
  if (process.env.RENDER === 'true' || process.env.NODE_ENV === 'production') {
    console.log(
      '📋 No local .env file — using process.env (e.g. Render Environment / hosting dashboard).',
    );
  } else {
    console.warn('⚠️  No .env file found. Tried:', candidates.join(' | '));
  }
})();

// Prefer IPv4 DNS — helps some Windows setups when Atlas SRV lookup fails
try {
  require('dns').setDefaultResultOrder('ipv4first');
} catch {
  /* older Node */
}

const express = require('express');
const cors    = require('cors');
const http    = require('http');
const helmet  = require('helmet');
const pinoHttp = require('pino-http');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const logger = require('./src/lib/logger');
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const { initRedis } = require('./src/config/redis');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const connectDB  = require('./src/config/db');
const app = express();
const server = http.createServer(app);

/**
 * CORS with credentials — required for cross-origin browser calls from Vercel → Render.
 * - Always allows common local dev + production Vercel app URL.
 * - Merges CORS_ALLOWED_ORIGINS, FRONTEND_URL / WEB_APP_URL (no trailing slash).
 * - The broad *.vercel.app wildcard is OFF by default. Any attacker-owned Vercel project
 *   is also under *.vercel.app, so trusting it with credentials:true is a real risk.
 *   Opt in explicitly with ALLOW_VERCEL_PREVIEW_ORIGINS=1 (e.g. for a staging environment)
 *   — production should rely on an explicit CORS_ALLOWED_ORIGINS list instead.
 */
function buildCorsOrigin() {
  const trimOrigin = (s) => s.trim().replace(/\/$/, '');
  const defaults = [
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'https://web-nine-gamma-76.vercel.app',
  ];
  const fromWeb = trimOrigin(
    process.env.FRONTEND_URL || process.env.WEB_APP_URL || '',
  );
  const fromEnv = (process.env.CORS_ALLOWED_ORIGINS || '')
    .split(',')
    .map((s) => trimOrigin(s))
    .filter(Boolean);

  const allowed = new Set(
    [...defaults, ...fromEnv, fromWeb].filter(Boolean),
  );

  const allowVercelPreviewWildcard = process.env.ALLOW_VERCEL_PREVIEW_ORIGINS === '1';

  if (process.env.NODE_ENV === 'production' && !allowVercelPreviewWildcard && fromEnv.length === 0 && !fromWeb) {
    console.warn(
      '⚠️  CORS: no CORS_ALLOWED_ORIGINS/FRONTEND_URL set in production — only the hardcoded defaults will be allowed.',
    );
  }

  return (origin, callback) => {
    if (!origin) {
      callback(null, true);
      return;
    }
    if (allowed.has(origin)) {
      callback(null, true);
      return;
    }
    if (allowVercelPreviewWildcard) {
      try {
        const u = new URL(origin);
        if (u.hostname.endsWith('.vercel.app')) {
          callback(null, true);
          return;
        }
      } catch {
        /* ignore */
      }
    }
    callback(new Error(`CORS: origin not allowed: ${origin}`));
  };
}

const corsOrigin = buildCorsOrigin();

// Render / other reverse proxies send X-Forwarded-For. express-rate-limit v7 validates this
// and throws ERR_ERL_UNEXPECTED_X_FORWARDED_FOR unless trust proxy is enabled.
if (process.env.RENDER === 'true' || process.env.NODE_ENV === 'production') {
  app.set('trust proxy', 1);
}

app.use(
  cors({
    origin: corsOrigin,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'bypass-tunnel-reminder',
      'X-Requested-With',
      'Cookie',
    ],
  }),
);

// ── Structured request logging (JSON in prod) ──────────────────
app.use(
  pinoHttp({
    logger,
    // /health is polled every ~14min by the keepalive workflow (and by Render itself) —
    // logging every hit would just be noise, not signal.
    autoLogging: { ignore: (req) => req.url === '/health' },
  }),
);

// ── Security headers (European/banking standard) ──────────────
app.use(helmet({
  contentSecurityPolicy: false,  // Flutter web needs inline scripts
  crossOriginOpenerPolicy: false, // handled by Vercel headers
  // Allow cross-origin fetch / Socket.io from Vercel and other web origins (default same-site can block usefully).
  crossOriginResourcePolicy: false,
}));

// ── Rate limiting on auth routes ──────────────────────────────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,                    // max 20 auth attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP. Please wait 15 minutes.' },
});

// ── Global API Rate limiting ──────────────────────────────────
// Dev / local: one IP hits the API from Next.js, HMR, and parallel tabs — keep headroom.
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: process.env.NODE_ENV === 'production' ? 150 : 500,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
  // CORS preflight (OPTIONS) must not burn the budget or return a response without CORS headers.
  skip: (req) => req.method === 'OPTIONS',
});

app.use(express.json());

// ── Data Sanitization against NoSQL Injection ─────────────────
app.use(mongoSanitize());

// ── Production safety: refuse to boot only for the dangerous combo ──
// RETURN_OTP_IN_JSON puts OTP in API JSON (needed on hosts without Twilio).
// If Twilio SMS is also configured, returning OTP in JSON is redundant and risky;
// require ALLOW_OTP_IN_JSON_PRODUCTION=1 in that case. Without Twilio, we only warn.
(function guardOtpInProduction() {
  const isProd = process.env.NODE_ENV === 'production';
  const otpInJson =
    process.env.RETURN_OTP_IN_JSON === '1' ||
    process.env.RETURN_OTP_IN_JSON === 'true';
  const ack = process.env.ALLOW_OTP_IN_JSON_PRODUCTION === '1';
  const twilioSms =
    Boolean(process.env.TWILIO_ACCOUNT_SID) && Boolean(process.env.TWILIO_AUTH_TOKEN);

  if (isProd && otpInJson && twilioSms && !ack) {
    console.error(
      '❌ Refusing to boot: RETURN_OTP_IN_JSON is on in production while Twilio SMS is configured. ' +
      'Remove RETURN_OTP_IN_JSON (recommended) or set ALLOW_OTP_IN_JSON_PRODUCTION=1 if you ' +
      'really need OTP in JSON alongside SMS.',
    );
    process.exit(1);
  }

  if (isProd && otpInJson && !twilioSms) {
    console.warn(
      '[BOOT] RETURN_OTP_IN_JSON is on without Twilio — OTP is returned in JSON (typical for Render until SMS is wired). ' +
      'Configure Twilio and unset RETURN_OTP_IN_JSON for public production.',
    );
  }
})();

// ── Production safety: PayPal webhook must be verifiable if billing is enabled ──
// Without PAYPAL_WEBHOOK_ID, /api/payment/webhook/paypal cannot verify signatures and
// paypal.service.js now throws on every webhook call — refuse to boot instead of
// silently running with an unverifiable billing webhook.
(function guardPaypalWebhookInProduction() {
  const isProd = process.env.NODE_ENV === 'production';
  const paypalConfigured =
    Boolean(process.env.PAYPAL_CLIENT_ID) && Boolean(process.env.PAYPAL_CLIENT_SECRET);
  const webhookIdSet = Boolean(process.env.PAYPAL_WEBHOOK_ID);

  if (isProd && paypalConfigured && !webhookIdSet) {
    console.error(
      '❌ Refusing to boot: PayPal is configured (PAYPAL_CLIENT_ID/SECRET set) but PAYPAL_WEBHOOK_ID ' +
      'is missing. Without it, incoming PayPal webhooks cannot be verified and billing state could be ' +
      'forged. Set PAYPAL_WEBHOOK_ID from the PayPal Developer Dashboard → Webhooks.',
    );
    process.exit(1);
  }
})();

app.use('/api/', apiLimiter);

// Browser / tools often open exactly http://localhost:5001/api — give JSON, not 404.
const apiDiscovery = (_, res) =>
  res.json({
    ok: true,
    app: 'VETO API',
    hint: 'Sub-routes are under /api/* (auth, users, vault, …). This URL is only for discovery.',
    get: {
      health: '/health',
      apiRoot: '/api',
      pushVapidKey: '/api/push/vapid-key',
      legalCalendar: '/api/calendar/events?year=YYYY&month=MM (JWT)',
      icalExport: '/api/calendar/export.ics?token= (public)',
    },
    postExamples: {
      requestOtp: '/api/auth/request-otp',
      verifyOtp: '/api/auth/verify-otp',
    },
  });
app.get('/api', apiDiscovery);
app.get('/api/', apiDiscovery);

// ── Static uploads folder (evidence files) ─────────────────
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const io = new Server(server, {
  cors: {
    origin: corsOrigin,
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
app.set('io', io);

// Setup Redis Adapter for multi-instance Socket.io (optional when REDIS_URL is set)
initRedis().then((redisClients) => {
  if (redisClients) {
    io.adapter(createAdapter(redisClients.pubClient, redisClients.subClient));
  }
});

// Global Socket.io handshake rate limit (per connecting IP)
const socketHandshakeRateLimiter = new RateLimiterMemory({
  points: 20,
  duration: 1,
});

io.use(async (socket, next) => {
  try {
    await socketHandshakeRateLimiter.consume(socket.handshake.address);
    next();
  } catch {
    next(new Error('Rate limit exceeded. Disconnecting.'));
  }
});

/**
 * Defensive route mounter.
 * If a single route file blows up at require()-time (syntax error, bad import,
 * missing optional dep), we don't want the entire API to fail booting.
 * - In dev: log loud and continue, mount a stub returning 503 on that prefix.
 * - In prod: same, plus Sentry capture so we see it in the alert pipe.
 */
function mountRoute(prefix, requirePath, ...preMiddleware) {
  try {
    const routerModule = require(requirePath);
    if (preMiddleware.length > 0) {
      app.use(prefix, ...preMiddleware, routerModule);
    } else {
      app.use(prefix, routerModule);
    }
  } catch (err) {
    console.error(`❌ Failed to mount ${prefix} from ${requirePath}:`, err.message);
    if (Sentry.__vetoInstrumented && typeof Sentry.captureException === 'function') {
      try { Sentry.captureException(err); } catch (_) { /* best effort */ }
    }
    app.use(prefix, (_req, res) =>
      res.status(503).json({
        error: 'Subsystem temporarily unavailable.',
        prefix,
      }),
    );
  }
}

mountRoute('/health', './src/routes/health.routes');

mountRoute('/api/auth', './src/routes/auth.routes', authLimiter);
mountRoute('/api/users', './src/routes/user.routes');
mountRoute('/api/lawyers', './src/routes/lawyer.routes');
mountRoute('/api/notifications', './src/routes/notifications.routes');

// ── Public VAPID key for browser push subscription ────────────
app.get('/api/push/vapid-key', (_, res) => {
  const key = process.env.VAPID_PUBLIC_KEY;
  if (!key) return res.status(503).json({ error: 'Push notifications not configured.' });
  res.json({ publicKey: key });
});
try {
  const { exportIcs: calendarExportIcs } = require('./src/controllers/calendar.controller');
  app.get('/api/calendar/export.ics', calendarExportIcs);
} catch (err) {
  console.error('❌ Failed to mount /api/calendar/export.ics:', err.message);
}
mountRoute('/api/calendar', './src/routes/calendar.routes');
mountRoute('/api/legal-notebook', './src/routes/legalNotebook.routes');
mountRoute('/api/integrations/gcal', './src/routes/gcalOAuth.routes');
mountRoute('/api/events', './src/routes/event.routes');
mountRoute('/api/admin', './src/routes/admin.routes');
mountRoute('/api/ai', './src/routes/ai.routes');
mountRoute('/api/payments', './src/routes/payment.routes');
mountRoute('/api/billing', './src/routes/billing.routes');
mountRoute('/api/chat', './src/routes/chat.routes');
mountRoute('/api/vault', './src/routes/vault.routes');
mountRoute('/api/citizen-dashboard', './src/routes/citizenDashboard.routes');
const sentryTracing = require('./src/middleware/sentryTracing.middleware');
mountRoute('/api/calls', './src/routes/call.routes', sentryTracing('calls'));
mountRoute('/api/legal-assistant', './src/routes/legalAssistant.routes');
mountRoute('/api/legal-documents', './src/routes/legalDocuments.routes');
mountRoute('/api/documents', './src/routes/document.routes');
mountRoute('/api/config', './src/routes/config.routes');

app.get('/', (_, res) =>
  res.json({
    app: 'VETO API',
    hint: 'No HTML here — use REST paths below.',
    paths: {
      health: 'GET /health',
      register: 'POST /api/auth/register',
      requestOtp: 'POST /api/auth/request-otp',
      verifyOtp: 'POST /api/auth/verify-otp',
    },
    ...(process.env.NODE_ENV !== 'production' && {
      localtunnel: {
        flutterDefaultHost: 'sweet-turkey-60.loca.lt',
        bypassHeader: { name: 'bypass-tunnel-reminder', value: 'true (any value ok)' },
        note:
          'Mobile app sends this header on API/WebSocket. Opening *.loca.lt in a normal browser still shows localtunnel’s page unless you use an extension or another tunnel (ngrok/cloudflared).',
        scripts:
          'backend: npm run tunnel (fixed host) | npm run tunnel:any (random host → set VETO_HOST in Flutter)',
      },
    }),
  }),
);

require('./src/socket/dispatch.socket')(io);
require('./src/socket/webrtc.socket')(io);

// Catch-all 404 — must be after every route mount. Without this, an unmatched path
// (typo, retired endpoint, probing) falls through to Express's default HTML 404 page
// instead of a clean JSON body, which every API client here expects.
app.use((req, res) => {
  res.status(404).json({ error: 'Not found', path: req.originalUrl });
});

// Sentry + global error handler (must be after routes; must run before listen())
if (Sentry.__vetoInstrumented) {
  app.use(Sentry.expressErrorHandler());
}
app.use(require('./src/middleware/error.middleware'));

const PORT = Number(process.env.PORT) || 5001;

function start() {
  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`❌ Port ${PORT} כבר בשימוש (שרת אחר / nodemon ישן).`);
      console.error('   PowerShell:  netstat -ano | findstr :' + PORT);
      console.error('   ואז:       taskkill /PID <מספר_PID> /F');
      console.error('   או סגור טרמינל אחר שמריץ npm run dev.');
      process.exit(1);
    }
    throw err;
  });

  // Render / cloud: חייבים להאזין מיד על 0.0.0.0 — אחרת "Application loading" נתקע אם Mongo איטי או נכשל
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 VETO Server listening on 0.0.0.0:${PORT}`);
    console.log(`   REST  → GET http://localhost:${PORT}/api (JSON discovery) · routes under /api/*`);
    console.log(`   Auth  → POST http://localhost:${PORT}/api/auth/register`);
    console.log(`   WS    → ws://localhost:${PORT}`);
    console.log(`   Health → GET /health (Mongo + Redis + config diagnostics)`);
    console.log(
      '   Dev OTP → terminal shows: ********** OTP FOR <phone>: <code> **********',
    );
    console.log(
      '   Tunnel → server FIRST, then: npm run tunnel → https://sweet-turkey-60.loca.lt',
    );
    console.log(
      '            OR npm run tunnel:any → copy host into flutter --dart-define=VETO_HOST=...',
    );
    console.log(
      '            503 = tunnel up but nothing on port ' +
        PORT +
        ' | Flutter host ≠ active tunnel | tunnel terminal closed.',
    );

    connectDB().catch((err) => {
      console.error('❌ MongoDB not connected — fix MONGO_URI / Atlas Network Access.');
      console.error('   ', err.message);
    });
  });
}

start();
