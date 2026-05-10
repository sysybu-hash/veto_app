// ============================================================
//  payment.routes.js
//  VETO Legal Emergency App
// ============================================================

const router = require('express').Router();
const ctrl = require('../controllers/payment.controller');
const { protect } = require('../middleware/auth.middleware');

// Plan checkout — demo activates immediately, paid plans return PayPal approveUrl.
router.post('/plan', protect, ctrl.createPlanOrder);
router.post('/consultation', protect, ctrl.createConsultationOrder);
router.post('/overtime', protect, ctrl.createOvertimeOrder);
router.post('/capture', protect, ctrl.capturePayment);
router.get('/me/plan', protect, ctrl.getMyPlan);

// Legacy alias — older clients call /subscription. Maps to standard plan.
router.post('/subscription', protect, ctrl.createSubscriptionOrder);

module.exports = router;
