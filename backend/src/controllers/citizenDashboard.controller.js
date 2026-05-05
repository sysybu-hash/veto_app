// ============================================================
//  citizenDashboard.controller.js — citizen-only CRM-lite API
// ============================================================

const mongoose = require('mongoose');
const CitizenContract = require('../models/CitizenContract');
const CitizenTask = require('../models/CitizenTask');
const CitizenContact = require('../models/CitizenContact');
const CitizenNotification = require('../models/CitizenNotification');
const VaultCase = require('../models/VaultCase');

function uid(req) {
  return req.user.userId;
}

function badId(res) {
  return res.status(400).json({ error: 'Invalid id.' });
}

// ── Summary (dashboard cards) ───────────────────────────────
async function getSummary(req, res, next) {
  try {
    const userId = uid(req);
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const [
      openTasks,
      tasksOpenedLastWeek,
      activeContracts,
      contractsCreatedLastWeek,
      vaultCases,
      casesLastWeek,
      atRiskContracts,
      overdueTasks,
    ] = await Promise.all([
      CitizenTask.countDocuments({ user_id: userId, status: 'open' }),
      CitizenTask.countDocuments({ user_id: userId, status: 'open', createdAt: { $gte: weekAgo } }),
      CitizenContract.countDocuments({ user_id: userId, status: { $in: ['draft', 'active', 'at_risk'] } }),
      CitizenContract.countDocuments({ user_id: userId, createdAt: { $gte: weekAgo } }),
      VaultCase.countDocuments({ user_id: userId }),
      VaultCase.countDocuments({ user_id: userId, createdAt: { $gte: weekAgo } }),
      CitizenContract.countDocuments({ user_id: userId, status: 'at_risk' }),
      CitizenTask.countDocuments({
        user_id: userId,
        status: 'open',
        dueAt: { $lt: now },
      }),
    ]);

    const openRisks = atRiskContracts + overdueTasks;

    res.json({
      openTasks,
      tasksTrend: tasksOpenedLastWeek,
      activeContracts,
      contractsTrend: contractsCreatedLastWeek,
      trackedCases: vaultCases,
      casesTrend: casesLastWeek,
      openRisks,
      labels: {
        tasksTrend: `+${tasksOpenedLastWeek} מהשבוע שעבר`,
        contractsTrend: `+${contractsCreatedLastWeek} מהשבוע שעבר`,
        casesTrend: `+${casesLastWeek} מהשבוע שעבר`,
      },
    });
  } catch (e) {
    next(e);
  }
}

// ── Reports stub ────────────────────────────────────────────
async function getReportsSummary(req, res, next) {
  try {
    const userId = uid(req);
    const [contracts, tasks, contacts] = await Promise.all([
      CitizenContract.countDocuments({ user_id: userId }),
      CitizenTask.countDocuments({ user_id: userId }),
      CitizenContact.countDocuments({ user_id: userId }),
    ]);
    res.json({
      period: 'all',
      totals: { contracts, tasks, contacts },
      generatedAt: new Date().toISOString(),
    });
  } catch (e) {
    next(e);
  }
}

// ── Contracts ───────────────────────────────────────────────
async function listContracts(req, res, next) {
  try {
    const rows = await CitizenContract.find({ user_id: uid(req) }).sort({ updatedAt: -1 }).lean();
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

async function createContract(req, res, next) {
  try {
    const { title, counterparty, status, notes, vaultFileIds, startDate, endDate } = req.body;
    if (!title || String(title).trim() === '') {
      return res.status(400).json({ error: 'title is required.' });
    }
    const doc = await CitizenContract.create({
      user_id: uid(req),
      title: String(title).trim(),
      counterparty: counterparty != null ? String(counterparty) : '',
      status: status || 'active',
      notes: notes != null ? String(notes) : '',
      vaultFileIds: Array.isArray(vaultFileIds) ? vaultFileIds : [],
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
    });
    res.status(201).json(doc);
  } catch (e) {
    next(e);
  }
}

async function updateContract(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const patch = { ...req.body };
    if (patch.startDate) patch.startDate = new Date(patch.startDate);
    if (patch.endDate) patch.endDate = new Date(patch.endDate);
    delete patch.user_id;
    const doc = await CitizenContract.findOneAndUpdate(
      { _id: id, user_id: uid(req) },
      { $set: patch },
      { new: true },
    );
    if (!doc) return res.status(404).json({ error: 'Not found.' });
    res.json(doc);
  } catch (e) {
    next(e);
  }
}

async function deleteContract(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const r = await CitizenContract.deleteOne({ _id: id, user_id: uid(req) });
    if (r.deletedCount === 0) return res.status(404).json({ error: 'Not found.' });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}

// ── Tasks ───────────────────────────────────────────────────
async function listTasks(req, res, next) {
  try {
    const rows = await CitizenTask.find({ user_id: uid(req) }).sort({ dueAt: 1, createdAt: -1 }).lean();
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

async function createTask(req, res, next) {
  try {
    const { title, description, dueAt, status, relatedType, relatedId } = req.body;
    if (!title || String(title).trim() === '') {
      return res.status(400).json({ error: 'title is required.' });
    }
    const doc = await CitizenTask.create({
      user_id: uid(req),
      title: String(title).trim(),
      description: description != null ? String(description) : '',
      dueAt: dueAt ? new Date(dueAt) : undefined,
      status: status === 'done' ? 'done' : 'open',
      relatedType: relatedType != null ? String(relatedType) : '',
      relatedId: relatedId && mongoose.isValidObjectId(relatedId) ? relatedId : undefined,
    });
    res.status(201).json(doc);
  } catch (e) {
    next(e);
  }
}

async function updateTask(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const patch = { ...req.body };
    if (patch.dueAt) patch.dueAt = new Date(patch.dueAt);
    delete patch.user_id;
    const doc = await CitizenTask.findOneAndUpdate(
      { _id: id, user_id: uid(req) },
      { $set: patch },
      { new: true },
    );
    if (!doc) return res.status(404).json({ error: 'Not found.' });
    res.json(doc);
  } catch (e) {
    next(e);
  }
}

async function deleteTask(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const r = await CitizenTask.deleteOne({ _id: id, user_id: uid(req) });
    if (r.deletedCount === 0) return res.status(404).json({ error: 'Not found.' });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}

// ── Contacts ─────────────────────────────────────────────────
async function listContacts(req, res, next) {
  try {
    const rows = await CitizenContact.find({ user_id: uid(req) }).sort({ updatedAt: -1 }).lean();
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

async function createContact(req, res, next) {
  try {
    const { name, phone, email, notes } = req.body;
    if (!name || String(name).trim() === '') {
      return res.status(400).json({ error: 'name is required.' });
    }
    const doc = await CitizenContact.create({
      user_id: uid(req),
      name: String(name).trim(),
      phone: phone != null ? String(phone) : '',
      email: email != null ? String(email) : '',
      notes: notes != null ? String(notes) : '',
    });
    res.status(201).json(doc);
  } catch (e) {
    next(e);
  }
}

async function updateContact(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const patch = { ...req.body };
    delete patch.user_id;
    const doc = await CitizenContact.findOneAndUpdate(
      { _id: id, user_id: uid(req) },
      { $set: patch },
      { new: true },
    );
    if (!doc) return res.status(404).json({ error: 'Not found.' });
    res.json(doc);
  } catch (e) {
    next(e);
  }
}

async function deleteContact(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const r = await CitizenContact.deleteOne({ _id: id, user_id: uid(req) });
    if (r.deletedCount === 0) return res.status(404).json({ error: 'Not found.' });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
}

// ── Notifications ───────────────────────────────────────────
async function listNotifications(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 200);
    const rows = await CitizenNotification.find({ user_id: uid(req) })
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    res.json(rows);
  } catch (e) {
    next(e);
  }
}

async function markNotificationRead(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.isValidObjectId(id)) return badId(res);
    const doc = await CitizenNotification.findOneAndUpdate(
      { _id: id, user_id: uid(req) },
      { $set: { read: true } },
      { new: true },
    );
    if (!doc) return res.status(404).json({ error: 'Not found.' });
    res.json(doc);
  } catch (e) {
    next(e);
  }
}

async function createNotification(req, res, next) {
  try {
    const { type, title, body, payload } = req.body;
    if (!title || String(title).trim() === '') {
      return res.status(400).json({ error: 'title is required.' });
    }
    const doc = await CitizenNotification.create({
      user_id: uid(req),
      type: type != null ? String(type) : 'info',
      title: String(title).trim(),
      body: body != null ? String(body) : '',
      read: false,
      payload: payload && typeof payload === 'object' ? payload : {},
    });
    res.status(201).json(doc);
  } catch (e) {
    next(e);
  }
}

module.exports = {
  getSummary,
  getReportsSummary,
  listContracts,
  createContract,
  updateContract,
  deleteContract,
  listTasks,
  createTask,
  updateTask,
  deleteTask,
  listContacts,
  createContact,
  updateContact,
  deleteContact,
  listNotifications,
  markNotificationRead,
  createNotification,
};
