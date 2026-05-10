/**
 * VETO load test: multiple citizens trigger SOS; multiple lawyer sockets race to accept.
 *
 * Env:
 *   SERVER_URL   — default http://localhost:5001
 *   CITIZEN_JWT  — JWT for role user (or admin acting as citizen)
 *   LAWYER_JWT   — JWT for role lawyer (reused for each "lawyer" socket unless LAWYER_JWTS is set)
 *   LAWYER_JWTS  — optional comma-separated JWTs for distinct lawyer accounts (length should match NUM_LAWYERS)
 *   NUM_CITIZENS — default 5
 *   NUM_LAWYERS  — default 3
 *
 * Run: npm run load-test
 */
const { io } = require('socket.io-client');

const SERVER_URL = process.env.SERVER_URL || 'http://localhost:5001';
const CITIZEN_JWT = process.env.CITIZEN_JWT;
const LAWYER_JWT = process.env.LAWYER_JWT;
const LAWYER_JWTS_RAW = process.env.LAWYER_JWTS;

const NUM_CITIZENS = Math.max(1, Number(process.env.NUM_CITIZENS || 5));
const NUM_LAWYERS = Math.max(1, Number(process.env.NUM_LAWYERS || 3));

function lawyerTokenAt(i) {
  if (LAWYER_JWTS_RAW) {
    const parts = LAWYER_JWTS_RAW.split(',').map((s) => s.trim()).filter(Boolean);
    return parts[i] || LAWYER_JWT;
  }
  return LAWYER_JWT;
}

if (!CITIZEN_JWT || !LAWYER_JWT) {
  console.error(
    'Aborting: set CITIZEN_JWT and LAWYER_JWT (or LAWYER_JWTS for multiple accounts).',
  );
  process.exit(1);
}

console.log(
  `Starting VETO load test: ${NUM_CITIZENS} citizens vs ${NUM_LAWYERS} lawyer sockets → ${SERVER_URL}`,
);

const lawyers = [];
for (let i = 0; i < NUM_LAWYERS; i += 1) {
  const token = lawyerTokenAt(i);
  const socket = io(SERVER_URL, {
    auth: { token },
    transports: ['websocket', 'polling'],
  });

  socket.on('connect', () => {
    console.log(`[Lawyer ${i}] connected`);
  });

  socket.on('new_emergency_alert', (data) => {
    const eventId = data?.eventId;
    if (!eventId) return;
    console.log(`[Lawyer ${i}] alert event=${eventId} — racing to accept…`);
    setTimeout(() => {
      socket.emit('accept_case', { eventId });
    }, Math.floor(Math.random() * 500) + 100);
  });

  socket.on('case_accepted_confirmed', (p) => {
    console.log(`[Lawyer ${i}] won race for event ${p?.eventId}`);
  });

  socket.on('case_already_taken', (p) => {
    console.log(`[Lawyer ${i}] lost race / already taken: ${p?.eventId}`);
  });

  socket.on('case_taken', (p) => {
    console.log(`[Lawyer ${i}] case_taken broadcast: ${p?.eventId}`);
  });

  socket.on('veto_error', (e) => {
    console.log(`[Lawyer ${i}] veto_error:`, e?.message || e);
  });

  socket.on('connect_error', (err) => {
    console.error(`[Lawyer ${i}] connect_error:`, err.message);
  });

  lawyers.push(socket);
}

const citizens = [];
for (let i = 0; i < NUM_CITIZENS; i += 1) {
  setTimeout(() => {
    const socket = io(SERVER_URL, {
      auth: { token: CITIZEN_JWT },
      transports: ['websocket', 'polling'],
    });

    let pendingEventId = null;

    socket.on('connect', () => {
      console.log(`[Citizen ${i}] connected — start_veto`);
      socket.emit('start_veto', {
        location: { lat: 31.7, lng: 35.2 },
        preferredLanguage: 'he',
        specialization: 'general',
      });
    });

    socket.on('emergency_created', (p) => {
      pendingEventId = p?.eventId;
      console.log(`[Citizen ${i}] emergency_created event=${pendingEventId}`);
    });

    socket.on('lawyer_found', (p) => {
      const eventId = p?.eventId || pendingEventId;
      console.log(`[Citizen ${i}] lawyer_found event=${eventId}`);
      socket.emit('citizen_chose_session', {
        eventId,
        callType: 'video',
      });
    });

    socket.on('session_ready', (p) => {
      console.log(`[Citizen ${i}] session_ready event=${p?.eventId || p?.channelId}`);
      socket.disconnect();
    });

    socket.on('no_lawyers_available', (p) => {
      console.warn(`[Citizen ${i}] no_lawyers_available`, p?.message);
      socket.disconnect();
    });

    socket.on('veto_error', (e) => {
      console.log(`[Citizen ${i}] veto_error:`, e?.message || e);
    });

    socket.on('connect_error', (err) => {
      console.error(`[Citizen ${i}] connect_error:`, err.message);
    });

    citizens.push(socket);
  }, i * 300);
}
