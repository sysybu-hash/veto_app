// ============================================================
//  ai.routes.js
//  VETO Legal Emergency App
//
//  POST /api/ai/chat  → AI legal intake + lawyer matching
// ============================================================

const router    = require('express').Router();
const { protect } = require('../middleware/auth.middleware');
const { aiChat }  = require('../controllers/ai.controller');

router.post('/chat', protect, aiChat);

module.exports = router;
