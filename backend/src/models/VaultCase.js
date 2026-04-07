const mongoose = require('mongoose');

const VaultCaseSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  name: { type: String, required: true },
  fileIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'VaultFile' }],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('VaultCase', VaultCaseSchema);
