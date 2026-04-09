const VaultFile = require('../models/VaultFile');
const VaultCase = require('../models/VaultCase');

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
    const files = await VaultFile.find({ user_id: req.user.userId }).sort({ uploadedAt: -1 });
    res.json({ files });
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
    const allowedFields = ['name', 'caseId', 'status'];
    const update = {};
    for (const f of allowedFields) {
      if (req.body[f] !== undefined) update[f] = req.body[f];
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
    
    // Mock AI Analysis
    file.aiSummary = 'AI Summary: The document contains standard legal clauses related to the case. Important terms are highlighted.';
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
