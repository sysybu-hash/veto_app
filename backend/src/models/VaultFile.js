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
  caseId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultCase' },
  uploadedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('VaultFile', VaultFileSchema);
