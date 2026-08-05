const express = require('express');
const { protect, authorize } = require('../middleware/auth.middleware');
const {
  getAdminSettings, updateFixedOtpSetting, getDashboardStats,
  updateEuComplianceMode,
  getAllUsers, createUser, updateUser, deleteUser,
  getAllLawyers, createLawyer, updateLawyer, deleteLawyer,
  getPendingLawyers, approveLawyer, rejectLawyer,
  getEmergencyLogs, updateEmergencyLog, deleteEmergencyLog,
  getLoginLogs, getAuditLogs, getSystemHealth, getAllUsersWithStatus,
  getFinanceReport, emailFinanceReport,
} = require('../controllers/admin.controller');
const {
  getLawyerPayoutSettings,
  syncLawyerEarnings,
  listLawyerFinance,
  listLawyerEarnings,
  updateLawyerPayoutProfile,
  createLawyerPayout,
  markLawyerPayoutPaid,
  cancelLawyerPayout,
  listLawyerPayoutBatches,
  exportLawyerEarningsCsv,
} = require('../controllers/adminFinance.controller');

const router = express.Router();
router.use(protect, authorize('admin'));

router.route('/settings').get(getAdminSettings);
router.route('/settings/fixed-otp').put(updateFixedOtpSetting);
router.route('/settings/eu-compliance').put(updateEuComplianceMode);
router.get('/system-health', getSystemHealth);

router.route('/users').get(getAllUsers).post(createUser);
router.route('/users/:id').put(updateUser).delete(deleteUser);

router.route('/lawyers').get(getAllLawyers).post(createLawyer);
router.get('/lawyers/pending', getPendingLawyers);
router.put('/lawyers/:id/approve', approveLawyer);
router.delete('/lawyers/:id/reject', rejectLawyer);
router.route('/lawyers/:id').put(updateLawyer).delete(deleteLawyer);

router.get('/emergency-logs', getEmergencyLogs);
router.route('/emergency-logs/:id').put(updateEmergencyLog).delete(deleteEmergencyLog);

// ── New endpoints ──────────────────────────────────────────────
router.get('/login-logs', getLoginLogs);
router.get('/audit-logs', getAuditLogs);
router.get('/users-with-status', getAllUsersWithStatus);

// Subscriptions endpoint — returns all users with sub status (for SubscriptionAdminScreen)
router.get('/subscriptions', getAllUsersWithStatus);

// Dashboard KPI stats + live emergency events (Mission 8 command center)
router.get('/stats', getDashboardStats);

// Finance management + report email
router.get('/finance/report', getFinanceReport);
router.post('/finance/email-report', emailFinanceReport);

// Lawyer payouts (activity-based)
router.get('/finance/payout-settings', getLawyerPayoutSettings);
router.post('/finance/lawyer-earnings/sync', syncLawyerEarnings);
router.get('/finance/lawyers', listLawyerFinance);
router.get('/finance/lawyers/:lawyerId/earnings', listLawyerEarnings);
router.patch('/finance/lawyers/:lawyerId/payout-profile', updateLawyerPayoutProfile);
router.get('/finance/lawyer-earnings/export', exportLawyerEarningsCsv);
router.get('/finance/payouts', listLawyerPayoutBatches);
router.post('/finance/payouts', createLawyerPayout);
router.patch('/finance/payouts/:batchId/paid', markLawyerPayoutPaid);
router.patch('/finance/payouts/:batchId/cancel', cancelLawyerPayout);

module.exports = router;
