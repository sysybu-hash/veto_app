const logger  = require('../lib/logger');
const User    = require('../models/User');
const Lawyer  = require('../models/Lawyer');
const Event   = require('../models/EmergencyEvent');
const AdminAuditLog = require('../models/AdminAuditLog');
const AppSetting = require('../models/AppSetting');
const mongoose = require('mongoose');
const { isGoogleAIConfigured } = require('../config/googleAI.client');

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

function asPlain(doc) {
  if (!doc) return null;
  return typeof doc.toObject === 'function' ? doc.toObject() : doc;
}

async function logAdminAction(req, { action, targetType, targetId, before = null, after = null, metadata = null }) {
  try {
    await AdminAuditLog.create({
      admin_id: req.user?.userId || null,
      admin_role: req.user?.role || 'admin',
      action,
      target_type: targetType,
      target_id: targetId ? String(targetId) : null,
      before: asPlain(before),
      after: asPlain(after),
      metadata,
      ip: req.ip || req.headers['x-forwarded-for'] || null,
      user_agent: req.headers['user-agent'] || null,
    });
  } catch (err) {
    logger.warn({ err }, '[admin audit] failed');
  }
}

const getAdminSettings = async (req, res, next) => {
  try {
    const isProd = process.env.NODE_ENV === 'production';
    // Fixed OTP is never available in production; non-prod uses hard-coded admin phones only.
    const enableFixedOtpForAdmins = !isProd;
    const compliance = await AppSetting.findOne({ key: 'eu_compliance_mode' }).lean();
    
    res.status(200).json({
      enableFixedOtpForAdmins,
      fixedOtpAllowedInProduction: false,
      serverStatus: 'Online',
      mongoDbStatus: 'Connected',
      appVersion: 'v1.2.4',
      euComplianceMode: compliance?.value === true,
    });
  } catch (err) {
    next(err);
  }
};

const updateEuComplianceMode = async (req, res, next) => {
  try {
    const enabled = req.body?.enabled;
    if (typeof enabled !== 'boolean') {
      return res.status(400).json({ error: 'enabled must be a boolean.' });
    }
    const setting = await AppSetting.findOneAndUpdate(
      { key: 'eu_compliance_mode' },
      { value: enabled, updated_by: req.user?.userId || null },
      { upsert: true, new: true },
    );
    await logAdminAction(req, {
      action: 'setting.eu_compliance_mode',
      targetType: 'setting',
      targetId: setting._id,
      after: setting,
    });
    res.json({ enabled });
  } catch (err) {
    next(err);
  }
};

/** Active SOS pipeline statuses (see EmergencyEvent schema). */
const ACTIVE_EMERGENCY_STATUSES = ['dispatching', 'accepted', 'in_progress'];

/**
 * Unified admin stats: live emergency rows + KPIs, plus legacy top-level fields
 * for Next.js `/api/admin/dashboard` and `fetchSystemStats()`.
 */
const getDashboardStats = async (req, res, next) => {
  try {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - 6);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      activeEvents,
      activeEventsCount,
      dailyEventsCount,
      revenueAgg,
      totalLawyers,
      lawyersOnline,
      totalUsers,
      activeLawyers,
      pendingLawyers,
      eventsToday,
      eventsWeek,
      eventsMonth,
    ] = await Promise.all([
      Event.find({ status: { $in: ACTIVE_EMERGENCY_STATUSES } })
        .sort({ createdAt: -1 })
        .limit(10)
        .lean(),
      Event.countDocuments({ status: { $in: ACTIVE_EMERGENCY_STATUSES } }),
      Event.countDocuments({ createdAt: { $gte: startOfToday } }),
      Event.aggregate([
        {
          $match: {
            createdAt: { $gte: startOfToday },
            status: 'completed',
          },
        },
        { $group: { _id: null, total: { $sum: '$charge_amount_ils' } } },
      ]),
      Lawyer.countDocuments({}),
      Lawyer.countDocuments({ is_available: true, is_active: true, is_approved: true }),
      User.countDocuments({}),
      Lawyer.countDocuments({ is_active: true }),
      Lawyer.countDocuments({ is_approved: false, is_active: true }),
      Event.countDocuments({ triggered_at: { $gte: startOfToday } }),
      Event.countDocuments({ triggered_at: { $gte: startOfWeek } }),
      Event.countDocuments({ triggered_at: { $gte: startOfMonth } }),
    ]);

    const dailyRevenue = revenueAgg.length > 0 ? Number(revenueAgg[0].total) || 0 : 0;

    res.status(200).json({
      status: 'success',
      data: {
        activeEvents,
        stats: {
          dailyEventsCount,
          dailyRevenue,
          totalLawyers,
          activeEventsCount,
          lawyersOnline,
        },
      },
      totalUsers,
      activeLawyers,
      pendingLawyers,
      eventsToday,
      eventsWeek,
      eventsMonth,
    });
  } catch (err) {
    next(err);
  }
};

const updateFixedOtpSetting = async (req, res, next) => {
  try {
    if (process.env.NODE_ENV === 'production') {
      return res.status(403).json({
        error: 'Fixed OTP cannot be enabled in production. Admin phones must use real SMS OTP.',
        enableFixedOtpForAdmins: false,
      });
    }
    const { enable } = req.body;
    if (typeof enable !== 'boolean') {
      return res.status(400).json({ error: 'Invalid value for enable. Must be a boolean.' });
    }
    // Non-prod: flag is informational only — requestOTP uses shouldUseFixedAdminOtp(phone).
    process.env.ENABLE_FIXED_OTP_FOR_ADMINS = enable.toString();
    logger.info({ enable }, '[ADMIN] ENABLE_FIXED_OTP_FOR_ADMINS set (non-production only)');
    res.status(200).json({
      message: 'Fixed OTP setting updated (development only; applies to admin phones only via code).',
      enableFixedOtpForAdmins: enable,
    });
  } catch (err) {
    next(err);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const [users, lawyers] = await Promise.all([
      User.find({})
        .select(
          'full_name phone email role is_verified is_subscribed subscription_expiry manually_added is_active preferred_language createdAt',
        )
        .sort({ createdAt: -1 })
        .lean(),
      Lawyer.find({})
        .select('full_name phone email createdAt')
        .sort({ createdAt: -1 })
        .lean(),
    ]);

    function subscriptionTierForUser(u) {
      if (u.manually_added) return 'basic';
      if (u.is_subscribed) {
        const exp = u.subscription_expiry;
        if (exp && new Date(exp) < new Date()) return 'expired';
        return 'pro';
      }
      if (u.subscription_expiry && new Date(u.subscription_expiry) < new Date()) {
        return 'expired';
      }
      return 'basic';
    }

    const rows = [
      ...users.map((u) => ({
        id: String(u._id),
        name: u.full_name || '—',
        email: (u.email && String(u.email).trim()) || u.phone || '',
        phone: u.phone || '',
        role: u.role === 'admin' ? 'admin' : 'user',
        createdAt: u.createdAt,
        subscriptionTier: subscriptionTierForUser(u),
        accountType: 'user',
      })),
      ...lawyers.map((l) => ({
        id: String(l._id),
        name: l.full_name || '—',
        email: (l.email && String(l.email).trim()) || l.phone || '',
        phone: l.phone || '',
        role: 'lawyer',
        createdAt: l.createdAt,
        subscriptionTier: 'basic',
        accountType: 'lawyer',
      })),
    ];

    rows.sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );
    res.json({ users: rows });
  } catch (err) {
    next(err);
  }
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
    await logAdminAction(req, {
      action: 'user.create',
      targetType: 'user',
      targetId: user._id,
      after: user,
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
    const before = await User.findById(req.params.id).lean();
    if (!before) return res.status(404).json({ error: 'User not found.' });

    if (req.body.extendDays !== undefined) {
      const days = Number(req.body.extendDays);
      if (Number.isFinite(days) && days !== 0) {
        const base =
          before.subscription_expiry && before.subscription_expiry > new Date()
            ? new Date(before.subscription_expiry)
            : new Date();
        updates.subscription_expiry = new Date(base.getTime() + days * 86400000);
      }
    }

    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ error: 'User not found.' });
    await logAdminAction(req, {
      action: 'user.update',
      targetType: 'user',
      targetId: user._id,
      before,
      after: user,
      metadata: { fields: Object.keys(updates) },
    });
    res.json({ user });
  } catch (err) { next(err); }
};

const deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    await logAdminAction(req, {
      action: 'user.delete',
      targetType: 'user',
      targetId: user._id,
      before: user,
    });
    res.json({ message: 'User deleted.' });
  } catch (err) { next(err); }
};

const getAllLawyers = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyers = await Lawyer.find({})
      .select(
        'full_name phone email is_available is_verified is_approved is_active createdAt specializations license_number years_of_experience languages_spoken preferred_language total_cases_handled rating trust bio bar_association whatsapp_number telegram_username payout',
      )
      .sort({ createdAt: -1 });
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
    await logAdminAction(req, {
      action: 'lawyer.approve',
      targetType: 'lawyer',
      targetId: lawyer._id,
      after: lawyer,
    });
    res.json({ lawyer, message: '\u05e2\u05d5\u05e8\u05da \u05d4\u05d3\u05d9\u05df \u05d0\u05d5\u05e9\u05e8 \u05d1\u05d4\u05e6\u05dc\u05d7\u05d4.' });
  } catch (err) { next(err); }
};

const rejectLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndDelete(req.params.id);
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    await logAdminAction(req, {
      action: 'lawyer.reject',
      targetType: 'lawyer',
      targetId: lawyer._id,
      before: lawyer,
    });
    res.json({ message: '\u05e2\u05d5\u05e8\u05da \u05d4\u05d3\u05d9\u05df \u05e0\u05d3\u05d7\u05d4.' });
  } catch (err) { next(err); }
};

const createLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const {
      full_name,
      email,
      license_number,
      specializations,
      years_of_experience,
      bio,
      bar_association,
      languages_spoken,
      preferred_language,
      whatsapp_number,
      telegram_username,
    } = req.body;
    const phone = normalizePhone(req.body.phone);
    if (!full_name || !phone) {
      return res.status(400).json({ error: 'full_name and phone are required.' });
    }
    const lawyer = await Lawyer.create({
      full_name,
      phone,
      // Omit rather than store null — see the email_partial_unique index on
      // Lawyer. Writing null here made the second email-less lawyer fail.
      ...(email ? { email } : {}),
      license_number: license_number || null,
      specializations: specializations || [],
      years_of_experience: years_of_experience || 0,
      bio: bio || '',
      bar_association: bar_association || '',
      languages_spoken: Array.isArray(languages_spoken) && languages_spoken.length
        ? languages_spoken
        : ['he'],
      preferred_language: preferred_language || 'he',
      whatsapp_number: whatsapp_number || null,
      telegram_username: telegram_username || null,
      is_verified: true,
      is_approved: true,  // admin-created lawyers are pre-approved
      is_active: true,
    });
    await logAdminAction(req, {
      action: 'lawyer.create',
      targetType: 'lawyer',
      targetId: lawyer._id,
      after: lawyer,
    });
    res.status(201).json({ lawyer });
  } catch (err) { next(err); }
};

const updateLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const allowed = [
      'full_name',
      'phone',
      'email',
      'is_available',
      'is_verified',
      'is_approved',
      'is_active',
      'specializations',
      'license_number',
      'years_of_experience',
      'bio',
      'trust',
      'languages_spoken',
      'preferred_language',
      'bar_association',
      'whatsapp_number',
      'telegram_username',
      'payout',
    ];
    const updates = {};
    const unset = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    if (updates.phone) updates.phone = normalizePhone(updates.phone);
    // Clearing an email must UNSET the field, not write null — null is indexed
    // by email_partial_unique's `$exists` check only when it is a string, but a
    // stored null still trips the legacy sparse index on older deployments and
    // is simply wrong data. See the Lawyer model.
    if (updates.email === '' || updates.email === null) {
      delete updates.email;
      unset.email = '';
    }
    if (updates.whatsapp_number === '') updates.whatsapp_number = null;
    if (updates.telegram_username === '') updates.telegram_username = null;
    const before = await Lawyer.findById(req.params.id).lean();
    if (!before) return res.status(404).json({ error: 'Lawyer not found.' });
    if (updates.payout && typeof updates.payout === 'object') {
      updates.payout = { ...(before.payout || {}), ...updates.payout };
    }
    const patch = Object.keys(unset).length
      ? { $set: updates, $unset: unset }
      : updates;
    const lawyer = await Lawyer.findByIdAndUpdate(req.params.id, patch, { new: true, runValidators: true });
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    await logAdminAction(req, {
      action: 'lawyer.update',
      targetType: 'lawyer',
      targetId: lawyer._id,
      before,
      after: lawyer,
      metadata: { fields: Object.keys(updates) },
    });
    res.json({ lawyer });
  } catch (err) { next(err); }
};

const deleteLawyer = async (req, res, next) => {
  try {
    const Lawyer = require('../models/Lawyer');
    const lawyer = await Lawyer.findByIdAndDelete(req.params.id);
    if (!lawyer) return res.status(404).json({ error: 'Lawyer not found.' });
    await logAdminAction(req, {
      action: 'lawyer.delete',
      targetType: 'lawyer',
      targetId: lawyer._id,
      before: lawyer,
    });
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

const getAuditLogs = async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 100, 500);
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const query = {};
    if (req.query.action) query.action = String(req.query.action);
    if (req.query.targetType) query.target_type = String(req.query.targetType);
    if (req.query.targetId) query.target_id = String(req.query.targetId);

    const [logs, total] = await Promise.all([
      AdminAuditLog.find(query)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      AdminAuditLog.countDocuments(query),
    ]);

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

    const before = await Event.findById(req.params.id).lean();
    if (!before) return res.status(404).json({ error: 'Event not found.' });
    const event = await Event.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    await logAdminAction(req, {
      action: 'event.update',
      targetType: 'event',
      targetId: event._id,
      before,
      after: event,
      metadata: { fields: Object.keys(updates) },
    });
    res.json({ event });
  } catch (err) { next(err); }
};

const deleteEmergencyLog = async (req, res, next) => {
  try {
    const Event = require('../models/EmergencyEvent');
    const event = await Event.findByIdAndDelete(req.params.id);
    if (!event) return res.status(404).json({ error: 'Event not found.' });
    await logAdminAction(req, {
      action: 'event.delete',
      targetType: 'event',
      targetId: event._id,
      before: event,
    });
    res.json({ message: 'Event deleted.' });
  } catch (err) { next(err); }
};

const getSystemHealth = async (req, res, next) => {
  try {
    const envEnabled = (name) => Boolean(String(process.env[name] || '').trim());
    const checks = [
      {
        key: 'mongo',
        label: 'MongoDB',
        status: mongoose.connection.readyState === 1 ? 'ok' : 'error',
      },
      {
        key: 'paypal-api',
        label: 'PayPal API credentials',
        status: envEnabled('PAYPAL_CLIENT_ID') && envEnabled('PAYPAL_CLIENT_SECRET') ? 'ok' : 'missing',
      },
      {
        key: 'paypal-subscriptions',
        label: 'PayPal subscription plan IDs',
        status: envEnabled('PAYPAL_STANDARD_PLAN_ID') && envEnabled('PAYPAL_FAMILY_PLAN_ID') ? 'ok' : 'missing',
      },
      {
        key: 'paypal-webhook',
        label: 'PayPal webhook verification',
        status: envEnabled('PAYPAL_WEBHOOK_ID') ? 'ok' : 'missing',
      },
      {
        key: 'gemini',
        label: 'Gemini API key',
        status: isGoogleAIConfigured() ? 'ok' : 'missing',
      },
      {
        key: 'web-app-url',
        label: 'Frontend return URL',
        status: envEnabled('WEB_APP_URL') || envEnabled('FRONTEND_URL') ? 'ok' : 'missing',
      },
      {
        key: 'google-oauth',
        label: 'Google OAuth',
        status: envEnabled('GOOGLE_CLIENT_ID') && envEnabled('GOOGLE_CLIENT_SECRET') ? 'ok' : 'optional',
      },
    ];

    res.json({
      status: checks.some((c) => c.status === 'error') ? 'error' : 'ok',
      generatedAt: new Date().toISOString(),
      checks,
    });
  } catch (err) {
    next(err);
  }
};

function startOfDay(d = new Date()) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function parseReportRange(query = {}) {
  const now = new Date();
  const preset = String(query.preset || 'month');
  let from;
  let to = now;
  if (query.from) {
    const f = new Date(query.from);
    if (!Number.isNaN(f.getTime())) from = f;
  }
  if (query.to) {
    const t = new Date(query.to);
    if (!Number.isNaN(t.getTime())) to = t;
  }
  if (!from) {
    if (preset === 'today') from = startOfDay(now);
    else if (preset === 'week') {
      from = new Date(now);
      from.setDate(now.getDate() - 6);
      from = startOfDay(from);
    } else {
      from = new Date(now.getFullYear(), now.getMonth(), 1);
    }
  }
  return { from, to, preset };
}

async function sumRevenue(from, to) {
  const agg = await Event.aggregate([
    {
      $match: {
        status: 'completed',
        createdAt: { $gte: from, $lte: to },
        charge_amount_ils: { $gt: 0 },
      },
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$charge_amount_ils' },
        count: { $sum: 1 },
      },
    },
  ]);
  return {
    totalIls: agg.length ? Number(agg[0].total) || 0 : 0,
    chargedCalls: agg.length ? Number(agg[0].count) || 0 : 0,
  };
}

async function buildFinanceReport({ from, to, preset }) {
  const now = new Date();
  const todayStart = startOfDay(now);
  const weekStart = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6));
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

  const [
    revenueRange,
    revenueToday,
    revenueWeek,
    revenueMonth,
    users,
    chargedEvents,
    eventsInRange,
  ] = await Promise.all([
    sumRevenue(from, to),
    sumRevenue(todayStart, now),
    sumRevenue(weekStart, now),
    sumRevenue(monthStart, now),
    User.find({})
      .select('full_name email phone role is_subscribed subscription_expiry manually_added is_active createdAt')
      .lean(),
    Event.find({
      status: 'completed',
      createdAt: { $gte: from, $lte: to },
      charge_amount_ils: { $gt: 0 },
    })
      .sort({ createdAt: -1 })
      .limit(50)
      .select('charge_amount_ils charge_status call_type triggered_at createdAt user_id assigned_lawyer_id')
      .lean(),
    Event.countDocuments({
      triggered_at: { $gte: from, $lte: to },
    }),
  ]);

  const subCounts = { active: 0, expired: 0, free: 0, none: 0, lawyers: 0, admins: 0 };
  for (const u of users) {
    if (u.role === 'lawyer') {
      subCounts.lawyers += 1;
      continue;
    }
    if (u.role === 'admin') {
      subCounts.admins += 1;
      continue;
    }
    if (u.manually_added) subCounts.free += 1;
    else if (u.is_subscribed) {
      const expired = u.subscription_expiry && new Date(u.subscription_expiry) < now;
      if (expired) subCounts.expired += 1;
      else subCounts.active += 1;
    } else subCounts.none += 1;
  }

  const lines = [
    'VETO Legal — דוח כספים וניהול',
    `נוצר: ${now.toISOString()}`,
    `טווח: ${from.toISOString()} → ${to.toISOString()} (${preset})`,
    '',
    // These sums are `charge_amount_ils`, which holds the OVERTIME charge only —
    // the base consultation is covered by the citizen's plan and is not billed
    // per call. Labelling this "הכנסות" without qualification reads as total
    // revenue and understates the picture.
    '=== הכנסות מחיובי חריגה (₪) ===',
    `בטווח שנבחר: ${revenueRange.totalIls.toFixed(2)} ₪ (${revenueRange.chargedCalls} חיובים)`,
    `היום: ${revenueToday.totalIls.toFixed(2)} ₪`,
    `7 ימים: ${revenueWeek.totalIls.toFixed(2)} ₪`,
    `מתחילת החודש: ${revenueMonth.totalIls.toFixed(2)} ₪`,
    '',
    '=== מנויים ומשתמשים ===',
    `מנויים פעילים: ${subCounts.active}`,
    `מנויים שפגו: ${subCounts.expired}`,
    `פטורים (ידני): ${subCounts.free}`,
    `ללא מנוי: ${subCounts.none}`,
    `עורכי דין: ${subCounts.lawyers}`,
    `מנהלים: ${subCounts.admins}`,
    `סה״כ משתמשים: ${users.length}`,
    `אירועי SOS בטווח: ${eventsInRange}`,
    '',
  ];

  const csvRows = [
    ['event_id', 'amount_ils', 'charge_status', 'call_type', 'created_at'].join(','),
    ...chargedEvents.map((e) =>
      [
        String(e._id),
        Number(e.charge_amount_ils) || 0,
        e.charge_status || '',
        e.call_type || '',
        e.createdAt ? new Date(e.createdAt).toISOString() : '',
      ].join(','),
    ),
  ];

  return {
    generatedAt: now.toISOString(),
    range: { from: from.toISOString(), to: to.toISOString(), preset },
    revenue: {
      range: revenueRange,
      today: revenueToday,
      week: revenueWeek,
      month: revenueMonth,
    },
    subscriptions: subCounts,
    totals: {
      users: users.length,
      eventsInRange,
    },
    recentCharges: chargedEvents.map((e) => ({
      id: String(e._id),
      amountIls: Number(e.charge_amount_ils) || 0,
      chargeStatus: e.charge_status || null,
      callType: e.call_type || null,
      createdAt: e.createdAt ? new Date(e.createdAt).toISOString() : null,
    })),
    textReport: lines.join('\n'),
    csv: csvRows.join('\n'),
  };
}

const getFinanceReport = async (req, res, next) => {
  try {
    const range = parseReportRange(req.query);
    const report = await buildFinanceReport(range);
    res.json({ status: 'success', data: report });
  } catch (err) {
    next(err);
  }
};

const emailFinanceReport = async (req, res, next) => {
  try {
    const { sendEmail, isConfigured } = require('../services/email.service');
    const to = String(req.body?.to || '').trim();
    if (!to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) {
      return res.status(400).json({ error: 'כתובת אימייל תקינה נדרשת (to).' });
    }
    if (!isConfigured()) {
      return res.status(503).json({
        error: 'SMTP לא מוגדר בשרת. הגדירו SMTP_HOST ו-SMTP_FROM.',
        smtpConfigured: false,
      });
    }

    const range = parseReportRange({
      preset: req.body?.preset,
      from: req.body?.from,
      to: req.body?.toDate || req.body?.rangeTo,
    });
    const report = await buildFinanceReport(range);
    const subject =
      String(req.body?.subject || '').trim() ||
      `VETO Legal — דוח כספים ${range.from.toISOString().slice(0, 10)}`;

    const result = await sendEmail({
      to,
      subject,
      text: report.textReport,
      html: `<pre style="font-family:ui-monospace,monospace;white-space:pre-wrap;direction:rtl;text-align:right">${report.textReport
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')}</pre>`,
      attachments: [
        {
          filename: `veto-finance-${range.from.toISOString().slice(0, 10)}.csv`,
          content: report.csv,
          contentType: 'text/csv; charset=utf-8',
        },
      ],
    });

    if (!result.sent) {
      return res.status(502).json({
        error: result.reason || 'שליחת המייל נכשלה',
        smtpConfigured: true,
      });
    }

    await logAdminAction(req, {
      action: 'finance_report_email',
      targetType: 'report',
      targetId: to,
      metadata: {
        preset: range.preset,
        from: range.from.toISOString(),
        to: range.to.toISOString(),
      },
    });

    res.json({
      status: 'success',
      sent: true,
      to,
      generatedAt: report.generatedAt,
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAdminSettings, getSystemHealth, updateFixedOtpSetting, updateEuComplianceMode, getDashboardStats,
  getAllUsers, createUser, updateUser, deleteUser,
  getAllLawyers, createLawyer, updateLawyer, deleteLawyer,
  getPendingLawyers, approveLawyer, rejectLawyer,
  getEmergencyLogs, updateEmergencyLog, deleteEmergencyLog,
  getLoginLogs, getAuditLogs, getAllUsersWithStatus,
  getFinanceReport, emailFinanceReport,
};
