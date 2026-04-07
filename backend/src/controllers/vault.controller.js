const VaultFile = require('../models/VaultFile');
const VaultCase = require('../models/VaultCase');

// ── Vault Controller ──────────────────────────────────────────
// Ensures users can only access their OWN files.

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
