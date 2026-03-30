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

// Prefer IPv4 DNS — helps some Windows setups when Atlas SRV lookup fails
try {
  require('dns').setDefaultResultOrder('ipv4first');
} catch (_) {
  /* older Node */
}

const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./src/config/db');

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

app.use(express.json());

const io = new Server(server, {
  cors: {
    origin: true,
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
app.set('io', io);

app.use('/api/auth', require('./src/routes/auth.routes'));
app.use('/api/users', require('./src/routes/user.routes'));
app.use('/api/lawyers', require('./src/routes/lawyer.routes'));
app.use('/api/events', require('./src/routes/event.routes'));

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
  res.json({
    status: 'ok',
    app: 'VETO',
    message: 'VETO Server is Alive!',
    env: process.env.NODE_ENV || 'development',
  }),
);

app.use(require('./src/middleware/error.middleware'));
require('./src/socket/dispatch.socket')(io);

const PORT = Number(process.env.PORT) || 5001;

async function start() {
  await connectDB();

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

  server.listen(PORT, () => {
    console.log(`🚀 VETO Server running on port ${PORT}`);
    console.log(`   REST  → http://localhost:${PORT}/api`);
    console.log(`   Auth  → POST http://localhost:${PORT}/api/auth/register`);
    console.log(`   WS    → ws://localhost:${PORT}`);
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
  });
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
