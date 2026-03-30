// ============================================================
//  event.routes.js
//  VETO Legal Emergency App
//
//  All routes are protected by JWT (protect middleware).
//
//  GET  /api/events/history           → paginated event history
//  GET  /api/events/:eventId          → full event detail
//  POST /api/events/:eventId/evidence → add evidence item
//  POST /api/events/:eventId/rate     → submit user rating
// ============================================================

const express  = require('express');
const router   = express.Router();
const { protect } = require('../middleware/auth.middleware');
const {
  getHistory,
  getEventById,
  addEvidence,
  rateEvent,
} = require('../controllers/event.controller');

// ── All event routes require authentication ────────────────
router.use(protect);

router.get('/history',                getHistory);
router.get('/:eventId',               getEventById);
router.post('/:eventId/evidence',     addEvidence);
router.post('/:eventId/rate',         rateEvent);

module.exports = router;
