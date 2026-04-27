const mongoose = require('mongoose');
const VaultFile = require('../models/VaultFile');
const VaultCase = require('../models/VaultCase');
const VaultFolder = require('../models/VaultFolder');
const { analyzeVaultFile } = require('../services/geminiLegal.service');

// ── Vault Controller ──────────────────────────────────────────
// Ensures users can only access their OWN files.

exports.getSharedFiles = async (req, res, next) => {
  try {
    const { userId } = req.params;
    // We only return files where lawyerAccess is true
    const files = await VaultFile.find({ user_id: userId, lawyerAccess: true }).sort({ uploadedAt: -1 });
    res.json({ files });
  } catch (err) { next(err); }
};

exports.getFiles = async (req, res, next) => {
  try {
    const q = { user_id: req.user.userId };
    if (req.query.folderId !== undefined) {
      const { folderId } = req.query;
      if (folderId === 'null' || folderId === '' || folderId == null) {
        q.$or = [{ folderId: null }, { folderId: { $exists: false } }];
      } else {
        if (!mongoose.Types.ObjectId.isValid(String(folderId))) {
          return res.status(400).json({ error: 'Invalid folderId' });
        }
        q.folderId = folderId;
      }
    }
    const files = await VaultFile.find(q).sort({ uploadedAt: -1 });
    res.json({ files });
  } catch (err) { next(err); }
};

exports.getFolders = async (req, res, next) => {
  try {
    const q = { user_id: req.user.userId };
    if (req.query.parentId !== undefined) {
      const { parentId } = req.query;
      if (parentId === 'null' || parentId === '' || parentId == null) {
        q.$or = [{ parentId: null }, { parentId: { $exists: false } }];
      } else {
        if (!mongoose.Types.ObjectId.isValid(String(parentId))) {
          return res.status(400).json({ error: 'Invalid parentId' });
        }
        q.parentId = parentId;
      }
    }
    const folders = await VaultFolder.find(q).sort({ name: 1 });
    res.json({ folders });
  } catch (err) { next(err); }
};

exports.createFolder = async (req, res, next) => {
  try {
    const { name, parentId } = req.body;
    if (!name || !String(name).trim()) {
      return res.status(400).json({ error: 'Name is required' });
    }
    let parent = null;
    if (parentId) {
      if (!mongoose.Types.ObjectId.isValid(String(parentId))) {
        return res.status(400).json({ error: 'Invalid parentId' });
      }
      parent = await VaultFolder.findOne({ _id: parentId, user_id: req.user.userId });
      if (!parent) return res.status(404).json({ error: 'Parent folder not found' });
    }
    const created = await VaultFolder.create({
      user_id: req.user.userId,
      name: String(name).trim(),
      parentId: parent ? parent._id : null,
    });
    res.status(201).json(created);
  } catch (err) { next(err); }
};

exports.updateFolder = async (req, res, next) => {
  try {
    const { folderId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(String(folderId))) {
      return res.status(400).json({ error: 'Invalid folderId' });
    }
    const { name, parentId } = req.body;
    const folder = await VaultFolder.findOne({ _id: folderId, user_id: req.user.userId });
    if (!folder) return res.status(404).json({ error: 'Folder not found' });

    if (name != null) folder.name = String(name).trim() || folder.name;
    if (parentId !== undefined) {
      if (parentId === null || parentId === '' || parentId === 'null') {
        folder.parentId = null;
      } else {
        if (!mongoose.Types.ObjectId.isValid(String(parentId))) {
          return res.status(400).json({ error: 'Invalid parentId' });
        }
        if (String(parentId) === String(folderId)) {
          return res.status(400).json({ error: 'Cannot move folder into itself' });
        }
        const p = await VaultFolder.findOne({ _id: parentId, user_id: req.user.userId });
        if (!p) return res.status(404).json({ error: 'Target parent not found' });
        folder.parentId = p._id;
      }
    }
    await folder.save();
    res.json(folder);
  } catch (err) { next(err); }
};

exports.deleteFolder = async (req, res, next) => {
  try {
    const { folderId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(String(folderId))) {
      return res.status(400).json({ error: 'Invalid folderId' });
    }
    const folder = await VaultFolder.findOne({ _id: folderId, user_id: req.user.userId });
    if (!folder) return res.status(404).json({ error: 'Folder not found' });

    const hasChildren = await VaultFolder.countDocuments({ user_id: req.user.userId, parentId: folderId });
    if (hasChildren > 0) {
      return res.status(400).json({ error: 'Folder is not empty (subfolders exist)' });
    }
    const hasFiles = await VaultFile.countDocuments({ user_id: req.user.userId, folderId: folderId });
    if (hasFiles > 0) {
      return res.status(400).json({ error: 'Folder is not empty (files exist)' });
    }
    await VaultFolder.deleteOne({ _id: folderId });
    res.json({ success: true });
  } catch (err) { next(err); }
};

exports.deleteFile = async (req, res, next) => {
  try {
    const file = await VaultFile.findOneAndDelete({ _id: req.params.fileId, user_id: req.user.userId });
    if (!file) return res.status(404).json({ error: 'File not found or unauthorized' });
    res.json({ success: true, message: 'File deleted' });
  } catch (err) { next(err); }
};

exports.updateFileAccess = async (req, res, next) => {
  try {
    const { lawyerAccess } = req.body;
    const file = await VaultFile.findOneAndUpdate(
      { _id: req.params.fileId, user_id: req.user.userId },
      { lawyerAccess: !!lawyerAccess },
      { new: true }
    );
    if (!file) return res.status(404).json({ error: 'File not found or unauthorized' });
    res.json(file);
  } catch (err) { next(err); }
};

exports.updateFile = async (req, res, next) => {
  try {
    const allowedFields = ['name', 'caseId', 'status', 'folderId'];
    const update = {};
    for (const f of allowedFields) {
      if (req.body[f] !== undefined) update[f] = req.body[f];
    }
    if (update.folderId !== undefined) {
      if (update.folderId === null || update.folderId === '' || update.folderId === 'null') {
        update.folderId = null;
      } else {
        if (!mongoose.Types.ObjectId.isValid(String(update.folderId))) {
          return res.status(400).json({ error: 'Invalid folderId' });
        }
        const folder = await VaultFolder.findOne({
          _id: update.folderId,
          user_id: req.user.userId,
        });
        if (!folder) return res.status(404).json({ error: 'Folder not found' });
      }
    }
    const file = await VaultFile.findOneAndUpdate(
      { _id: req.params.fileId, user_id: req.user.userId },
      update,
      { new: true }
    );
    if (!file) return res.status(404).json({ error: 'File not found or unauthorized' });
    res.json(file);
  } catch (err) { next(err); }
};

exports.analyzeFile = async (req, res, next) => {
  try {
    const file = await VaultFile.findOne({ _id: req.params.fileId, user_id: req.user.userId });
    if (!file) return res.status(404).json({ error: 'File not found or unauthorized' });

    const { summary, legalAnalysis, error } = await analyzeVaultFile({
      name: file.name,
      mimeType: file.mimeType,
      url: file.url,
    });
    if (error) {
      return res.status(400).json({
        error: 'Document analysis could not be completed.',
        details: error,
        file: { _id: file._id, name: file.name, status: file.status, mimeType: file.mimeType },
      });
    }
    file.aiSummary = summary;
    file.legalAnalysis = legalAnalysis;
    file.status = 'analyzed';
    await file.save();
    res.json(file);
  } catch (err) { next(err); }
};

exports.getCases = async (req, res, next) => {
  try {
    const cases = await VaultCase.find({ user_id: req.user.userId }).sort({ createdAt: -1 });
    res.json({ cases });
  } catch (err) { next(err); }
};

exports.createCase = async (req, res, next) => {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: 'Case name is required' });

    const newCase = await VaultCase.create({
      user_id: req.user.userId,
      name,
    });
    res.status(201).json(newCase);
  } catch (err) { next(err); }
};

exports.updateCase = async (req, res, next) => {
  try {
    const { name } = req.body;
    const legalCase = await VaultCase.findOneAndUpdate(
      { _id: req.params.caseId, user_id: req.user.userId },
      { name },
      { new: true }
    );
    if (!legalCase) return res.status(404).json({ error: 'Case not found or unauthorized' });
    res.json(legalCase);
  } catch (err) { next(err); }
};

exports.deleteCase = async (req, res, next) => {
  try {
    // 1. Delete the case
    const legalCase = await VaultCase.findOneAndDelete({ _id: req.params.caseId, user_id: req.user.userId });
    if (!legalCase) return res.status(404).json({ error: 'Case not found or unauthorized' });

    // 2. Unlink all files associated with this case
    await VaultFile.updateMany(
      { caseId: req.params.caseId, user_id: req.user.userId },
      { $unset: { caseId: 1 } }
    );

    res.json({ success: true, message: 'Case deleted and files unlinked' });
  } catch (err) { next(err); }
};
