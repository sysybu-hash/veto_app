const mongoose = require('mongoose');

const CitizenContractSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User', index: true },
    title: { type: String, required: true, trim: true },
    counterparty: { type: String, default: '', trim: true },
    status: {
      type: String,
      enum: ['draft', 'active', 'closed', 'at_risk'],
      default: 'active',
      index: true,
    },
    notes: { type: String, default: '' },
    vaultFileIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'VaultFile' }],
    startDate: { type: Date },
    endDate: { type: Date },
  },
  { timestamps: true },
);

CitizenContractSchema.index({ user_id: 1, createdAt: -1 });

module.exports = mongoose.model('CitizenContract', CitizenContractSchema);
