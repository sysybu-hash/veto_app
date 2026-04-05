// ============================================================
//  ai.routes.js
//  VETO Legal Emergency App
//
//  POST /api/ai/chat  → AI legal intake + lawyer matching
// ============================================================

const router    = require('express').Router();
const { aiChat }  = require('../controllers/ai.controller');

router.post('/chat', aiChat);

module.exports = router;
