const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const { getAdminSettings, updateFixedOtpSetting } = require('../controllers/admin.controller');

const router = express.Router();

router.use(protect, authorize('admin'));

router.route('/settings')
  .get(getAdminSettings);

router.route('/settings/fixed-otp')
  .put(updateFixedOtpSetting);

module.exports = router;
