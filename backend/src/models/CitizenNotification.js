const mongoose = require('mongoose');

const CitizenNotificationSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User', index: true },
    type: { type: String, default: 'info', trim: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, default: '' },
    read: { type: Boolean, default: false, index: true },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

CitizenNotificationSchema.index({ user_id: 1, createdAt: -1 });

module.exports = mongoose.model('CitizenNotification', CitizenNotificationSchema);
