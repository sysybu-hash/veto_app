// ============================================================
//  /api/legal-notebook
// ============================================================

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const c = require('../controllers/legalNotebook.controller');

router.use(protect);
router.get('/', c.list);
router.post('/', c.create);
router.get('/:id/open', c.getOpenUrl);
router.post('/:id/sync', c.sync);

module.exports = router;
