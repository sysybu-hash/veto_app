const mongoose = require('mongoose');

const VaultFolderSchema = new mongoose.Schema({
  user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
  name: { type: String, required: true, trim: true, maxlength: 200 },
  parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultFolder', default: null, index: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('VaultFolder', VaultFolderSchema);
