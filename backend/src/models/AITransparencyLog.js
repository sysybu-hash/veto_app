const mongoose = require('mongoose');

const AITransparencyLogSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
      index: true,
    },
    role: {
      type: String,
      enum: ['user', 'lawyer', 'admin', 'anonymous'],
      default: 'anonymous',
      index: true,
    },
    action: {
      type: String,
      required: true,
      index: true,
    },
    source: {
      type: String,
      enum: ['chat', 'vault', 'document', 'call', 'system', 'other'],
      default: 'other',
      index: true,
    },
    model: {
      type: String,
      default: null,
    },
    input_ref: {
      type: String,
      default: null,
    },
    output_ref: {
      type: String,
      default: null,
    },
    produced_output: {
      type: Boolean,
      default: false,
    },
    used_fallback: {
      type: Boolean,
      default: false,
    },
    requires_lawyer_review: {
      type: Boolean,
      default: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
  },
  { timestamps: true, versionKey: false },
);

AITransparencyLogSchema.index({ user_id: 1, createdAt: -1 });

module.exports = mongoose.model('AITransparencyLog', AITransparencyLogSchema);
