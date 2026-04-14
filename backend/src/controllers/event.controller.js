// ============================================================
//  event.controller.js — Emergency Event Controller
//  VETO Legal Emergency App
// ============================================================

const EmergencyEvent = require('../models/EmergencyEvent');

// ── Pagination defaults ────────────────────────────────────
const DEFAULT_PAGE  = 1;
const DEFAULT_LIMIT = 20;

// ============================================================
//  GET /events/history
//  Protected. Returns paginated past events for the caller.
//  Users see their own events; lawyers see cases they handled.
//  Query params: ?page=1&limit=20&status=completed
// ============================================================
const getHistory = async (req, res, next) => {
  try {
    const { userId, role }  = req.user;
    const page   = Math.max(1, parseInt(req.query.page)  || DEFAULT_PAGE);
    const limit  = Math.min(50, parseInt(req.query.limit) || DEFAULT_LIMIT);
    const skip   = (page - 1) * limit;
    const status = req.query.status; // optional filter

    // ── Build query filter ───────────────────────────────
    const filter = role === 'lawyer'
      ? { assigned_lawyer_id: userId }
      : { user_id: userId };

    if (status) filter.status = status;

    // ── Query ────────────────────────────────────────────
    const [events, total] = await Promise.all([
      EmergencyEvent.find(filter)
        .sort({ triggered_at: -1 })           // newest first
        .skip(skip)
        .limit(limit)
        .populate('user_id',            'full_name phone preferred_language')
        .populate('assigned_lawyer_id', 'full_name phone whatsapp_number telegram_username')
        .select('-dispatch_attempts'),         // omit bulky dispatch log in list view
      EmergencyEvent.countDocuments(filter),
    ]);

    return res.status(200).json({
      page,
      limit,
      total,
      pages:  Math.ceil(total / limit),
      events,
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  GET /events/:eventId
//  Protected. Full event detail — lawyer, evidence, dispatch log.
//  Only the owning user OR the assigned lawyer may access it.
// ============================================================
const getEventById = async (req, res, next) => {
  try {
    const { userId } = req.user;
    const { eventId } = req.params;

    const event = await EmergencyEvent.findById(eventId)
      .populate('user_id',            'full_name phone email preferred_language last_location')
      .populate('assigned_lawyer_id', 'full_name phone whatsapp_number telegram_username rating specializations')
      .populate('dispatch_attempts.lawyer_id', 'full_name phone');

    if (!event) {
      return res.status(404).json({ error: 'Event not found.' });
    }

    // ── Access control ───────────────────────────────────
    const isOwner    = event.user_id?._id?.toString() === userId.toString();
    const isLawyer   = event.assigned_lawyer_id?._id?.toString() === userId.toString();

    if (!isOwner && !isLawyer) {
      return res.status(403).json({ error: 'Access denied.' });
    }

    return res.status(200).json({ event });
  } catch (err) {
    // Invalid ObjectId format
    if (err.name === 'CastError') {
      return res.status(400).json({ error: 'Invalid event ID.' });
    }
    next(err);
  }
};

// ============================================================
//  POST /events/:eventId/evidence
//  Protected (user only). Add an evidence item to an event.
//  Body: { type, cloud_url, gps_location: { lat, lng }, duration_seconds?, file_size_bytes? }
//  (In production, upload happens client-side to S3/Cloudinary,
//   client sends the resulting URL here.)
// ============================================================
const addEvidence = async (req, res, next) => {
  try {
    const { userId }  = req.user;
    const { eventId } = req.params;
    const {
      type,
      cloud_url,
      gps_location,
      duration_seconds,
      file_size_bytes,
    } = req.body;

    if (!type || !cloud_url) {
      return res.status(400).json({ error: 'type and cloud_url are required.' });
    }

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found.' });

    if (event.user_id.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Only the event owner may add evidence.' });
    }

    const evidenceItem = {
      type,
      cloud_url,
      timestamp: new Date(),
      ...(gps_location && {
        gps_location: {
          type:        'Point',
          coordinates: [gps_location.lng, gps_location.lat],
        },
      }),
      ...(duration_seconds  !== undefined && { duration_seconds }),
      ...(file_size_bytes   !== undefined && { file_size_bytes }),
    };

    event.evidence.push(evidenceItem);
    await event.save();

    return res.status(201).json({
      message:  'Evidence added.',
      evidence: evidenceItem,
    });
  } catch (err) {
    next(err);
  }
};

// ============================================================
//  POST /events/:eventId/rate
//  Protected (user only). Submit a rating after the call.
//  Body: { score: 1-5, comment? }
// ============================================================
const rateEvent = async (req, res, next) => {
  try {
    const { userId }  = req.user;
    const { eventId } = req.params;
    const { score, comment = '' } = req.body;

    if (!score || score < 1 || score > 5) {
      return res.status(400).json({ error: 'score must be between 1 and 5.' });
    }

    const event = await EmergencyEvent.findById(eventId);
    if (!event) return res.status(404).json({ error: 'Event not found.' });

    if (event.user_id.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Only the event owner may rate it.' });
    }

    if (event.status !== 'completed') {
      return res.status(400).json({ error: 'Can only rate completed events.' });
    }

    event.user_rating = { score, comment };
    await event.save();

    // ── Update lawyer's aggregate rating ─────────────────
    if (event.assigned_lawyer_id) {
      const Lawyer = require('../models/Lawyer');
      const lawyer = await Lawyer.findById(event.assigned_lawyer_id);
      if (lawyer) {
        const prev    = lawyer.rating;
        const newCount = prev.count + 1;
        const newAvg   = ((prev.average * prev.count) + score) / newCount;
        lawyer.rating  = { average: Math.round(newAvg * 10) / 10, count: newCount };
        await lawyer.save();
      }
    }

    return res.status(200).json({ message: 'Rating submitted. Thank you!' });
  } catch (err) {
    next(err);
  }
};

module.exports = { getHistory, getEventById, addEvidence, rateEvent };
