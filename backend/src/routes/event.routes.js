// ============================================================
//  event.routes.js
//  VETO Legal Emergency App
//
//  All routes are protected by JWT (protect middleware).
//
//  GET  /api/events/history                  → paginated event history
//  GET  /api/events/:eventId                 → full event detail
//  POST /api/events/:eventId/evidence        → add evidence metadata
//  POST /api/events/:eventId/evidence/upload → upload evidence file (Cloudinary)
//  POST /api/events/:eventId/rate            → submit user rating
// ============================================================

const express  = require('express');
const router   = express.Router();
const multer   = require('multer');
const { protect } = require('../middleware/auth.middleware');
const {
  getHistory,
  getEventById,
  addEvidence,
  rateEvent,
} = require('../controllers/event.controller');

// ── Multer storage: Cloudinary if configured, local disk fallback ─
let upload;
if (
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
) {
  const { cloudinaryStorage } = require('../config/cloudinary');
  upload = multer({
    storage: cloudinaryStorage,
    limits: { fileSize: 50 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      const allowed = ['image/', 'video/', 'audio/'];
      if (allowed.some(t => file.mimetype.startsWith(t))) return cb(null, true);
      cb(new Error('Only image, video, or audio files are allowed'));
    },
  });
  console.log('📦 Evidence upload: Cloudinary storage');
} else {
  const path = require('path');
  const fs   = require('fs');
  const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads');
  if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });
  upload = multer({
    storage: multer.diskStorage({
      destination: (req, file, cb) => cb(null, UPLOADS_DIR),
      filename:    (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
    }),
    limits: { fileSize: 50 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
      const allowed = ['image/', 'video/', 'audio/'];
      if (allowed.some(t => file.mimetype.startsWith(t))) return cb(null, true);
      cb(new Error('Only image, video, or audio files are allowed'));
    },
  });
  console.warn('⚠️  Evidence upload: local disk (files lost on server restart). Set CLOUDINARY_* env vars for persistent storage.');
}

// ── All event routes require authentication ────────────────
router.use(protect);

router.get('/history',                         getHistory);
router.get('/:eventId',                        getEventById);
router.post('/:eventId/evidence',              addEvidence);
router.post('/:eventId/rate',                  rateEvent);

// ── File upload: multipart/form-data ──────────────────────
//  Fields: type (photo|video|audio), lat, lng, client_timestamp
//  File key: 'file'
router.post('/:eventId/evidence/upload', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

    const { eventId } = req.params;
    const { type = 'photo', lat, lng, client_timestamp } = req.body;

    // Cloudinary returns req.file.path as the secure URL
    // Local disk returns req.file.filename → build URL from host
    const cloudUrl = req.file.path
      ? req.file.path
      : `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const EmergencyEvent = require('../models/EmergencyEvent');
    const event = await EmergencyEvent.findByIdAndUpdate(
      eventId,
      {
        $push: {
          evidence: {
            type,
            cloud_url: cloudUrl,
            location: lat && lng
              ? { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] }
              : undefined,
            timestamp: client_timestamp ? new Date(client_timestamp) : new Date(),
            file_size: req.file.size,
          },
        },
      },
      { new: true, select: 'evidence' },
    );

    if (!event) return res.status(404).json({ error: 'Event not found.' });

    const saved = event.evidence[event.evidence.length - 1];
    return res.status(201).json({ success: true, cloudUrl, evidence: saved });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
