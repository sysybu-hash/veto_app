// ============================================================
//  Chat is citizen ↔ lawyer only.
//
//  Before the hardening, /api/chat/messages trusted the client-supplied
//  `receiver_role` and never checked who the recipient actually was, so a
//  lawyer could message another lawyer and a citizen could message another
//  citizen. This mounts the REAL router behind the REAL auth middleware and
//  drives it over HTTP, so the JWT handling and the rule are both exercised.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'chat-pair-test-secret';

let server;
let baseUrl;
let User;
let Lawyer;
let Message;

function tokenFor(id, role) {
  return jwt.sign({ userId: String(id), role }, process.env.JWT_SECRET);
}

async function api(path, { token, method = 'GET', body } = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }
  return { status: res.status, body: json };
}

test.before(async () => {
  await startMemoryDb();
  User = require('../src/models/User');
  Lawyer = require('../src/models/Lawyer');
  await Lawyer.syncIndexes();
  Message = require('../src/models/Message');

  const app = express();
  app.use(express.json());
  app.use('/api/chat', require('../src/routes/chat.routes'));
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, _next) => res.status(500).json({ error: String(err) }));

  server = http.createServer(app);
  await new Promise((r) => server.listen(0, r));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  await new Promise((r) => server.close(r));
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
});

async function makeCitizen(name = 'אזרח') {
  return User.create({
    full_name: name,
    phone: `+9725${String(Math.floor(Math.random() * 1e8)).padStart(8, '0')}`,
    role: 'user',
    is_active: true,
  });
}

async function makeLawyer(name = 'עו״ד') {
  return Lawyer.create({
    full_name: name,
    phone: `+9725${String(Math.floor(Math.random() * 1e8)).padStart(8, '0')}`,
    is_approved: true,
    is_active: true,
  });
}

test('unauthenticated requests are rejected', async () => {
  const res = await api('/api/chat/conversations');
  assert.equal(res.status, 401);
});

test('a citizen may message a lawyer', async () => {
  const citizen = await makeCitizen();
  const lawyer = await makeLawyer();

  const res = await api('/api/chat/messages', {
    token: tokenFor(citizen._id, 'user'),
    method: 'POST',
    body: { receiver_id: String(lawyer._id), text: 'שלום, אני צריך עזרה' },
  });

  assert.ok(
    res.status === 200 || res.status === 201,
    `expected a success status, got ${res.status}`,
  );
  const saved = await Message.findOne({ sender_id: citizen._id });
  assert.ok(saved, 'message should be persisted');
  assert.equal(saved.receiver_role, 'lawyer');
});

test('a citizen may NOT message another citizen', async () => {
  const a = await makeCitizen('אזרח א');
  const b = await makeCitizen('אזרח ב');

  const res = await api('/api/chat/messages', {
    token: tokenFor(a._id, 'user'),
    method: 'POST',
    body: { receiver_id: String(b._id), text: 'היי' },
  });

  assert.equal(res.status, 403);
  assert.equal(await Message.countDocuments({}), 0, 'nothing may be persisted');
});

test('a lawyer may NOT message another lawyer', async () => {
  const a = await makeLawyer('עו״ד א');
  const b = await makeLawyer('עו״ד ב');

  const res = await api('/api/chat/messages', {
    token: tokenFor(a._id, 'lawyer'),
    method: 'POST',
    body: { receiver_id: String(b._id), text: 'שיחה פנימית' },
  });

  assert.equal(res.status, 403);
  assert.equal(await Message.countDocuments({}), 0);
});

test('a forged receiver_role cannot smuggle a lawyer↔lawyer message through', async () => {
  // The old code trusted this field; the recipient kind is now resolved from
  // the database and the client claim is ignored.
  const a = await makeLawyer('עו״ד א');
  const b = await makeLawyer('עו״ד ב');

  const res = await api('/api/chat/messages', {
    token: tokenFor(a._id, 'lawyer'),
    method: 'POST',
    body: {
      receiver_id: String(b._id),
      receiver_role: 'user', // lie
      text: 'עוקף',
    },
  });

  assert.equal(res.status, 403);
  assert.equal(await Message.countDocuments({}), 0);
});

test('receiver_role is taken from the DB, not from the request body', async () => {
  const citizen = await makeCitizen();
  const lawyer = await makeLawyer();

  await api('/api/chat/messages', {
    token: tokenFor(citizen._id, 'user'),
    method: 'POST',
    body: {
      receiver_id: String(lawyer._id),
      receiver_role: 'admin', // lie
      text: 'שלום',
    },
  });

  const saved = await Message.findOne({});
  assert.equal(saved.receiver_role, 'lawyer', 'client claim must be overridden');
});

test('messaging a non-existent recipient is a 404, not a silent write', async () => {
  const citizen = await makeCitizen();
  const res = await api('/api/chat/messages', {
    token: tokenFor(citizen._id, 'user'),
    method: 'POST',
    body: { receiver_id: String(new mongoose.Types.ObjectId()), text: 'שלום' },
  });

  assert.equal(res.status, 404);
  assert.equal(await Message.countDocuments({}), 0);
});

test('reading a lawyer↔lawyer thread is refused too, not just writing', async () => {
  const a = await makeLawyer('עו״ד א');
  const b = await makeLawyer('עו״ד ב');

  const res = await api(`/api/chat/messages/${b._id}`, {
    token: tokenFor(a._id, 'lawyer'),
  });

  assert.equal(res.status, 403);
});

test('a citizen sees only lawyers in the partner picker', async () => {
  const citizen = await makeCitizen();
  await makeCitizen('אזרח אחר');
  await makeLawyer('עו״ד זמין');

  const res = await api('/api/chat/partners', {
    token: tokenFor(citizen._id, 'user'),
  });

  assert.equal(res.status, 200);
  assert.ok(res.body.partners.length > 0);
  assert.ok(
    res.body.partners.every((p) => p.role === 'lawyer'),
    'a citizen must never be offered another citizen',
  );
});

test('a lawyer sees only citizen-side accounts in the partner picker', async () => {
  const lawyer = await makeLawyer();
  await makeCitizen('אזרח');
  await makeLawyer('עו״ד אחר');

  const res = await api('/api/chat/partners', {
    token: tokenFor(lawyer._id, 'lawyer'),
  });

  assert.equal(res.status, 200);
  assert.ok(res.body.partners.length > 0);
  assert.ok(
    res.body.partners.every((p) => p.role !== 'lawyer'),
    'no lawyer may appear in another lawyer’s partner list',
  );
});

test('more than one lawyer can exist without an email address', async () => {
  // Regression guard: Lawyer.email used to be `unique + sparse` with
  // `default: null`. A sparse index skips MISSING fields, not explicit nulls,
  // so the second email-less lawyer died with E11000 — meaning the admin panel
  // could only ever onboard one lawyer who had no email on file.
  const a = await makeLawyer('עו״ד ללא מייל א');
  const b = await makeLawyer('עו״ד ללא מייל ב');
  assert.ok(a._id && b._id);
  assert.equal(a.email, undefined, 'email must be absent, never null');
  assert.equal(b.email, undefined);

  // Real emails are still unique.
  await Lawyer.create({
    full_name: 'עו״ד עם מייל',
    phone: '+972500000123',
    email: 'dup@example.test',
  });
  await assert.rejects(
    () =>
      Lawyer.create({
        full_name: 'מתחזה',
        phone: '+972500000124',
        email: 'dup@example.test',
      }),
    /E11000|duplicate key/i,
  );
});
