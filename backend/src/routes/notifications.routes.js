// ============================================================
//  POST /api/notifications/subscribe  (JWT)
//  Persists Web Push subscription on User or Lawyer.
// ============================================================

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const User = require('../models/User');
const Lawyer = require('../models/Lawyer');

router.use(protect);

router.post('/subscribe', async (req, res, next) => {
  try {
    const { subscription } = req.body;
    const role = req.user.role;
    const id = req.user.userId;

    if (role === 'lawyer') {
      await Lawyer.findByIdAndUpdate(id, {
        push_subscription: subscription || null,
      });
    } else {
      await User.findByIdAndUpdate(id, {
        push_subscription: subscription || null,
      });
    }

    res.json({
      ok: true,
      message: subscription ? 'Push subscription saved.' : 'Push subscription cleared.',
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
