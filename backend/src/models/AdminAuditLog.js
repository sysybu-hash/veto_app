const mongoose = require('mongoose');

const AdminAuditLogSchema = new mongoose.Schema(
  {
    admin_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    admin_role: {
      type: String,
      default: 'admin',
    },
    action: {
      type: String,
      required: true,
      index: true,
    },
    target_type: {
      type: String,
      required: true,
      index: true,
    },
    target_id: {
      type: String,
      default: null,
      index: true,
    },
    before: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    after: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    ip: {
      type: String,
      default: null,
    },
    user_agent: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  },
);

AdminAuditLogSchema.index({ createdAt: -1 });

module.exports = mongoose.model('AdminAuditLog', AdminAuditLogSchema);
