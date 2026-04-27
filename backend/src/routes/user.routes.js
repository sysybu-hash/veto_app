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
const { protect } = require('../middleware/auth.middleware');
const User       = require('../models/User');

router.use(protect);

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
    res.json({ user });
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
      'profile_photo_url', 'settings',
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
