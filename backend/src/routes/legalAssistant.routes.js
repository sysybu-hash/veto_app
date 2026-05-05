const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const { contextChat } = require('../controllers/legalAssistant.controller');

const router = express.Router();

router.post('/context-chat', protect, authorize('user', 'lawyer', 'admin'), contextChat);

module.exports = router;

