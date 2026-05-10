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

const { PLANS } = require('../config/pricing');

router.use(protect);
router.use(requireValidMongoUserId);

// ── Family group: owner adds a member by phone (must already be a registered user).
router.post('/family/invite', async (req, res, next) => {
  try {
    const owner = await User.findById(req.user.userId);
    if (!owner) return res.status(404).json({ error: 'Owner not found.' });
    if (owner.subscription_plan !== 'family') {
      return res.status(403).json({ error: 'Only the family plan owner can add members.' });
    }
    const expired = owner.subscription_expiry && owner.subscription_expiry < new Date();
    if (expired) return res.status(403).json({ error: 'Family plan expired.' });
    if (String(owner.family_owner_id) !== String(owner._id)) {
      return res.status(403).json({ error: 'You are not the family plan owner.' });
    }

    const phone = (req.body?.phone || '').toString().trim();
    if (!phone) return res.status(400).json({ error: 'phone is required.' });

    const target = await User.findOne({ phone });
    if (!target) return res.status(404).json({ error: 'User with that phone is not registered.' });
    if (String(target._id) === String(owner._id)) {
      return res.status(400).json({ error: 'Owner is already part of the plan.' });
    }
    if (target.family_owner_id && String(target.family_owner_id) !== String(owner._id)) {
      return res.status(409).json({ error: 'User is already linked to another family plan.' });
    }

    const seats = PLANS.family.familySeats;
    const memberCount = await User.countDocuments({ family_owner_id: owner._id });
    if (memberCount >= seats) {
      return res.status(409).json({ error: `Family plan limited to ${seats} members.` });
    }

    target.family_owner_id = owner._id;
    target.subscription_plan = 'family';
    target.is_subscribed = true;
    target.subscription_expiry = owner.subscription_expiry;
    await target.save();

    res.json({ success: true, memberId: target._id });
  } catch (err) { next(err); }
});

router.get('/family', async (req, res, next) => {
  try {
    const me = await User.findById(req.user.userId).select('subscription_plan family_owner_id subscription_expiry');
    if (!me) return res.status(404).json({ error: 'Not found' });
    const ownerId = me.family_owner_id || (me.subscription_plan === 'family' ? me._id : null);
    if (!ownerId) return res.json({ owner: null, members: [] });
    const owner = await User.findById(ownerId).select('full_name phone subscription_expiry');
    const members = await User.find({ family_owner_id: ownerId, _id: { $ne: ownerId } })
      .select('full_name phone _id');
    res.json({
      isOwner: String(ownerId) === String(me._id),
      owner: owner ? { id: owner._id, name: owner.full_name, phone: owner.phone, expiry: owner.subscription_expiry } : null,
      members: members.map((m) => ({ id: m._id, name: m.full_name, phone: m.phone })),
      seats: PLANS.family.familySeats,
    });
  } catch (err) { next(err); }
});

router.delete('/family/:memberId', async (req, res, next) => {
  try {
    const owner = await User.findById(req.user.userId);
    if (!owner || owner.subscription_plan !== 'family' ||
        String(owner.family_owner_id) !== String(owner._id)) {
      return res.status(403).json({ error: 'Only the family plan owner can remove members.' });
    }
    const target = await User.findById(req.params.memberId);
    if (!target) return res.status(404).json({ error: 'Member not found' });
    if (String(target.family_owner_id) !== String(owner._id)) {
      return res.status(409).json({ error: 'User is not in your family plan.' });
    }
    target.family_owner_id = null;
    target.subscription_plan = null;
    target.is_subscribed = false;
    target.subscription_expiry = null;
    await target.save();
    res.json({ success: true });
  } catch (err) { next(err); }
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
