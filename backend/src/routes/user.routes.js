// ============================================================
//  user.routes.js
//  VETO Legal Emergency App
//
//  GET  /api/users/me        → current user profile
//  PUT  /api/users/me        → update profile / preferred_language
//  PUT  /api/users/location  → update last known GPS location
// ============================================================

const express    = require('express');
const router     = express.Router();
const { protect, requireValidMongoUserId } = require('../middleware/auth.middleware');
const User       = require('../models/User');

const EmergencyEvent = require('../models/EmergencyEvent');
const PrivacyRequest = require('../models/PrivacyRequest');

router.use(protect);
router.use(requireValidMongoUserId);

router.get('/entitlement', async (req, res, next) => {
  try {
    if (req.user.role === 'lawyer') {
      return res.json({
        allowed: true,
        status: 'lawyer',
        reason: 'Lawyer accounts do not require citizen subscriptions.',
        nextAction: 'dashboard',
      });
    }

    const user = await User.findById(req.user.userId).select(
      'role manually_added is_subscribed subscription_plan subscription_status subscription_expiry family_owner_id pending_consultation_token consultations_included consultations_used',
    );
    if (!user) return res.status(404).json({ error: 'User not found.' });

    const pendingOvertime = await EmergencyEvent.countDocuments({
      user_id: req.user.userId,
      charge_status: 'pending',
      charge_amount_ils: { $gt: 0 },
    });

    const expired = user.subscription_expiry && user.subscription_expiry < new Date();
    const paymentExempt = user.role === 'admin' || !!user.manually_added;
    let status = 'payment_required';
    let allowed = false;
    let reason = 'No active plan or paid consultation is available.';
    let nextAction = 'pricing';

    if (paymentExempt) {
      status = 'exempt';
      allowed = true;
      reason = 'Account is payment-exempt, including legal consultations.';
      nextAction = 'sos';
    } else if (pendingOvertime > 0) {
      status = 'overtime_pending';
      allowed = false;
      reason = 'A previous call has overtime minutes pending payment.';
      nextAction = 'pay_overtime';
    } else if (user.is_subscribed && user.subscription_plan && !expired) {
      status = user.subscription_plan === 'family' ? 'family_active' : 'subscription_active';
      allowed = true;
      reason = 'Active subscription found.';
      nextAction = 'sos';
    } else if (user.pending_consultation_token) {
      status = 'consultation_paid';
      allowed = true;
      reason = 'A one-time consultation is paid and ready.';
      nextAction = 'sos';
    }

    res.json({
      allowed,
      status,
      reason,
      nextAction,
      planId: expired ? null : user.subscription_plan,
      subscriptionExpiry: user.subscription_expiry,
      consultationsIncluded: user.consultations_included || 0,
      consultationsUsed: user.consultations_used || 0,
      pendingOvertime: paymentExempt ? 0 : pendingOvertime,
      paymentExempt,
      consultationExempt: paymentExempt,
    });
  } catch (err) { next(err); }
});

router.get('/privacy-requests', async (req, res, next) => {
  try {
    const requests = await PrivacyRequest.find({ user_id: req.user.userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ requests });
  } catch (err) { next(err); }
});

router.post('/privacy-requests', async (req, res, next) => {
  try {
    const type = String(req.body?.type || '');
    if (!['export', 'delete', 'correct'].includes(type)) {
      return res.status(400).json({ error: 'Invalid privacy request type.' });
    }
    const request = await PrivacyRequest.create({
      user_id: req.user.userId,
      type,
      note: req.body?.note ? String(req.body.note).slice(0, 1000) : '',
    });
    res.status(201).json({ request });
  } catch (err) { next(err); }
});

// ── Family plan ────────────────────────────────────────────
// All logic lives in familyPlan.service.js: seat accounting (which counts the
// owner, unlike the version this replaced), invitations for phone numbers that
// are not registered yet, and notifying people when their access changes.
const familyPlan = require('../services/familyPlan.service');
const { normalizePhoneForVeto } = require('../services/auth/phone.service');

/** Loads the caller and asserts they own an active family plan. */
async function requireFamilyOwner(req) {
  const owner = await User.findById(req.user.userId);
  if (!owner) {
    const e = new Error('משתמש לא נמצא.');
    e.status = 404;
    throw e;
  }
  if (owner.subscription_plan !== 'family' ||
      String(owner.family_owner_id) !== String(owner._id)) {
    const e = new Error('רק בעל המנוי המשפחתי יכול לנהל אותו.');
    e.status = 403;
    throw e;
  }
  if (owner.subscription_expiry && owner.subscription_expiry < new Date()) {
    const e = new Error('המנוי המשפחתי פג תוקף.');
    e.status = 403;
    throw e;
  }
  return owner;
}

function sendErr(res, err, next) {
  if (err?.status) return res.status(err.status).json({ error: err.message });
  return next(err);
}

router.post('/family/invite', async (req, res, next) => {
  try {
    const owner = await requireFamilyOwner(req);
    const phone = normalizePhoneForVeto(String(req.body?.phone || '').trim());
    const result = await familyPlan.addToPlan(owner, phone);
    res.status(result.kind === 'invited' ? 201 : 200).json({ success: true, ...result });
  } catch (err) { sendErr(res, err, next); }
});

router.get('/family', async (req, res, next) => {
  try {
    res.json(await familyPlan.getPlanView(req.user.userId));
  } catch (err) { sendErr(res, err, next); }
});

router.delete('/family/invite/:inviteId', async (req, res, next) => {
  try {
    const owner = await requireFamilyOwner(req);
    res.json({ success: true, ...(await familyPlan.cancelInvite(owner, req.params.inviteId)) });
  } catch (err) { sendErr(res, err, next); }
});

router.delete('/family/:memberId', async (req, res, next) => {
  try {
    const owner = await requireFamilyOwner(req);
    res.json({ success: true, ...(await familyPlan.removeMember(owner, req.params.memberId)) });
  } catch (err) { sendErr(res, err, next); }
});

// GET /api/users/me
router.get('/me', async (req, res, next) => {
  try {
    const role = req.user?.role;
    if (role === 'lawyer') {
      const Lawyer = require('../models/Lawyer');
      const lawyer = await Lawyer.findById(req.user.userId);
      if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
      return res.json({ user: lawyer });
    }
    const user = await User.findById(req.user.userId)
      .populate('emergency_events', 'status triggered_at assigned_lawyer_id');
    if (!user) return res.status(404).json({ error: 'User not found.' });
    const u = user.toObject ? user.toObject() : user;
    const isPaymentExempt = user.role === 'admin' || user.manually_added === true;
    res.json({ user: { ...u, is_payment_exempt: isPaymentExempt } });
  } catch (err) { next(err); }
});

// PUT /api/users/me — update profile fields
router.put('/me', async (req, res, next) => {
  try {
    const role = req.user?.role;

    if (role === 'lawyer') {
      const Lawyer = require('../models/Lawyer');
      const allowed = [
        'full_name', 'email', 'phone', 'preferred_language',
        'profile_photo_url', 'is_available', 'whatsapp_number',
        'telegram_username', 'specializations', 'languages_spoken',
        'license_number', 'bar_association', 'response_minutes',
        'schedule', 'settings',
      ];
      const updates = {};
      allowed.forEach((f) => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
      const lawyer = await Lawyer.findByIdAndUpdate(
        req.user.userId, updates, { new: true, runValidators: false }
      );
      if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
      return res.json({ message: 'Profile updated.', user: lawyer });
    }

    // Regular user / admin
    const allowed = [
      'full_name', 'email', 'phone', 'preferred_language',
      'profile_photo_url', 'settings', 'onboarding_completed',
    ];
    const updates = {};
    allowed.forEach((f) => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      updates,
      { new: true, runValidators: false }
    );
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ message: 'Profile updated.', user });
  } catch (err) { next(err); }
});

// PUT /api/users/location — body: { lat, lng }
router.put('/location', async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ error: 'lat and lng are required.' });
    }
    await User.findByIdAndUpdate(req.user.userId, {
      last_location: { type: 'Point', coordinates: [lng, lat] },
    });
    res.json({ message: 'Location updated.' });
  } catch (err) { next(err); }
});

// POST /api/users/push-subscription — Web Push (VAPID) for client users
router.post('/push-subscription', async (req, res, next) => {
  try {
    if (req.user.role === 'lawyer') {
      return res.status(400).json({ error: 'Lawyers use /api/lawyers/push-subscription' });
    }
    const { subscription } = req.body;
    await User.findByIdAndUpdate(req.user.userId, {
      push_subscription: subscription || null,
    });
    res.json({ message: subscription ? 'Push subscription saved.' : 'Push subscription cleared.' });
  } catch (err) { next(err); }
});

// POST /api/users/fcm-token — Firebase Cloud Messaging (mobile)
router.post('/fcm-token', async (req, res, next) => {
  try {
    if (req.user.role === 'lawyer') {
      const { token } = req.body;
      const Lawyer = require('../models/Lawyer');
      await Lawyer.findByIdAndUpdate(req.user.userId, { fcm_token: token || null });
      return res.json({ message: token ? 'FCM token saved.' : 'FCM token cleared.' });
    }
    const { token } = req.body;
    await User.findByIdAndUpdate(req.user.userId, { fcm_token: token || null });
    res.json({ message: token ? 'FCM token saved.' : 'FCM token cleared.' });
  } catch (err) { next(err); }
});

module.exports = router;
