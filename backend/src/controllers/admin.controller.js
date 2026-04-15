const User    = require('../models/User');
const Lawyer  = require('../models/Lawyer');
const Event   = require('../models/EmergencyEvent');

/**
 * Normalise a raw phone string to E.164 (+972XXXXXXXXX).
 * Handles: 0501234567 → +972501234567, 972501234567 → +972501234567, already E.164 → unchanged.
 */
function normalizePhone(raw) {
  if (!raw) return raw;
  const trimmed = raw.trim();
  if (trimmed.startsWith('+')) return trimmed;
  const digits = trimmed.replace(/\D/g, '');
  if (digits.startsWith('972')) return '+' + digits;
  if (digits.startsWith('0'))   return '+972' + digits.slice(1);
  return '+972' + digits;
}

const getAdminSettings = async (req, res, next) => {
  try {
    const enableFixedOtpForAdmins = process.env.ENABLE_FIXED_OTP_FOR_ADMINS === 'true';
    
    res.status(200).json({
      enableFixedOtpForAdmins,
      serverStatus: 'Online',
      mongoDbStatus: 'Connected',
      appVersion: 'v1.2.4',
    });
  } catch (err) {
    next(err);
  }
};

const getAdminStats = async (req, res, next) => {
  try {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek  = new Date(now); startOfWeek.setDate(now.getDate() - 6);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalUsers,
      activeLawyers,
      pendingLawyers,
      eventsToday,
      eventsWeek,
      eventsMonth,
    ] = await Promise.all([
      User.countDocuments({}),
      Lawyer.countDocuments({ is_active: true }),
      Lawyer.countDocuments({ is_approved: false, is_active: true }),
      Event.countDocuments({ triggered_at: { $gte: startOfToday } }),
      Event.countDocuments({ triggered_at: { $gte: startOfWeek } }),
      Event.countDocuments({ triggered_at: { $gte: startOfMonth } }),
    ]);

    res.json({ totalUsers, activeLawyers, pendingLawyers, eventsToday, eventsWeek, eventsMonth });
  } catch (err) { next(err); }
};

const updateFixedOtpSetting = async (req, res, next) => {
  try {
    const { enable } = req.body;
    if (typeof enable !== 'boolean') {
      return res.status(400).json({ error: 'Invalid value for enable. Must be a boolean.' });
    }
    process.env.ENABLE_FIXED_OTP_FOR_ADMINS = enable.toString();
    console.log(`[ADMIN] ENABLE_FIXED_OTP_FOR_ADMINS set to: ${enable}`);
    res.status(200).json({ message: 'Fixed OTP setting updated successfully.', enableFixedOtpForAdmins: enable });
  } catch (err) {
    next(err);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.find({}).select('full_name phone role is_verified is_subscribed subscription_expiry manually_added is_active preferred_language createdAt').sort({ createdAt: -1 });
    res.json({ users });
  } catch (err) { next(err); }
};

const createUser = async (req, res, next) => {
  try {
    const { full_name, role, preferred_language } = req.body;
    const phone = normalizePhone(req.body.phone);
    if (!full_name || !phone) return res.status(400).json({ error: 'full_name and phone are required.' });
    const user = await User.create({
      full_name, phone,
      role: role || 'user',
      preferred_language: preferred_language || 'he',
      is_verified: true,
      manually_added: true,   // admin-created users are payment-exempt
    });
    res.status(201).json({ user });
  } catch (err) { next(err); }
};

const updateUser = async (req, res, next) => {
  try {
    const allowed = ['full_name', 'phone', 'role', 'preferred_language', 'email', 'is_verified', 'manually_added', 'is_subscribed', 'is_active', 'subscription_expiry'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    if (updates.phone) updates.phone = normalizePhone(updates.phone);

    if (req.body.extendDays !== undefined) {
      const days = Number(req.body.extendDays);
      if (Number.isFinite(days) && days !== 0) {
        const u = await User.findById(req.params.id).select('subscription_expiry');
        if (!u) return res.status(404).json({ error: 'User not found.' });
        const base =
          u.subscription_expiry && u.subscription_expiry > new Date()
            ? new Date(u.subscription_expiry)
            : new Date();
        updates.subscription_expiry = new Date(base.getTime() + days * 86400000);
      }
    }

    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ user });
  } catch (err) { next(err); }
};

const deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ message: 'User deleted.' });
  } catch (err) { next(err); }
};

const getAllLawyers = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyers = await Lawyer.find({}).select('full_name phone email is_available is_verified is_approved is_active createdAt specializations license_number years_of_experience').sort({ createdAt: -1 });
    res.json({ lawyers });
  } catch (err) { next(err); }
};

const getPendingLawyers = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyers = await Lawyer.find({ is_approved: false }).select('full_name phone email specializations license_number years_of_experience createdAt').sort({ createdAt: -1 });
    res.json({ lawyers });
  } catch (err) { next(err); }
};

const approveLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndUpdate(
      req.params.id,
      { is_approved: true },
      { new: true }
    );
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ lawyer, message: '\u05e2\u05d5\u05e8\u05da \u05d4\u05d3\u05d9\u05df \u05d0\u05d5\u05e9\u05e8 \u05d1\u05d4\u05e6\u05dc\u05d7\u05d4.' });
  } catch (err) { next(err); }
};

const rejectLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndDelete(req.params.id);
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ message: '\u05e2\u05d5\u05e8\u05da \u05d4\u05d3\u05d9\u05df \u05e0\u05d3\u05d7\u05d4.' });
  } catch (err) { next(err); }
};

const createLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const { full_name, phone, email, license_number, specializations, years_of_experience } = req.body;
    if (!full_name || !phone) {
      return res.status(400).json({ error: 'full_name and phone are required.' });
    }
    const lawyer = await Lawyer.create({
      full_name, phone, email: email || null,
      license_number: license_number || null,
      specializations: specializations || [],
      years_of_experience: years_of_experience || 0,
      is_verified: true,
      is_approved: true,  // admin-created lawyers are pre-approved
    });
    res.status(201).json({ lawyer });
  } catch (err) { next(err); }
};

const updateLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const allowed = ['full_name', 'phone', 'email', 'is_available', 'is_verified', 'specializations', 'license_number', 'years_of_experience', 'bio'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    const lawyer = await Lawyer.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ lawyer });
  } catch (err) { next(err); }
};

const deleteLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndDelete(req.params.id);
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    res.json({ message: 'Lawyer deleted.' });
  } catch (err) { next(err); }
};

// ── Login attempt logs ────────────────────────────────────────
const getLoginLogs = async (req, res, next) => {
  try {
    const LoginLog = require('../models/LoginLog');
    const limit = Math.min(parseInt(req.query.limit) || 200, 500);
    const page  = Math.max(1, parseInt(req.query.page) || 1);
    const logs  = await LoginLog.find({})
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);
    const total = await LoginLog.countDocuments();
    res.json({ logs, total, page, limit });
  } catch (err) { next(err); }
};

// ── All users with subscription status (for admin users+subs page) ───
const getAllUsersWithStatus = async (req, res, next) => {
  try {
    const users = await User.find({})
      .select('full_name phone email role is_verified is_subscribed subscription_expiry manually_added is_active preferred_language createdAt')
      .sort({ createdAt: -1 });

    const enriched = users.map((u) => {
      let status = 'unverified';
      if (u.manually_added) status = 'free';
      else if (u.is_subscribed) {
        const expired = u.subscription_expiry && u.subscription_expiry < new Date();
        status = expired ? 'expired' : 'active';
      } else if (u.is_verified) {
        status = 'no_subscription';
      }
      return {
        _id:                u._id,
        full_name:          u.full_name,
        phone:              u.phone,
        email:              u.email,
        role:               u.role,
        is_verified:        u.is_verified,
        is_subscribed:      u.is_subscribed,
        manually_added:     u.manually_added,
        subscription_expiry:u.subscription_expiry,
        is_active:          u.is_active,
        preferred_language: u.preferred_language,
        createdAt:          u.createdAt,
        computed_status:    status,
      };
    });
    res.json({ users: enriched });
  } catch (err) { next(err); }
};

const getEmergencyLogs = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const events = await Event.find({}).sort({ triggered_at: -1 }).limit(100)
      .populate('user_id', 'full_name phone')
      .populate('assigned_lawyer_id', 'full_name phone');
    res.json({ events });
  } catch (err) { next(err); }
};

const updateEmergencyLog = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const STATUS_ENUM = new Set([
      'dispatching',
      'accepted',
      'in_progress',
      'completed',
      'cancelled',
      'failed',
      'documentation',
    ]);
    const updates = {};

    if (req.body.status !== undefined) {
      const s = String(req.body.status);
      if (!STATUS_ENUM.has(s)) {
        return res.status(400).json({ error: 'Invalid status.' });
      }
      updates.status = s;
    }

    if (req.body.assigned_lawyer_id !== undefined) {
      updates.assigned_lawyer_id = req.body.assigned_lawyer_id || null;
    }

    if (req.body.clearEvidence === true || req.body.clear_evidence === true) {
      updates.evidence = [];
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update.' });
    }

    const event = await Event.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    res.json({ event });
  } catch (err) { next(err); }
};

const deleteEmergencyLog = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    res.json({ message: 'Event deleted.' });
  } catch (err) { next(err); }
};

module.exports = {
  getAdminSettings, updateFixedOtpSetting, getAdminStats,
  getAllUsers, createUser, updateUser, deleteUser,
  getAllLawyers, createLawyer, updateLawyer, deleteLawyer,
  getPendingLawyers, approveLawyer, rejectLawyer,
  getEmergencyLogs, updateEmergencyLog, deleteEmergencyLog,
  getLoginLogs, getAllUsersWithStatus,
};