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
const EmergencyEvent = require('../models/EmergencyEvent');

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

router.get('/cockpit', async (req, res, next) => {
  try {
    const lawyer = await Lawyer.findById(req.user.userId)
      .select('full_name is_available is_online is_approved specializations languages_spoken total_cases_handled rating trust response_minutes')
      .lean();
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });

    const events = await EmergencyEvent.find({ assigned_lawyer_id: req.user.userId })
      .select('user_id status call_type triggered_at accepted_at completed_at call_transcript recording_url screen_recording_url charge_status')
      .populate('user_id', 'full_name phone preferred_language')
      .sort({ triggered_at: -1 })
      .limit(20)
      .lean();

    const active = events.find((event) => ['accepted', 'in_progress'].includes(event.status));
    const handledCount = events.filter((event) => event.status === 'completed').length;
    const acceptedWithTimes = events.filter((event) => event.accepted_at && event.triggered_at);
    const avgResponseSeconds = acceptedWithTimes.length
      ? Math.round(
          acceptedWithTimes.reduce((sum, event) => {
            return sum + Math.max(0, new Date(event.accepted_at).getTime() - new Date(event.triggered_at).getTime()) / 1000;
          }, 0) / acceptedWithTimes.length,
        )
      : null;

    res.json({
      lawyer,
      status: {
        busy: !!active,
        activeEventId: active?._id || null,
        handledCount: lawyer.total_cases_handled || handledCount,
        avgResponseSeconds,
      },
      recentEvents: events.map((event) => ({
        id: event._id,
        status: event.status,
        callType: event.call_type,
        triggeredAt: event.triggered_at,
        completedAt: event.completed_at,
        citizen: event.user_id ? {
          id: event.user_id._id,
          name: event.user_id.full_name,
          phone: event.user_id.phone,
          language: event.user_id.preferred_language,
        } : null,
        hasTranscript: !!event.call_transcript,
        hasRecording: !!event.recording_url || !!event.screen_recording_url,
        chargeStatus: event.charge_status,
      })),
    });
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
      last_seen: new Date(),
    });
    res.json({ message: 'Location updated.' });
  } catch (err) { next(err); }
});

// POST /api/lawyers/push-subscription
// Saves (or clears) the browser push subscription for this lawyer.
// Body: { subscription: <PushSubscription object> | null }
router.post('/push-subscription', async (req, res, next) => {
  try {
    const { subscription } = req.body;
    await Lawyer.findByIdAndUpdate(req.user.userId, {
      push_subscription: subscription || null,
    });
    res.json({ message: subscription ? 'Push subscription saved.' : 'Push subscription cleared.' });
  } catch (err) { next(err); }
});

module.exports = router;
