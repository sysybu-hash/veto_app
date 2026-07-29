const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const { renderDocument } = require('../controllers/documentRender.controller');

const router = express.Router();

router.post('/', protect, authorize('user', 'lawyer', 'admin'), renderDocument);

module.exports = router;
