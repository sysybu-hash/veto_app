// ============================================================
//  P4: Google Calendar OAuth2 (two-way sync) — not implemented
//  Needs user OAuth consent, refresh token storage, conflict resolution.
// ============================================================

const express = require('express');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();
router.use(protect);

router.get('/status', (req, res) => {
  res.status(501).json({
    enabled: false,
    message: 'Google Calendar two-way sync is not enabled on this server.',
    hint: 'Requires app OAuth client, encrypted refresh_token storage, and background sync job.',
  });
});

module.exports = router;
