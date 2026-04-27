const mongoose = require('mongoose');

const LegalNotebookSchema = new mongoose.Schema(
  {
    accountId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    accountRole: { type: String, enum: ['user', 'lawyer', 'admin'], default: 'user' },
    name: { type: String, default: 'Legal notebook' },
    caseId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultCase', default: null },
    vaultFileIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'VaultFile' }],
    /** NotebookLM Enterprise / Discovery — external resource name or id. */
    externalNotebookId: { type: String, default: null },
    externalUrl: { type: String, default: null },
    lastSyncedAt: { type: Date, default: null },
    status: { type: String, enum: ['draft', 'syncing', 'synced', 'error', 'unconfigured'], default: 'unconfigured' },
    lastError: { type: String, default: null },
  },
  { timestamps: true },
);

module.exports = mongoose.model('LegalNotebook', LegalNotebookSchema);
