// ============================================================
//  call.routes.js — Call Recording & Transcription Routes
//  VETO Legal Emergency App
// ============================================================

const express    = require('express');
const multer     = require('multer');
const router     = express.Router();
const { protect } = require('../middleware/auth.middleware');
const callCtrl   = require('../controllers/call.controller');

// In-memory storage for uploaded recording blobs
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 }, // 200 MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['audio/webm', 'video/webm', 'audio/ogg', 'audio/mp4', 'video/mp4', 'audio/mpeg'];
    if (allowed.includes(file.mimetype) || file.mimetype.startsWith('audio/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error(`Unsupported file type: ${file.mimetype}`));
    }
  },
});

// GET  /api/calls/:eventId          — Get call details
router.get('/:eventId', protect, callCtrl.getCallDetails);

// POST /api/calls/:eventId/recording — Upload recording file
router.post('/:eventId/recording', protect, upload.single('recording'), callCtrl.uploadRecording);

// POST /api/calls/:eventId/transcribe — Transcribe audio with Gemini
router.post('/:eventId/transcribe', protect, callCtrl.transcribeRecording);

module.exports = router;
