// ============================================================
//  Regression guard for the vault lawyer-access IDOR.
//
//  Before the fix, GET /api/vault/shared/:userId returned every
//  lawyerAccess file for ANY userId a caller passed. Any approved lawyer could
//  enumerate user ids and read the evidence vault of citizens they had never
//  been dispatched to. The controller now requires an EmergencyEvent linking
//  that citizen to the requesting lawyer.
//
//  These run against a real MongoDB because the check is a cross-collection
//  query — stubbing it would test the mock, not the rule.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

let vaultController;
let VaultFile;
let EmergencyEvent;

/** Minimal express-shaped res that records what the controller sent. */
function makeRes() {
  const res = {
    statusCode: 200,
    body: undefined,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
  return res;
}

function callController(fn, req) {
  return new Promise((resolve, reject) => {
    const res = makeRes();
    fn(req, res, (err) => (err ? reject(err) : resolve(res))).then(
      () => resolve(res),
      reject,
    );
  });
}

test.before(async () => {
  await startMemoryDb();
  vaultController = require('../src/controllers/vault.controller');
  VaultFile = require('../src/models/VaultFile');
  EmergencyEvent = require('../src/models/EmergencyEvent');
});

test.after(async () => {
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
});

async function seedCitizenWithSharedFile() {
  const citizenId = new mongoose.Types.ObjectId();
  await VaultFile.create({
    user_id: citizenId,
    name: 'הקלטת חקירה.mp3',
    url: 'https://example.test/evidence.mp3',
    sizeBytes: 1024,
    lawyerAccess: true,
  });
  return citizenId;
}

test('a lawyer with NO case for this citizen is refused (IDOR guard)', async () => {
  const citizenId = await seedCitizenWithSharedFile();
  const strangerLawyerId = new mongoose.Types.ObjectId();

  const res = await callController(vaultController.getSharedFiles, {
    params: { userId: String(citizenId) },
    user: { userId: String(strangerLawyerId), role: 'lawyer' },
  });

  assert.equal(res.statusCode, 403, 'must not expose another citizen’s vault');
  assert.equal(res.body?.files, undefined, 'no file list may leak on refusal');
});

test('a lawyer assigned to the citizen’s case can read the shared files', async () => {
  const citizenId = await seedCitizenWithSharedFile();
  const lawyerId = new mongoose.Types.ObjectId();
  await EmergencyEvent.create({
    user_id: citizenId,
    assigned_lawyer_id: lawyerId,
    status: 'completed',
  });

  const res = await callController(vaultController.getSharedFiles, {
    params: { userId: String(citizenId) },
    user: { userId: String(lawyerId), role: 'lawyer' },
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.files.length, 1);
});

test('admins retain access without a case link', async () => {
  const citizenId = await seedCitizenWithSharedFile();

  const res = await callController(vaultController.getSharedFiles, {
    params: { userId: String(citizenId) },
    user: { userId: String(new mongoose.Types.ObjectId()), role: 'admin' },
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.files.length, 1);
});

test('files the citizen did not share stay private even to the assigned lawyer', async () => {
  const citizenId = new mongoose.Types.ObjectId();
  const lawyerId = new mongoose.Types.ObjectId();
  await VaultFile.create({
    user_id: citizenId,
    name: 'יומן אישי.pdf',
    url: 'https://example.test/private.pdf',
    sizeBytes: 2048,
    lawyerAccess: false,
  });
  await EmergencyEvent.create({
    user_id: citizenId,
    assigned_lawyer_id: lawyerId,
    status: 'completed',
  });

  const res = await callController(vaultController.getSharedFiles, {
    params: { userId: String(citizenId) },
    user: { userId: String(lawyerId), role: 'lawyer' },
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.files.length, 0, 'lawyerAccess=false must never be returned');
});

test('the lawyer inbox only contains citizens that lawyer was dispatched to', async () => {
  const mine = new mongoose.Types.ObjectId();
  const theirs = new mongoose.Types.ObjectId();
  const lawyerId = new mongoose.Types.ObjectId();
  const otherLawyerId = new mongoose.Types.ObjectId();

  for (const uid of [mine, theirs]) {
    await VaultFile.create({
      user_id: uid,
      name: 'file.pdf',
      url: 'https://example.test/f.pdf',
      sizeBytes: 10,
      lawyerAccess: true,
    });
  }
  await EmergencyEvent.create({
    user_id: mine,
    assigned_lawyer_id: lawyerId,
    status: 'completed',
  });
  await EmergencyEvent.create({
    user_id: theirs,
    assigned_lawyer_id: otherLawyerId,
    status: 'completed',
  });

  const res = await callController(vaultController.getLawyerSharedInbox, {
    user: { userId: String(lawyerId), role: 'lawyer' },
    query: {},
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.files.length, 1);
  assert.equal(String(res.body.files[0].user_id), String(mine));
});

test('a lawyer with no cases gets an empty inbox, not everyone’s files', async () => {
  await seedCitizenWithSharedFile();

  const res = await callController(vaultController.getLawyerSharedInbox, {
    user: { userId: String(new mongoose.Types.ObjectId()), role: 'lawyer' },
    query: {},
  });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.files, []);
});
