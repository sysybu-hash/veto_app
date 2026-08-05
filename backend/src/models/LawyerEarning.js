const mongoose = require('mongoose');

/**
 * Per-call lawyer entitlement ledger.
 * Citizen payment stays on EmergencyEvent; this tracks what VETO owes the lawyer.
 */
const LawyerEarningSchema = new mongoose.Schema(
  {
    lawyer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lawyer',
      required: true,
      index: true,
    },
    emergency_event_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'EmergencyEvent',
      required: true,
      unique: true,
    },
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    call_completed_at: { type: Date, default: Date.now },
    call_duration_seconds: { type: Number, default: 0 },
    call_type: { type: String, default: null },
    /** Snapshot of citizen charge on the event */
    charge_amount_ils: { type: Number, default: 0 },
    charge_status: { type: String, default: 'none' },
    /** Fixed fee for completing the SOS call */
    base_fee_ils: { type: Number, default: 0 },
    /** Share of overtime / extras */
    overtime_share_ils: { type: Number, default: 0 },
    lawyer_amount_ils: { type: Number, required: true, default: 0 },
    /** Consultation fee recognised for this call — 0 for payment-exempt citizens */
    consultation_revenue_ils: { type: Number, default: 0 },
    /** Platform margin; may be negative on exempt calls (lawyer fee with no revenue) */
    platform_amount_ils: { type: Number, default: 0 },
    commission_rate: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['pending', 'included_in_payout', 'paid', 'void'],
      default: 'pending',
      index: true,
    },
    payout_batch_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'LawyerPayoutBatch',
      default: null,
      index: true,
    },
    notes: { type: String, default: '' },
  },
  { timestamps: true },
);

LawyerEarningSchema.index({ lawyer_id: 1, status: 1, call_completed_at: -1 });

module.exports = mongoose.model('LawyerEarning', LawyerEarningSchema);
