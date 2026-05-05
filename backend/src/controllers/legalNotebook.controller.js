// ============================================================
//  legalNotebook.controller
//  Architecture (product): **VETO local notebook** — markdown, sources,
//  chat via Gemini on aggregated context. Enterprise NotebookLM remains
//  optional (externalUrl / sync probe); consumer NotebookLM has no public API.
// ============================================================

const mongoose = require('mongoose');
const LegalNotebook = require('../models/LegalNotebook');
const VaultFile = require('../models/VaultFile');
const { accountFromReq } = require('../utils/calendarAccount.util');
const nb = require('../services/notebooklm.service');
const { generateNotebookReply } = require('../services/notebookChat.service');

const MAX_CHAT_STORED = 48;

async function buildNotebookContext(row, accountId) {
  const chunks = [];
  chunks.push(`# ${row.name}\n\n## Notebook (markdown)\n${row.content || ''}`);
  for (const s of row.sources || []) {
    if (s.kind === 'text') {
      chunks.push(`\n## Source: ${s.title || 'text'}\n${(s.text || '').slice(0, 20000)}`);
    } else if (s.kind === 'url') {
      chunks.push(`\n## Link: ${s.title || ''}\n${s.url || ''}`);
    } else if (s.kind === 'vault' && s.vaultFileId) {
      const f = await VaultFile.findOne({ _id: s.vaultFileId, user_id: accountId }).select(
        'name url mimeType aiSummary legalAnalysis',
      );
      if (f) {
        const la = f.legalAnalysis ? JSON.stringify(f.legalAnalysis).slice(0, 8000) : '';
        chunks.push(
          `\n## Vault file: ${f.name}\nMime: ${f.mimeType}\nSummary: ${f.aiSummary || '—'}\nAnalysis: ${la || '—'}`,
        );
      } else {
        chunks.push(`\n## Vault file ${s.vaultFileId} — not found or no access`);
      }
    }
  }
  return chunks.join('\n').slice(0, 120000);
}

exports.list = async (req, res, next) => {
  try {
    const { accountId, accountRole } = accountFromReq(req);
    const rows = await LegalNotebook.find({ accountId, accountRole }).sort({ updatedAt: -1 });
    res.json({
      notebooks: rows,
      enterpriseProbe: await nb.probeEnterpriseApi(),
      architecture: 'veto_local',
    });
  } catch (e) {
    next(e);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { name, caseId, vaultFileIds = [], content = '' } = req.body;
    const { accountId, accountRole } = accountFromReq(req);
    const openUrl = nb.openNotebookUrl({});
    const created = await LegalNotebook.create({
      accountId,
      accountRole,
      name: (name && String(name).trim()) || 'Legal notebook',
      caseId: caseId || null,
      vaultFileIds: Array.isArray(vaultFileIds) ? vaultFileIds : [],
      content: content == null ? '' : String(content),
      status: 'draft',
      externalUrl: openUrl,
    });
    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    res.json(row);
  } catch (e) {
    next(e);
  }
};

exports.patchNotebook = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    const { name, content, caseId } = req.body;
    if (name !== undefined) row.name = String(name).trim() || row.name;
    if (content !== undefined) row.content = String(content);
    if (caseId !== undefined) row.caseId = caseId || null;
    await row.save();
    res.json(row);
  } catch (e) {
    next(e);
  }
};

exports.addSource = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    const { kind, title = '', vaultFileId, url, text } = req.body;
    if (!['vault', 'url', 'text'].includes(kind)) {
      return res.status(400).json({ error: 'kind must be vault, url, or text' });
    }
    if (kind === 'vault') {
      if (!mongoose.Types.ObjectId.isValid(String(vaultFileId || ''))) {
        return res.status(400).json({ error: 'vaultFileId required' });
      }
      const f = await VaultFile.findOne({ _id: vaultFileId, user_id: accountId });
      if (!f) return res.status(400).json({ error: 'Vault file not found' });
    }
    if (kind === 'url' && !(url && String(url).trim())) {
      return res.status(400).json({ error: 'url required' });
    }
    if (kind === 'text' && !(text && String(text).trim())) {
      return res.status(400).json({ error: 'text required' });
    }
    row.sources.push({
      kind,
      title: String(title || '').slice(0, 200),
      vaultFileId: kind === 'vault' ? vaultFileId : null,
      url: kind === 'url' ? String(url).trim().slice(0, 2000) : '',
      text: kind === 'text' ? String(text).slice(0, 50000) : '',
    });
    await row.save();
    res.status(201).json(row);
  } catch (e) {
    next(e);
  }
};

exports.removeSource = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    if (!mongoose.Types.ObjectId.isValid(String(req.params.sourceId))) {
      return res.status(400).json({ error: 'Invalid sourceId' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });
    row.sources = (row.sources || []).filter((s) => String(s._id) !== String(req.params.sourceId));
    await row.save();
    res.json(row);
  } catch (e) {
    next(e);
  }
};

exports.chat = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(String(req.params.id))) {
      return res.status(400).json({ error: 'Invalid id' });
    }
    const { message } = req.body;
    if (!message || !String(message).trim()) {
      return res.status(400).json({ error: 'message is required' });
    }
    const { accountId, accountRole } = accountFromReq(req);
    const row = await LegalNotebook.findOne({ _id: req.params.id, accountId, accountRole });
    if (!row) return res.status(404).json({ error: 'Not found' });

    const userText = String(message).trim().slice(0, 8000);
    row.chatMessages.push({ role: 'user', text: userText, at: new Date() });

    const context = await buildNotebookContext(row, accountId);
    const history = (row.chatMessages || []).slice(0, -1).map((m) => ({ role: m.role, text: m.text }));
    const { text: reply, error } = await generateNotebookReply(context, history, userText);

    if (error) {
      row.chatMessages.pop();
      await row.save();
      return res.status(503).json({ error });
    }

    row.chatMessages.push({ role: 'model', text: reply, at: new Date() });
    while (row.chatMessages.length > MAX_CHAT_STORED) {
      row.chatMessages.shift();
    }
    await row.save();
    res.json({ reply, notebook: row });
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
