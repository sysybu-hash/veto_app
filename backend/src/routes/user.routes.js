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

module.exports = router;
