// ============================================================
//  server.js — Entry Point
//  VETO Legal Emergency App — dotenv, MongoDB, CORS, Socket.io
// ============================================================

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
      return;
    }
  }
  require('dotenv').config();
  console.warn('⚠️  No .env file found. Tried:', candidates.join(' | '));
})();

// ── Sentry (error monitoring) — init BEFORE everything else ──
const Sentry = require('@sentry/node');
if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: 0.2,
  });
  console.log('🔍 Sentry error monitoring active');
}

// Prefer IPv4 DNS — helps some Windows setups when Atlas SRV lookup fails
try {
  require('dns').setDefaultResultOrder('ipv4first');
} catch (_) {
  /* older Node */
}

const express = require('express');
const cors    = require('cors');
const http    = require('http');
const helmet  = require('helmet');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const connectDB  = require('./src/config/db');

/** ל-Render health check: השרת חי לפני ש-Mongo מחובר */
let mongoState = 'pending';
let ioReady    = false;

const app = express();
const server = http.createServer(app);

app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'bypass-tunnel-reminder',
    ],
  }),
);

// ── Security headers (European/banking standard) ──────────────
app.use(helmet({
  contentSecurityPolicy: false,  // Flutter web needs inline scripts
  crossOriginOpenerPolicy: false, // handled by Vercel headers
}));

// ── Rate limiting on auth routes ──────────────────────────────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,                    // max 20 auth attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests from this IP. Please wait 15 minutes.' },
});
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  message: { error: 'Too many OTP requests. Please wait 10 minutes.' },
});

app.use(express.json());

// ── Static uploads folder (evidence files) ─────────────────
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const io = new Server(server, {
  cors: {
    origin: true,
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
app.set('io', io);

app.use('/api/auth', authLimiter, require('./src/routes/auth.routes'));
app.use('/api/users', require('./src/routes/user.routes'));
app.use('/api/lawyers', require('./src/routes/lawyer.routes'));

// ── Public VAPID key for browser push subscription ────────────
app.get('/api/push/vapid-key', (_, res) => {
  const key = process.env.VAPID_PUBLIC_KEY;
  if (!key) return res.status(503).json({ error: 'Push notifications not configured.' });
  res.json({ publicKey: key });
});
app.use('/api/events', require('./src/routes/event.routes'));
app.use('/api/admin', require('./src/routes/admin.routes'));
app.use('/api/ai', require('./src/routes/ai.routes'));
app.use('/api/payments', require('./src/routes/payment.routes'));
app.use('/api/chat', require('./src/routes/chat.routes'));

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

app.get('/health', (_, res) =>
  res.status(200).json({
    status: 'ok',
    app: 'VETO',
    message: 'VETO Server is Alive!',
    env: process.env.NODE_ENV || 'development',
    mongo: mongoState,
    db: mongoState,          // alias used by AdminDashboard
    socket: ioReady,         // socket.io ready flag
  }),
);

app.use(require('./src/middleware/error.middleware'));
require('./src/socket/dispatch.socket')(io);
ioReady = true;

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
    console.log(`   REST  → http://localhost:${PORT}/api`);
    console.log(`   Auth  → POST http://localhost:${PORT}/api/auth/register`);
    console.log(`   WS    → ws://localhost:${PORT}`);
    console.log(`   Health → GET /health (mongo: pending → connected | error)`);
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

    connectDB()
      .then(() => {
        mongoState = 'connected';
      })
      .catch((err) => {
        mongoState = 'error';
        console.error('❌ MongoDB not connected — fix MONGO_URI / Atlas Network Access.');
        console.error('   ', err.message);
      });
  });
}

start();

// ── Sentry error handler (must be LAST middleware) ────────────
if (process.env.SENTRY_DSN) {
  const Sentry = require('@sentry/node');
  app.use(Sentry.expressErrorHandler());
}
