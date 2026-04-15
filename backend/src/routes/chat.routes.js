// ============================================================
//  chat.routes.js — Real-time messaging between users and lawyers
// ============================================================

const express  = require('express');
const { protect } = require('../middleware/auth.middleware');
const Message  = require('../models/Message');
const User     = require('../models/User');
const Lawyer   = require('../models/Lawyer');

const router = express.Router();
router.use(protect);

// ──────────────────────────────────────────────────────────────
// GET /api/chat/conversations
// Returns list of conversation partners with last message + unread count
// ──────────────────────────────────────────────────────────────
router.get('/conversations', async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const [sent, received] = await Promise.all([
      Message.find({ sender_id: userId }).distinct('receiver_id'),
      Message.find({ receiver_id: userId }).distinct('sender_id'),
    ]);
    const ids = [...new Set([...sent.map(String), ...received.map(String)])];

    const conversations = await Promise.all(ids.map(async (pid) => {
      const [lastMsg, unread, u, l] = await Promise.all([
        Message.findOne({
          $or: [
            { sender_id: userId, receiver_id: pid },
            { sender_id: pid,    receiver_id: userId },
          ],
        }).sort({ createdAt: -1 }),
        Message.countDocuments({ sender_id: pid, receiver_id: userId, read: false }),
        User.findById(pid).select('full_name role phone'),
        Lawyer.findById(pid).select('full_name phone'),
      ]);
      const partner = u || l;
      return {
        partner_id:      pid,
        partner_name:    partner?.full_name || 'Unknown',
        partner_role:    u ? (u.role || 'user') : 'lawyer',
        last_message:    lastMsg?.text || '',
        last_message_at: lastMsg?.createdAt || null,
        unread_count:    unread,
      };
    }));

    const sorted = conversations.sort(
      (a, b) => new Date(b.last_message_at || 0) - new Date(a.last_message_at || 0),
    );
    res.json({ conversations: sorted });
  } catch (err) { next(err); }
});

// ──────────────────────────────────────────────────────────────
// GET /api/chat/messages/:partnerId?page=1
// ──────────────────────────────────────────────────────────────
router.get('/messages/:partnerId', async (req, res, next) => {
  try {
    const userId    = req.user.userId;
    const partnerId = req.params.partnerId;
    const page      = Math.max(1, parseInt(req.query.page) || 1);
    const LIMIT     = 50;

    const messages = await Message.find({
      $or: [
        { sender_id: userId,    receiver_id: partnerId },
        { sender_id: partnerId, receiver_id: userId },
      ],
    })
      .sort({ createdAt: -1 })
      .skip((page - 1) * LIMIT)
      .limit(LIMIT);

    // Mark incoming as read
    await Message.updateMany(
      { sender_id: partnerId, receiver_id: userId, read: false },
      { read: true },
    );

    res.json({ messages: messages.reverse() });
  } catch (err) { next(err); }
});

// ──────────────────────────────────────────────────────────────
// POST /api/chat/messages
// Body: { receiver_id, receiver_role, text, event_id?, attachments? }
// ──────────────────────────────────────────────────────────────
router.post('/messages', async (req, res, next) => {
  try {
    const { receiver_id, receiver_role, text, event_id, attachments } = req.body;

    if (!receiver_id || !text?.trim()) {
      return res.status(400).json({ error: 'receiver_id and text are required.' });
    }
    if (text.length > 4000) {
      return res.status(400).json({ error: 'Message too long (max 4000 chars).' });
    }

    const msg = await Message.create({
      sender_id:    req.user.userId,
      sender_role:  req.user.role,
      receiver_id,
      receiver_role: receiver_role || 'user',
      text:         text.trim(),
      event_id:     event_id  || null,
      attachments:  attachments || [],
    });

    // Real-time push via Socket.io (rooms match dispatch.socket.js joins)
    const io = req.app.get('io');
    if (io) {
      const rRole = String(receiver_role || 'user').toLowerCase();
      const room =
        rRole === 'lawyer' ? `lawyer:${receiver_id}` : `user:${receiver_id}`;
      io.to(room).emit('new_message', {
        message:     msg,
        sender_name: req.user.full_name || 'User',
      });
    }

    res.status(201).json({ message: msg });
  } catch (err) { next(err); }
});

// ──────────────────────────────────────────────────────────────
// DELETE /api/chat/messages/:id  (sender only)
// ──────────────────────────────────────────────────────────────
router.delete('/messages/:id', async (req, res, next) => {
  try {
    const msg = await Message.findOneAndDelete({
      _id:       req.params.id,
      sender_id: req.user.userId,
    });
    if (!msg) return res.status(404).json({ error: 'Message not found.' });
    res.json({ message: 'Deleted.' });
  } catch (err) { next(err); }
});

// ──────────────────────────────────────────────────────────────
// GET /api/chat/partners  (admin: list users you can message + all lawyers)
// ──────────────────────────────────────────────────────────────
router.get('/partners', async (req, res, next) => {
  try {
    const role = req.user.role;
    let partners = [];
    if (role === 'lawyer' || role === 'admin') {
      const users = await User.find({ is_active: true }).select('full_name phone role');
      partners = users.map(u => ({ id: u._id, name: u.full_name, role: u.role || 'user' }));
    } else {
      const lawyers = await Lawyer.find({ is_approved: true, is_active: true }).select('full_name phone');
      partners = lawyers.map(l => ({ id: l._id, name: l.full_name, role: 'lawyer' }));
    }
    res.json({ partners });
  } catch (err) { next(err); }
});

module.exports = router;
