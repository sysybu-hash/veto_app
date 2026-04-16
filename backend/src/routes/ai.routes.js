// ============================================================
//  ai.routes.js
//  VETO Legal Emergency App
//
//  POST /api/ai/chat  → AI legal intake + lawyer matching
// ============================================================

const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const { aiChat } = require('../controllers/ai.controller');
const { protect } = require('../middleware/auth.middleware');

// Stricter than global /api limiter — AI calls Gemini and burns quota.
const aiChatLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many AI requests. Please wait a minute and try again.' },
});

// Browsers open URLs with GET — show a clear hint instead of Express default "Cannot GET".
router.get('/chat', (_req, res) => {
  res.status(200).json({
    ok: true,
    path: '/api/ai/chat',
    method: 'POST',
    hint: 'This endpoint expects JSON POST from the app, not a browser GET.',
    body: { message: 'string', history: [], lang: 'he' },
  });
});

router.post('/chat', aiChatLimiter, protect, aiChat);

module.exports = router;
