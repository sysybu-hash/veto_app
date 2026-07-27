const mongoose = require('mongoose');

const VaultFileSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  name: { type: String, required: true },
  mimeType: { type: String, default: 'application/octet-stream' },
  url: { type: String, required: true },
  status: { type: String, enum: ['uploaded', 'analyzed', 'archived'], default: 'uploaded' },
  sizeBytes: { type: Number, required: true },
  lawyerAccess: { type: Boolean, default: false },
  aiSummary: { type: String },
  /** Structured output from legal analysis (JSON from Gemini) */
  legalAnalysis: { type: mongoose.Schema.Types.Mixed, default: null },
  caseId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultCase' },
  /** Optional document folder (separate from legal "case"). */
  folderId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultFolder', default: null, index: true },
  /** EmergencyEvent created via POST /events/documentation-session (optional). */
  sourceEventId: { type: mongoose.Schema.Types.ObjectId, ref: 'EmergencyEvent', index: true },
  uploadedAt: { type: Date, default: Date.now },
});

// Every vault read in vault.controller.js filters by user_id (the citizen's own vault —
// the most-hit query in this collection) and sorts by uploadedAt. user_id had no index
// at all before this; without it every vault list does a full collection scan.
VaultFileSchema.index({ user_id: 1, uploadedAt: -1 });

module.exports = mongoose.model('VaultFile', VaultFileSchema);
