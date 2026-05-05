// ============================================================
//  Google Calendar OAuth2 + token storage (encrypted)
// ============================================================

const express = require('express');
const { protect } = require('../middleware/auth.middleware');
const gcal = require('../controllers/gcalOAuth.controller');

const router = express.Router();

/** Public — Google redirects here */
router.get('/callback', gcal.oauthCallback);

router.use(protect);
router.get('/status', gcal.status);
router.post('/connect', gcal.connect);
router.post('/disconnect', gcal.disconnect);

module.exports = router;
