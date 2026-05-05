const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth.middleware');
const c = require('../controllers/citizenDashboard.controller');

router.use(protect);
router.use(authorize('user'));

router.get('/summary', c.getSummary);
router.get('/reports/summary', c.getReportsSummary);

router.get('/contracts', c.listContracts);
router.post('/contracts', c.createContract);
router.patch('/contracts/:id', c.updateContract);
router.delete('/contracts/:id', c.deleteContract);

router.get('/tasks', c.listTasks);
router.post('/tasks', c.createTask);
router.patch('/tasks/:id', c.updateTask);
router.delete('/tasks/:id', c.deleteTask);

router.get('/contacts', c.listContacts);
router.post('/contacts', c.createContact);
router.patch('/contacts/:id', c.updateContact);
router.delete('/contacts/:id', c.deleteContact);

router.get('/notifications', c.listNotifications);
router.post('/notifications', c.createNotification);
router.patch('/notifications/:id/read', c.markNotificationRead);

module.exports = router;
