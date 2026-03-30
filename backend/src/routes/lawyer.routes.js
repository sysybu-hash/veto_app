// ============================================================
//  lawyer.routes.js
//  VETO Legal Emergency App
//
//  GET  /api/lawyers/me           → lawyer profile
//  PUT  /api/lawyers/me           → update profile
//  PUT  /api/lawyers/availability → toggle is_available
//  PUT  /api/lawyers/location     → update GPS location
// ============================================================

const express    = require('express');
const router     = express.Router();
const { protect } = require('../middleware/auth.middleware');
const Lawyer     = require('../models/Lawyer');

router.use(protect);

// ── Guard: only lawyers may use these routes ───────────────
router.use((req, res, next) => {
  if (req.user.role !== 'lawyer') {
    return res.status(403).json({ error: 'Lawyer access only.' });
  }
  next();
});

// GET /api/lawyers/me
router.get('/me', async (req, res, next) => {
  try {
    const lawyer = await Lawyer.findById(req.user.userId)
      .populate('emergency_events', 'status triggered_at user_id');
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ lawyer });
  } catch (err) { next(err); }
});

// PUT /api/lawyers/me
router.put('/me', async (req, res, next) => {
  try {
    const allowed = [
      'full_name', 'email', 'preferred_language', 'languages_spoken',
      'specializations', 'bio', 'whatsapp_number', 'telegram_username',
      'profile_photo_url',
    ];
    const updates = {};
    allowed.forEach((f) => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const lawyer = await Lawyer.findByIdAndUpdate(
      req.user.userId, updates, { new: true, runValidators: true }
    );
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ message: 'Profile updated.', lawyer });
  } catch (err) { next(err); }
});

// PUT /api/lawyers/availability — body: { is_available: true|false }
router.put('/availability', async (req, res, next) => {
  try {
    const { is_available } = req.body;
    if (typeof is_available !== 'boolean') {
      return res.status(400).json({ error: 'is_available must be a boolean.' });
    }
    await Lawyer.findByIdAndUpdate(req.user.userId, { is_available });
    res.json({ message: `Availability set to ${is_available}.` });
  } catch (err) { next(err); }
});

// PUT /api/lawyers/location — body: { lat, lng }
router.put('/location', async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ error: 'lat and lng are required.' });
    }
    await Lawyer.findByIdAndUpdate(req.user.userId, {
      last_location: { type: 'Point', coordinates: [lng, lat] },
    });
    res.json({ message: 'Location updated.' });
  } catch (err) { next(err); }
});

module.exports = router;
