// ============================================================
//  payment.routes.js
//  VETO Legal Emergency App
// ============================================================

const router = require('express').Router();
const ctrl = require('../controllers/payment.controller');
const { protect } = require('../middleware/auth.middleware');

// No auth required on create — user starts checkout from the app while logged in
router.post('/subscription', ctrl.createSubscriptionOrder);
router.post('/consultation', ctrl.createConsultationOrder);
router.post('/capture', protect, ctrl.capturePayment);

module.exports = router;
