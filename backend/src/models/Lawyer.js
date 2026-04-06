// ============================================================
//  Lawyer.js — Mongoose Schema
//  VETO Legal Emergency App
// ============================================================

const mongoose = require('mongoose');

const LawyerSchema = new mongoose.Schema(
  {
    // ── Identity ──────────────────────────────────────────────
    full_name: {
      type: String,
      required: [true, 'Full name is required'],
      trim: true,
    },

    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      unique: true,
      trim: true,
      match: [/^\+[1-9]\d{7,14}$/, 'Please provide a valid phone number'],
    },

    email: {
      type: String,
      required: false,
      unique: true,
      sparse: true,    // allows multiple null values
      lowercase: true,
      trim: true,
      default: null,
    },

    // ── Auth ──────────────────────────────────────────────────
    otp_code: {
      type: String,
      select: false,
    },

    otp_expires_at: {
      type: Date,
      select: false,
    },

    is_verified: {
      type: Boolean,
      default: false,
    },

    // ── Professional Details ───────────────────────────────────
    license_number: {
      type: String,
      required: false,
      trim: true,
      default: null,
    },

    bar_association: {
      type: String,
      trim: true, // e.g. "Israel Bar Association"
    },

    specializations: {
      type: [String],
      // e.g. ['Criminal', 'Civil', 'Family', 'Labor', 'Real Estate']
      default: [],
    },

    years_of_experience: {
      type: Number,
      min: 0,
      default: 0,
    },

    bio: {
      type: String,
      maxlength: 500,
      default: '',
    },

    profile_photo_url: {
      type: String,
      default: null,
    },

    // ── Preferences ───────────────────────────────────────────
    preferred_language: {
      type: String,
      enum: ['en', 'he', 'ru', 'ar'],
      default: 'he',
    },

    languages_spoken: {
      type: [String],
      enum: ['en', 'he', 'ru', 'ar'],
      default: ['he'],
    },

    // ── Availability & Dispatch ────────────────────────────────
    is_online: {
      type: Boolean,
      default: false,
      index: true, // queried heavily during dispatch
    },

    is_available: {
      type: Boolean,
      default: true, // false when handling an active call
    },

    socket_id: {
      type: String,
      default: null, // current Socket.io connection ID
    },

    // ── Location ──────────────────────────────────────────────
    last_location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },

    // ── Contact Channels for Deep-linking ─────────────────────
    whatsapp_number: {
      type: String,
      trim: true,
      default: null,
    },

    telegram_username: {
      type: String,
      trim: true,
      default: null,
    },

    // ── Stats ─────────────────────────────────────────────────
    total_cases_handled: {
      type: Number,
      default: 0,
    },

    rating: {
      average: { type: Number, default: 0, min: 0, max: 5 },
      count:   { type: Number, default: 0 },
    },

    // ── Account Status ────────────────────────────────────────
    is_active: {
      type: Boolean,
      default: true,
    },

    // ── Admin approval (self-registered lawyers need approval) ─
    is_approved: {
      type: Boolean,
      default: false,
      index: true,
    },

    // ── Case History ──────────────────────────────────────────
    emergency_events: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'EmergencyEvent',
      },
    ],

    // ── Notification / App Settings ───────────────────────────
    settings: {
      notifyEmergency: { type: Boolean, default: true },
      notifyUpdates:   { type: Boolean, default: true },
      notifySms:       { type: Boolean, default: false },
    },

    // ── Web Push Subscription (browser PushSubscription object) ─
    push_subscription: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
      select: false, // don't expose by default
    },

    // ── Response Config ───────────────────────────────────────
    response_minutes: {
      type: Number,
      default: 15,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// ── Indexes ────────────────────────────────────────────────
LawyerSchema.index({ last_location: '2dsphere' });
LawyerSchema.index({ is_online: 1, is_available: 1 }); // core dispatch query

module.exports = mongoose.model('Lawyer', LawyerSchema);
