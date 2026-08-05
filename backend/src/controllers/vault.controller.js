const mongoose = require('mongoose');
const VaultFile = require('../models/VaultFile');
const VaultCase = require('../models/VaultCase');
const VaultFolder = require('../models/VaultFolder');
const EmergencyEvent = require('../models/EmergencyEvent');
const AITransparencyLog = require('../models/AITransparencyLog');
const { analyzeVaultFile } = require('../services/geminiLegal.service');
const {
  destroyCloudinaryAsset,
  isOurCloudinaryUrl,
} = require('../services/media/cloudinaryDelete.service');

// ── Vault Controller ──────────────────────────────────────────
// Ensures users can only access their OWN files.

exports.getSharedFiles = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const linked = await EmergencyEvent.exists({
      user_id: userId,
      assigned_lawyer_id: req.user.userId,
    });
    if (!linked && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'No shared case for this user.' });
    }
    const files = await VaultFile.find({ user_id: userId, lawyerAccess: true }).sort({ uploadedAt: -1 });
    res.json({ files });
  } catch (err) { next(err); }
};

/**
 * Lawyer inbox: all VaultFiles with lawyerAccess from citizens assigned to this lawyer.
 */
exports.getLawyerSharedInbox = async (req, res, next) => {
  try {
    const events = await EmergencyEvent.find({
      assigned_lawyer_id: req.user.userId,
    })
      .select('user_id')
      .lean();
    const citizenIds = [
      ...new Set(
        events
          .map((e) => (e.user_id ? String(e.user_id) : null))
          .filter(Boolean),
      ),
    ];
    if (citizenIds.length === 0) {
      return res.json({ files: [], citizens: [] });
    }
    const files = await VaultFile.find({
      user_id: { $in: citizenIds },
      lawyerAccess: true,
    })
      .sort({ uploadedAt: -1 })
      .lean();
    res.json({
      files,
      citizens: citizenIds,
    });
  } catch (err) { next(err); }
};

exports.getTimeline = async (req, res, next) => {
  try {
    const userId = req.user.role === 'lawyer' && req.query.userId
      ? req.query.userId
      : req.user.userId;
    if (req.user.role === 'lawyer') {
      const linked = await EmergencyEvent.exists({
        user_id: userId,
        assigned_lawyer_id: req.user.userId,
      });
      if (!linked) return res.status(403).json({ error: 'No shared case for this user.' });
    }

    const [files, events] = await Promise.all([
      VaultFile.find(
        req.user.role === 'lawyer'
          ? { user_id: userId, lawyerAccess: true }
          : { user_id: userId },
      ).sort({ uploadedAt: -1 }).lean(),
      EmergencyEvent.find({
        user_id: userId,
        ...(req.user.role === 'lawyer' ? { assigned_lawyer_id: req.user.userId } : {}),
      })
        .select('status call_type triggered_at completed_at assigned_lawyer_id recording_url screen_recording_url call_transcript recording_saved_decision charge_status charge_amount_ils')
        .sort({ triggered_at: -1 })
        .limit(100)
        .lean(),
    ]);

    const items = [
      ...events.map((event) => ({
        id: String(event._id),
        type: 'sos',
        title: 'SOS / שיחה משפטית',
        at: event.triggered_at || event.createdAt,
        status: event.status,
        caseId: String(event._id),
        hasRecording: !!event.recording_url || !!event.screen_recording_url,
        hasTranscript: !!event.call_transcript,
        sharedWithLawyer: !!event.assigned_lawyer_id,
        // The client can only offer to open/play a recording if it actually has the
        // URL — hasRecording alone (a boolean) was previously the only signal sent,
        // so the vault UI had nothing to link to even when a recording existed.
        recordingUrl: event.recording_url || null,
        screenRecordingUrl: event.screen_recording_url || null,
        metadata: {
          callType: event.call_type,
          chargeStatus: event.charge_status,
          chargeAmountIls: event.charge_amount_ils || 0,
        },
      })),
      ...files.map((file) => ({
        id: String(file._id),
        type: 'document',
        title: file.name,
        at: file.uploadedAt || file.createdAt,
        status: file.status || 'uploaded',
        caseId: file.caseId ? String(file.caseId) : null,
        mimeType: file.mimeType,
        sharedWithLawyer: !!file.lawyerAccess,
        // Same gap as above: the file's own URL was never sent, only derived metadata.
        fileUrl: file.url || null,
        metadata: {
          sizeBytes: file.sizeBytes || null,
          hasAiSummary: !!file.aiSummary,
        },
      })),
    ].sort((a, b) => new Date(b.at || 0).getTime() - new Date(a.at || 0).getTime());

    res.json({ items });
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
    const file = await VaultFile.findOne({ _id: req.params.fileId, user_id: req.user.userId });
    if (!file) return res.status(404).json({ error: 'File not found or unauthorized' });

    const url = String(file.url || '');
    const isRemote = url.startsWith('http://') || url.startsWith('https://');
    if (isRemote && isOurCloudinaryUrl(url)) {
      const destroyed = await destroyCloudinaryAsset({ fileUrl: url });
      if (!destroyed.ok && !destroyed.skipped) {
        return res.status(502).json({
          error: 'Cloudinary delete failed',
          detail: destroyed.error || null,
        });
      }
    }

    await VaultFile.deleteOne({ _id: file._id, user_id: req.user.userId });
    res.json({ success: true, message: 'File deleted' });
  } catch (err) { next(err); }
};

/**
 * Authenticated remote-asset delete for Prisma Evidence (web-client) and other callers.
 * Body: { fileUrl: string }
 * Ownership of the Evidence row is enforced by the caller; here we only destroy
 * assets that belong to our Cloudinary cloud (or skip data: URLs).
 */
exports.deleteRemoteFile = async (req, res, next) => {
  try {
    const fileUrl = typeof req.body?.fileUrl === 'string' ? req.body.fileUrl.trim() : '';
    if (!fileUrl) {
      return res.status(400).json({ error: 'fileUrl is required' });
    }
    if (fileUrl.startsWith('data:')) {
      return res.json({ success: true, skipped: true });
    }
    if (!(fileUrl.startsWith('http://') || fileUrl.startsWith('https://'))) {
      return res.status(400).json({ error: 'fileUrl must be http(s) or data:' });
    }

    // Prefer Mongo ownership when the URL is a VaultFile the user owns.
    const owned = await VaultFile.findOne({ user_id: req.user.userId, url: fileUrl }).select('_id').lean();
    if (!owned && !isOurCloudinaryUrl(fileUrl)) {
      return res.status(400).json({
        error: 'URL is not a VETO Cloudinary asset and is not in your vault',
      });
    }

    if (isOurCloudinaryUrl(fileUrl)) {
      const destroyed = await destroyCloudinaryAsset({ fileUrl });
      if (!destroyed.ok && !destroyed.skipped) {
        return res.status(502).json({
          error: 'Cloudinary delete failed',
          detail: destroyed.error || null,
        });
      }
      return res.json({ success: true, skipped: !!destroyed.skipped });
    }

    // Owned VaultFile on non-Cloudinary storage (local /uploads) — nothing remote to destroy.
    return res.json({ success: true, skipped: true });
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
    await AITransparencyLog.create({
      user_id: req.user.userId,
      role: req.user.role || 'user',
      action: 'AI vault document analysis',
      source: 'vault',
      input_ref: String(file._id),
      output_ref: String(file._id),
      produced_output: true,
      used_fallback: false,
      requires_lawyer_review: true,
    }).catch(() => {});
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
