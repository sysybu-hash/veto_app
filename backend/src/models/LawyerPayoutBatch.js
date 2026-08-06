const mongoose = require('mongoose');

const LawyerPayoutBatchSchema = new mongoose.Schema(
  {
    lawyer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lawyer',
      required: true,
      index: true,
    },
    period_from: { type: Date, default: null },
    period_to: { type: Date, default: null },
    earning_ids: [
      { type: mongoose.Schema.Types.ObjectId, ref: 'LawyerEarning' },
    ],
    calls_count: { type: Number, default: 0 },
    amount_ils: { type: Number, required: true, default: 0 },
    status: {
      type: String,
      enum: ['draft', 'pending', 'paid', 'cancelled'],
      default: 'pending',
      index: true,
    },
    paid_at: { type: Date, default: null },
    payment_ref: { type: String, default: '' },
    payment_method: {
      type: String,
      enum: ['bank_transfer', 'paypal', 'bit', 'cash', 'manual', 'other'],
      default: 'manual',
    },
    created_by_admin_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    notes: { type: String, default: '' },
  },
  { timestamps: true },
);

LawyerPayoutBatchSchema.index({ lawyer_id: 1, createdAt: -1 });

module.exports = mongoose.model('LawyerPayoutBatch', LawyerPayoutBatchSchema);
