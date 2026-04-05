const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const {
  getAdminSettings, updateFixedOtpSetting,
  getAllUsers, createUser, updateUser, deleteUser,
  getAllLawyers, createLawyer, updateLawyer, deleteLawyer,
  getPendingLawyers, approveLawyer, rejectLawyer,
  getEmergencyLogs, updateEmergencyLog, deleteEmergencyLog,
} = require('../controllers/admin.controller');

const router = express.Router();
router.use(protect, authorize('admin'));

router.route('/settings').get(getAdminSettings);
router.route('/settings/fixed-otp').put(updateFixedOtpSetting);

router.route('/users').get(getAllUsers).post(createUser);
router.route('/users/:id').put(updateUser).delete(deleteUser);

router.route('/lawyers').get(getAllLawyers).post(createLawyer);
router.get('/lawyers/pending', getPendingLawyers);
router.put('/lawyers/:id/approve', approveLawyer);
router.delete('/lawyers/:id/reject', rejectLawyer);
router.route('/lawyers/:id').put(updateLawyer).delete(deleteLawyer);

router.get('/emergency-logs', getEmergencyLogs);
router.route('/emergency-logs/:id').put(updateEmergencyLog).delete(deleteEmergencyLog);

module.exports = router;