// ============================================================
//  /api/calendar  (JWT) —  export.ics is mounted separately
// ============================================================

const express = require('express');
const router = express.Router();
const cal = require('../controllers/calendar.controller');
const { protect } = require('../middleware/auth.middleware');

router.use(protect);
router.get('/events', cal.listEvents);
router.get('/feed', cal.getFeedInfo);
router.get('/events/:id', cal.getOne);
router.post('/events', cal.createEvent);
router.put('/events/:id', cal.updateEvent);
router.delete('/events/:id', cal.deleteEvent);

module.exports = router;
