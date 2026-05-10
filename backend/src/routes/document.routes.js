// ============================================================
//  document.routes.js — /api/documents (M10–11)
// ============================================================

const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const docController = require('../controllers/document.controller');

const router = express.Router();

router.use(protect);
router.use(authorize('user', 'lawyer', 'admin'));

router.post('/generate', docController.generateDocument);
router.post('/:docId/sign', docController.signDocument);
router.post('/:docId/request-signature', docController.requestLawyerSignature);

module.exports = router;
