// ============================================================
//  payment.routes.js
//  VETO Legal Emergency App
// ============================================================

const router = require('express').Router();
const ctrl = require('../controllers/payment.controller');

// No auth required on create — user pays before/outside auth session
router.post('/subscription', ctrl.createSubscriptionOrder);
router.post('/consultation', ctrl.createConsultationOrder);
router.post('/capture', ctrl.capturePayment);

module.exports = router;
