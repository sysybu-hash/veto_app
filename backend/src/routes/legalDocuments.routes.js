const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const {
  generateDraft,
  exportDraft,
} = require('../controllers/legalDocuments.controller');

const router = express.Router();

router.post('/generate', protect, authorize('user', 'lawyer', 'admin'), generateDraft);
router.post('/export', protect, authorize('user', 'lawyer', 'admin'), exportDraft);

module.exports = router;

