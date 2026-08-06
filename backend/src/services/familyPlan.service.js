// ============================================================
//  familyPlan.service.js — owner-managed seats on the family plan.
//
//  Seat accounting note: PLANS.family.familySeats is the TOTAL number of
//  people covered, the owner included. The route used to compare it against
//  the member count alone, which silently allowed owner + 4 = 5 people while
//  the UI displayed "x / seats-1". Server and screen disagreed; the server was
//  the wrong one. Everything here counts owner + members + pending invites
//  against the same number.
// ============================================================

const mongoose = require('mongoose');
const User = require('../models/User');
const FamilyInvite = require('../models/FamilyInvite');
const { PLANS } = require('../config/pricing');
const { sendTransactionalSms } = require('./auth/sms.service');
const { sendEmail, isConfigured: emailConfigured } = require('./email.service');
const logger = require('../lib/logger');

const INVITE_TTL_DAYS = 14;

function totalSeats() {
  return PLANS.family.familySeats;
}

function siteUrl() {
  return (
    process.env.WEB_APP_URL ||
    process.env.FRONTEND_URL ||
    'https://veto-legal.co.il'
  ).replace(/\/$/, '');
}

/** Seats in use = the owner + linked members + still-pending invites. */
async function seatUsage(ownerId) {
  const [members, pending] = await Promise.all([
    User.countDocuments({ family_owner_id: ownerId, _id: { $ne: ownerId } }),
    FamilyInvite.countDocuments({
      owner_id: ownerId,
      status: 'pending',
      expires_at: { $gt: new Date() },
    }),
  ]);
  const used = 1 + members + pending; // 1 = the owner's own seat
  return { members, pending, used, total: totalSeats(), free: totalSeats() - used };
}

/**
 * Notifies a person about a family-plan change. Never throws: a failed text
 * must not roll back the membership change the owner just made. Returns what
 * actually went out so the caller can tell the owner the truth.
 */
async function notify({ phone, email, smsBody, emailSubject, emailText }) {
  const out = { sms: false, email: false };
  if (phone) {
    const r = await sendTransactionalSms(phone, smsBody);
    out.sms = r.sent;
  }
  if (email && emailConfigured()) {
    try {
      const r = await sendEmail({ to: email, subject: emailSubject, text: emailText });
      out.email = !!r.sent;
    } catch (err) {
      logger.warn({ err: String(err?.message || err) }, '[family] email notify failed');
    }
  }
  return out;
}

/** Links an existing account to the owner's plan and mirrors their expiry. */
async function linkMember(owner, target) {
  target.family_owner_id = owner._id;
  target.subscription_plan = 'family';
  target.is_subscribed = true;
  target.subscription_expiry = owner.subscription_expiry;
  await target.save();

  const notified = await notify({
    phone: target.phone,
    email: target.email,
    smsBody:
      `צורפת למנוי המשפחתי של ${owner.full_name || 'בן משפחה'} ב-VETO Legal.\n` +
      `הגנה משפטית בחירום זמינה לך עכשיו: ${siteUrl()}`,
    emailSubject: 'צורפת למנוי המשפחתי ב-VETO Legal',
    emailText:
      `שלום ${target.full_name || ''},\n\n` +
      `${owner.full_name || 'בן משפחה'} צירף/ה אותך למנוי המשפחתי ב-VETO Legal.\n` +
      `מרגע זה יש לך גישה מלאה לשירות: ${siteUrl()}\n\n` +
      `אם לדעתך זו טעות, ניתן לפנות אלינו דרך ${siteUrl()}/contact`,
  });
  return { member: target, notified };
}

/**
 * Adds a phone to the plan. If that person already has an account they are
 * linked immediately; otherwise a seat is reserved and an invite is sent that
 * gets claimed automatically when they register.
 */
async function addToPlan(owner, rawPhone) {
  const phone = String(rawPhone || '').trim();
  if (!phone) {
    const err = new Error('נדרש מספר טלפון.');
    err.status = 400;
    throw err;
  }
  if (phone === owner.phone) {
    const err = new Error('בעל המנוי כבר נכלל בו.');
    err.status = 400;
    throw err;
  }

  const usage = await seatUsage(owner._id);
  if (usage.free <= 0) {
    const err = new Error(
      `המנוי המשפחתי מוגבל ל-${usage.total} משתמשים, כולל בעל המנוי. ` +
        `בטלו הזמנה ממתינה או הסירו חבר כדי לפנות מקום.`,
    );
    err.status = 409;
    throw err;
  }

  const target = await User.findOne({ phone });

  if (target) {
    if (String(target._id) === String(owner._id)) {
      const err = new Error('בעל המנוי כבר נכלל בו.');
      err.status = 400;
      throw err;
    }
    if (target.family_owner_id && String(target.family_owner_id) !== String(owner._id)) {
      const err = new Error('המשתמש כבר משויך למנוי משפחתי אחר.');
      err.status = 409;
      throw err;
    }
    if (String(target.family_owner_id) === String(owner._id)) {
      const err = new Error('המשתמש כבר נמצא במנוי שלך.');
      err.status = 409;
      throw err;
    }
    const { member, notified } = await linkMember(owner, target);
    return {
      kind: 'linked',
      member: { id: String(member._id), name: member.full_name, phone: member.phone },
      notified,
    };
  }

  // Not registered — reserve the seat.
  const expiresAt = new Date(Date.now() + INVITE_TTL_DAYS * 86400000);
  let invite;
  try {
    invite = await FamilyInvite.create({
      owner_id: owner._id,
      phone,
      invited_by_name: owner.full_name || '',
      expires_at: expiresAt,
    });
  } catch (err) {
    if (err?.code === 11000) {
      const dup = new Error('כבר קיימת הזמנה ממתינה למספר הזה.');
      dup.status = 409;
      throw dup;
    }
    throw err;
  }

  const notified = await notify({
    phone,
    smsBody:
      `${owner.full_name || 'בן משפחה'} הזמין/ה אותך למנוי המשפחתי ב-VETO Legal — ` +
      `עורך דין בווידאו תוך שניות ברגע חירום.\n` +
      `להרשמה עם המספר הזה: ${siteUrl()}/register\n` +
      `ההזמנה בתוקף ל-${INVITE_TTL_DAYS} ימים.`,
    emailSubject: 'הוזמנת למנוי המשפחתי ב-VETO Legal',
    emailText: '',
  });

  await FamilyInvite.updateOne(
    { _id: invite._id },
    { $set: { 'notified.sms': notified.sms, 'notified.email': notified.email } },
  );

  return {
    kind: 'invited',
    invite: {
      id: String(invite._id),
      phone: invite.phone,
      expiresAt: invite.expires_at,
    },
    notified,
  };
}

/** Removes a linked member and tells them, so they don't find out mid-emergency. */
async function removeMember(owner, memberId) {
  const target = await User.findById(memberId);
  if (!target) {
    const err = new Error('החבר לא נמצא.');
    err.status = 404;
    throw err;
  }
  if (String(target.family_owner_id) !== String(owner._id)) {
    const err = new Error('המשתמש אינו נמצא במנוי שלך.');
    err.status = 409;
    throw err;
  }

  target.family_owner_id = null;
  target.subscription_plan = null;
  target.is_subscribed = false;
  target.subscription_expiry = null;
  await target.save();

  // Silent removal used to mean the person discovered it by pressing SOS.
  const notified = await notify({
    phone: target.phone,
    email: target.email,
    smsBody:
      `הוסרת מהמנוי המשפחתי של ${owner.full_name || 'בן משפחה'} ב-VETO Legal, ` +
      `והשירות אינו זמין לך כרגע.\nלמסלול אישי: ${siteUrl()}/pricing`,
    emailSubject: 'הוסרת מהמנוי המשפחתי ב-VETO Legal',
    emailText:
      `שלום ${target.full_name || ''},\n\n` +
      `הוסרת מהמנוי המשפחתי ב-VETO Legal, והשירות אינו זמין לך כרגע.\n` +
      `החשבון והמסמכים שלך נשמרים. למסלול אישי: ${siteUrl()}/pricing`,
  });
  return { notified };
}

async function cancelInvite(owner, inviteId) {
  if (!mongoose.isValidObjectId(inviteId)) {
    const err = new Error('מזהה הזמנה לא תקין.');
    err.status = 400;
    throw err;
  }
  const res = await FamilyInvite.findOneAndUpdate(
    { _id: inviteId, owner_id: owner._id, status: 'pending' },
    { $set: { status: 'cancelled' } },
    { new: true },
  );
  if (!res) {
    const err = new Error('הזמנה ממתינה לא נמצאה.');
    err.status = 404;
    throw err;
  }
  return { id: String(res._id) };
}

/**
 * Called right after a new account is created. If a seat was reserved for that
 * phone, claim it — this is what turns "invite" into something the owner does
 * not have to follow up on.
 *
 * Best-effort by design: a failure here must never break registration.
 */
async function claimInviteForNewUser(user) {
  try {
    if (!user?.phone) return null;
    const invite = await FamilyInvite.findOneAndUpdate(
      { phone: user.phone, status: 'pending', expires_at: { $gt: new Date() } },
      { $set: { status: 'accepted', accepted_at: new Date(), accepted_user_id: user._id } },
      { new: true, sort: { createdAt: 1 } },
    );
    if (!invite) return null;

    const owner = await User.findById(invite.owner_id);
    if (!owner || owner.subscription_plan !== 'family') return null;

    const usage = await seatUsage(owner._id);
    // The reservation we just consumed is no longer pending, so a full plan
    // here means seats were taken by others in the meantime.
    if (usage.free < 0) {
      logger.warn(
        { ownerId: String(owner._id) },
        '[family] invite accepted but plan is over capacity — not linking',
      );
      return null;
    }

    await linkMember(owner, user);
    logger.info(
      { ownerId: String(owner._id), userId: String(user._id) },
      '[family] pending invite claimed on registration',
    );
    return { ownerId: String(owner._id) };
  } catch (err) {
    logger.warn({ err }, '[family] claiming invite on registration failed');
    return null;
  }
}

/** Everything the owner's screen needs, in one read. */
async function getPlanView(userId) {
  const me = await User.findById(userId).select(
    'full_name phone subscription_plan family_owner_id subscription_expiry',
  );
  if (!me) {
    const err = new Error('משתמש לא נמצא.');
    err.status = 404;
    throw err;
  }
  const ownerId =
    me.family_owner_id || (me.subscription_plan === 'family' ? me._id : null);
  if (!ownerId) {
    return { owner: null, members: [], invites: [], seats: totalSeats(), isOwner: false };
  }

  const owner = await User.findById(ownerId).select(
    'full_name phone subscription_expiry',
  );
  const members = await User.find({
    family_owner_id: ownerId,
    _id: { $ne: ownerId },
  }).select('full_name phone');

  const isOwner = String(ownerId) === String(me._id);
  const invites = isOwner
    ? await FamilyInvite.find({
        owner_id: ownerId,
        status: 'pending',
        expires_at: { $gt: new Date() },
      })
        .select('phone expires_at notified')
        .lean()
    : [];

  const usage = await seatUsage(ownerId);
  return {
    owner: owner
      ? {
          id: String(owner._id),
          name: owner.full_name,
          phone: owner.phone,
          expiry: owner.subscription_expiry,
        }
      : null,
    members: members.map((m) => ({
      id: String(m._id),
      name: m.full_name,
      phone: m.phone,
    })),
    invites: invites.map((i) => ({
      id: String(i._id),
      phone: i.phone,
      expiresAt: i.expires_at,
      smsSent: !!i.notified?.sms,
    })),
    seats: usage.total,
    seatsUsed: usage.used,
    seatsFree: usage.free,
    isOwner,
  };
}

module.exports = {
  totalSeats,
  seatUsage,
  addToPlan,
  removeMember,
  cancelInvite,
  claimInviteForNewUser,
  getPlanView,
  INVITE_TTL_DAYS,
};
