const mongoose = require('mongoose');

const CitizenContactSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User', index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, default: '', trim: true },
    email: { type: String, default: '', trim: true },
    notes: { type: String, default: '' },
  },
  { timestamps: true },
);

CitizenContactSchema.index({ user_id: 1, createdAt: -1 });

module.exports = mongoose.model('CitizenContact', CitizenContactSchema);
