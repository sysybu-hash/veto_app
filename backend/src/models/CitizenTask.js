const mongoose = require('mongoose');

const CitizenTaskSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User', index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    dueAt: { type: Date, index: true },
    status: {
      type: String,
      enum: ['open', 'done'],
      default: 'open',
      index: true,
    },
    relatedType: { type: String, default: '' },
    relatedId: { type: mongoose.Schema.Types.ObjectId },
  },
  { timestamps: true },
);

CitizenTaskSchema.index({ user_id: 1, status: 1, dueAt: 1 });

module.exports = mongoose.model('CitizenTask', CitizenTaskSchema);
