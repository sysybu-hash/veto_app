// ============================================================
//  legalNotebook.controller — Enterprise notebook refs
// ============================================================

const LegalNotebook = require('../models/LegalNotebook');
const { accountFromReq } = require('../utils/calendarAccount.util');
const nb = require('../services/notebooklm.service');

exports.list = async (req, res, next) => {
  try {
    const { accountId, accountRole } = accountFromReq(req);
    const rows = await LegalNotebook.find({ accountId, accountRole }).sort({ updatedAt: -1 });
    res.json({ notebooks: rows, enterpriseProbe: await nb.probeEnterpriseApi() });
  } catch (e) {
    next(e);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { name, caseId, vaultFileIds = [] } = req.body;
    const { accountId, accountRole } = accountFromReq(req);
    const openUrl = nb.openNotebookUrl({});
    const created = await LegalNotebook.create({
      accountId,
      accountRole,
      name: (name && String(name).trim()) || 'Legal notebook',
      caseId: caseId || null,
      vaultFileIds: Array.isArray(vaultFileIds) ? vaultFileIds : [],
      status: nb.isEnterpriseConfigured() ? 'draft' : 'unconfigured',
      externalUrl: openUrl,
    });
    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
};

exports.getOpenUrl = async (req, res, next) => {
  try {
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    const url = row.externalUrl || nb.openNotebookUrl({ externalId: row.externalNotebookId || undefined });
    res.json({ url, externalNotebookId: row.externalNotebookId, status: row.status });
  } catch (e) {
    next(e);
  }
};

exports.sync = async (req, res, next) => {
  try {
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    row.status = 'syncing';
    row.lastError = null;
    await row.save();
    const r = await nb.syncVaultToNotebook();
    row.lastSyncedAt = new Date();
    row.status = r.ok ? 'synced' : 'error';
    if (!r.ok) row.lastError = r.error || r.reason || 'sync failed';
    await row.save();
    res.json({ notebook: row, sync: r });
  } catch (e) {
    next(e);
  }
};
