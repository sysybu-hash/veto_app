const mongoose = require('mongoose');

const CalendarEventSchema = new mongoose.Schema(
  {
    accountId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    accountRole: {
      type: String,
      required: true,
      enum: ['user', 'lawyer', 'admin'],
      index: true,
    },
    title: { type: String, required: true, trim: true },
    type: { type: String, enum: ['hearing', 'meeting', 'other'], default: 'other' },
    start: { type: Date, required: true, index: true },
    end: { type: Date, required: true },
    timezone: { type: String, default: 'Asia/Jerusalem' },
    locationAddress: { type: String, default: '' },
    locationLatLng: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
    /** Minutes before [start] to fire reminders, e.g. [15, 60, 1440]. */
    reminderBeforeMinutes: [{ type: Number }],
    notes: { type: String, default: '' },
    sourceCaseId: { type: mongoose.Schema.Types.ObjectId, ref: 'VaultCase', default: null },
    /** Deduplication for server-side reminder jobs: { at, beforeMinutes, channel } */
    remindersFired: [
      {
        at: { type: Date, required: true },
        beforeMinutes: { type: Number, required: true },
        channel: { type: String, enum: ['email', 'push', 'fcm'], default: 'push' },
      },
    ],
  },
  { timestamps: true },
);

CalendarEventSchema.index({ accountId: 1, start: 1 });
CalendarEventSchema.index({ start: 1, end: 1 });

module.exports = mongoose.model('CalendarEvent', CalendarEventSchema);
