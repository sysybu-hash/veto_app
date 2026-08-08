// ============================================================
//  Family plan seat management.
//
//  Two things this guards that were previously wrong or missing:
//
//  1. Seat accounting. `familySeats: 4` means four PEOPLE, the owner
//     included. The old route compared it against the member count alone, so
//     owner + 4 = 5 people fitted on a 4-seat plan, while the screen showed
//     "x / 3". Server and UI disagreed and the server was the wrong one.
//
//  2. Invitations. Adding someone who had not registered yet returned
//     "User with that phone is not registered" and did nothing. A seat is now
//     reserved and claimed automatically when they sign up.
// ============================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  startMemoryDb,
  stopMemoryDb,
  clearCollections,
} = require('./helpers/memoryDb');

let family;
let User;
let FamilyInvite;

// Twilio/SMTP are not configured in tests, so notifications no-op. That is
// itself worth asserting: a missing text must never block a seat change.
test.before(async () => {
  await startMemoryDb();
  family = require('../src/services/familyPlan.service');
  User = require('../src/models/User');
  FamilyInvite = require('../src/models/FamilyInvite');
  await FamilyInvite.syncIndexes();
});

test.after(async () => {
  await stopMemoryDb();
});

test.beforeEach(async () => {
  await clearCollections();
});

let phoneSeq = 0;
function nextPhone() {
  phoneSeq += 1;
  return `+9725${String(10000000 + phoneSeq).slice(0, 8)}`;
}

async function makeOwner() {
  const owner = await User.create({
    full_name: 'בעל המנוי',
    phone: nextPhone(),
    role: 'user',
    subscription_plan: 'family',
    is_subscribed: true,
    subscription_expiry: new Date(Date.now() + 30 * 86400000),
  });
  owner.family_owner_id = owner._id;
  await owner.save();
  return owner;
}

async function makeCitizen(name = 'אזרח') {
  return User.create({ full_name: name, phone: nextPhone(), role: 'user' });
}

test('a fresh plan reports the owner already occupying one seat', async () => {
  const owner = await makeOwner();
  const usage = await family.seatUsage(owner._id);
  assert.equal(usage.total, 4);
  assert.equal(usage.used, 1, 'the owner counts against the plan');
  assert.equal(usage.free, 3);
});

test('an existing user is linked immediately and inherits the expiry', async () => {
  const owner = await makeOwner();
  const target = await makeCitizen();

  const res = await family.addToPlan(owner, target.phone);
  assert.equal(res.kind, 'linked');

  const after = await User.findById(target._id);
  assert.equal(String(after.family_owner_id), String(owner._id));
  assert.equal(after.subscription_plan, 'family');
  assert.equal(after.is_subscribed, true);
  assert.equal(
    new Date(after.subscription_expiry).getTime(),
    new Date(owner.subscription_expiry).getTime(),
    'member expiry must mirror the owner',
  );
});

test('the plan holds exactly four people, owner included', async () => {
  const owner = await makeOwner();
  for (let i = 0; i < 3; i += 1) {
    const c = await makeCitizen(`בן משפחה ${i}`);
    await family.addToPlan(owner, c.phone);
  }
  const usage = await family.seatUsage(owner._id);
  assert.equal(usage.used, 4);
  assert.equal(usage.free, 0);

  const fourth = await makeCitizen('אחד יותר מדי');
  await assert.rejects(
    () => family.addToPlan(owner, fourth.phone),
    (err) => err.status === 409 && /4/.test(err.message),
    'a fifth person must be refused',
  );
});

test('an unregistered number reserves a seat instead of erroring', async () => {
  const owner = await makeOwner();
  const phone = nextPhone();

  const res = await family.addToPlan(owner, phone);
  assert.equal(res.kind, 'invited');

  const invite = await FamilyInvite.findOne({ phone }).lean();
  assert.ok(invite, 'an invite row must exist');
  assert.equal(invite.status, 'pending');
  assert.ok(invite.expires_at > new Date());

  const usage = await family.seatUsage(owner._id);
  assert.equal(usage.used, 2, 'a pending invite holds a seat');
});

test('pending invites cannot be used to over-commit the plan', async () => {
  const owner = await makeOwner();
  for (let i = 0; i < 3; i += 1) await family.addToPlan(owner, nextPhone());
  await assert.rejects(
    () => family.addToPlan(owner, nextPhone()),
    (err) => err.status === 409,
    'three reservations plus the owner fill the plan',
  );
});

test('registering with an invited number claims the seat automatically', async () => {
  const owner = await makeOwner();
  const phone = nextPhone();
  await family.addToPlan(owner, phone);

  // Simulates what auth.controller does right after User.create.
  const joiner = await User.create({ full_name: 'מצטרף', phone, role: 'user' });
  const claimed = await family.claimInviteForNewUser(joiner);
  assert.ok(claimed, 'the invite should be claimed');

  const after = await User.findById(joiner._id);
  assert.equal(String(after.family_owner_id), String(owner._id));
  assert.equal(after.is_subscribed, true);

  const invite = await FamilyInvite.findOne({ phone }).lean();
  assert.equal(invite.status, 'accepted');
  assert.equal(String(invite.accepted_user_id), String(joiner._id));

  // The seat moved from reserved to occupied; it must not be counted twice.
  const usage = await family.seatUsage(owner._id);
  assert.equal(usage.used, 2);
});

test('registering with no invite is untouched', async () => {
  const stranger = await User.create({
    full_name: 'זר',
    phone: nextPhone(),
    role: 'user',
  });
  assert.equal(await family.claimInviteForNewUser(stranger), null);
  const after = await User.findById(stranger._id);
  assert.equal(after.family_owner_id ?? null, null);
  assert.notEqual(after.is_subscribed, true);
});

test('cancelling an invite frees the seat', async () => {
  const owner = await makeOwner();
  const res = await family.addToPlan(owner, nextPhone());
  assert.equal((await family.seatUsage(owner._id)).free, 2);

  await family.cancelInvite(owner, res.invite.id);
  assert.equal((await family.seatUsage(owner._id)).free, 3);

  const invite = await FamilyInvite.findById(res.invite.id).lean();
  assert.equal(invite.status, 'cancelled');
});

test('a cancelled invite does not block re-inviting the same number', async () => {
  const owner = await makeOwner();
  const phone = nextPhone();
  const first = await family.addToPlan(owner, phone);
  await family.cancelInvite(owner, first.invite.id);
  const second = await family.addToPlan(owner, phone);
  assert.equal(second.kind, 'invited', 'the partial unique index must allow this');
});

test('the same number cannot be invited twice while one is pending', async () => {
  const owner = await makeOwner();
  const phone = nextPhone();
  await family.addToPlan(owner, phone);
  await assert.rejects(
    () => family.addToPlan(owner, phone),
    (err) => err.status === 409,
  );
});

test('someone on another family plan is refused', async () => {
  const ownerA = await makeOwner();
  const ownerB = await makeOwner();
  const shared = await makeCitizen();
  await family.addToPlan(ownerA, shared.phone);

  await assert.rejects(
    () => family.addToPlan(ownerB, shared.phone),
    (err) => err.status === 409 && /אחר/.test(err.message),
  );
});

test('the owner cannot add themselves', async () => {
  const owner = await makeOwner();
  await assert.rejects(
    () => family.addToPlan(owner, owner.phone),
    (err) => err.status === 400,
  );
});

test('removing a member revokes access and frees the seat', async () => {
  const owner = await makeOwner();
  const member = await makeCitizen();
  await family.addToPlan(owner, member.phone);
  assert.equal((await family.seatUsage(owner._id)).used, 2);

  await family.removeMember(owner, member._id);

  const after = await User.findById(member._id);
  assert.equal(after.family_owner_id ?? null, null);
  assert.equal(after.is_subscribed, false);
  assert.equal(after.subscription_expiry ?? null, null);
  assert.equal((await family.seatUsage(owner._id)).used, 1);
});

test('an owner cannot remove someone from another plan', async () => {
  const ownerA = await makeOwner();
  const ownerB = await makeOwner();
  const member = await makeCitizen();
  await family.addToPlan(ownerA, member.phone);

  await assert.rejects(
    () => family.removeMember(ownerB, member._id),
    (err) => err.status === 409,
  );
});

test('a seat change succeeds even though no SMS or SMTP is configured', async () => {
  const owner = await makeOwner();
  const member = await makeCitizen();
  const res = await family.addToPlan(owner, member.phone);
  assert.equal(res.notified.sms, false, 'no Twilio in tests');
  assert.equal(res.notified.email, false, 'no SMTP in tests');
  const after = await User.findById(member._id);
  assert.equal(after.is_subscribed, true, 'the membership still applied');
});

test('the plan view shows members, pending invites and seat counts', async () => {
  const owner = await makeOwner();
  const member = await makeCitizen('חבר');
  await family.addToPlan(owner, member.phone);
  await family.addToPlan(owner, nextPhone());

  const view = await family.getPlanView(owner._id);
  assert.equal(view.isOwner, true);
  assert.equal(view.members.length, 1);
  assert.equal(view.invites.length, 1);
  assert.equal(view.seats, 4);
  assert.equal(view.seatsUsed, 3);
  assert.equal(view.seatsFree, 1);
});

test('a member sees the plan but not its pending invites', async () => {
  const owner = await makeOwner();
  const member = await makeCitizen('חבר');
  await family.addToPlan(owner, member.phone);
  await family.addToPlan(owner, nextPhone());

  const view = await family.getPlanView(member._id);
  assert.equal(view.isOwner, false);
  assert.equal(view.invites.length, 0, 'only the owner sees invited numbers');
  assert.ok(view.owner, 'a member still sees who owns the plan');
});

test('someone with no plan gets an empty view rather than an error', async () => {
  const nobody = await makeCitizen();
  const view = await family.getPlanView(nobody._id);
  assert.equal(view.owner, null);
  assert.deepEqual(view.members, []);
});
