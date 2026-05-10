const express = require('express');
const router = express.Router();
const healthController = require('../controllers/health.controller');

// Public route for uptime monitoring (Render cron jobs) and deployment verification
router.get('/', healthController.getHealthStatus);

module.exports = router;
