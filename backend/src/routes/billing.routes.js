// ============================================================
//  billing.routes.js — /api/billing (Mission 12)
// ============================================================

const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const billingController = require('../controllers/billing.controller');

const router = express.Router();

router.use(protect);
router.use(authorize('user', 'admin'));

router.post('/create-order', billingController.createOrder);
router.post('/capture-order', billingController.captureOrder);

module.exports = router;
