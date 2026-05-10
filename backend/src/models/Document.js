// ============================================================
//  Document.js — Interactive Legal Architect / signed docs (M10–11)
// ============================================================

const mongoose = require('mongoose');

const signatureSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      // May reference User or Lawyer collection depending on signer role
    },
    role: {
      type: String,
      enum: ['citizen', 'lawyer'],
      required: true,
    },
    signatureHash: { type: String, required: true },
    signedAt: { type: Date, default: Date.now },
  },
  { _id: true },
);

const documentSchema = new mongoose.Schema(
  {
    creator: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    sections: [
      {
        heading: { type: String, default: '' },
        content: { type: String, default: '' },
      },
    ],
    footer: { type: String, default: '' },
    signatures: [signatureSchema],
    status: {
      type: String,
      enum: ['draft', 'pending_lawyer', 'signed'],
      default: 'draft',
      index: true,
    },
  },
  { timestamps: true },
);

documentSchema.index({ creator: 1, updatedAt: -1 });

module.exports = mongoose.model('Document', documentSchema);
