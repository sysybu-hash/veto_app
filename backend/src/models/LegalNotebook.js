const mongoose = require('mongoose');

const SourceSchema = new mongoose.Schema(
  {
    kind: { type: String, enum: ['vault', 'url', 'text'], required: true },
    title: { type: String, default: '' },
    vaultFileId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultFile', default: null },
    url: { type: String, default: '' },
    text: { type: String, default: '' },
    addedAt: { type: Date, default: Date.now },
  },
  { _id: true },
);

const ChatMsgSchema = new mongoose.Schema(
  {
    role: { type: String, enum: ['user', 'model'], required: true },
    text: { type: String, required: true },
    at: { type: Date, default: Date.now },
  },
  { _id: false },
);

const LegalNotebookSchema = new mongoose.Schema(
  {
    accountId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    accountRole: { type: String, enum: ['user', 'lawyer', 'admin'], default: 'user' },
    name: { type: String, default: 'Legal notebook' },
    caseId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultCase', default: null },
    vaultFileIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'VaultFile' }],
    /** Local markdown body (VETO notebook — primary editing surface). */
    content: { type: String, default: '' },
    sources: [SourceSchema],
    chatMessages: { type: [ChatMsgSchema], default: [] },
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
