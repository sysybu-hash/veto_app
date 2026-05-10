const mongoose = require('mongoose');

const PrivacyRequestSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['export', 'delete', 'correct'],
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['open', 'in_review', 'completed', 'rejected'],
      default: 'open',
      index: true,
    },
    note: {
      type: String,
      maxlength: 1000,
      default: '',
    },
  },
  { timestamps: true, versionKey: false },
);

module.exports = mongoose.model('PrivacyRequest', PrivacyRequestSchema);
