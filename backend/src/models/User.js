// ============================================================
//  User.js — Mongoose Schema
//  VETO Legal Emergency App
// ============================================================

const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    // ── Identity ──────────────────────────────────────────────
    full_name: {
      type: String,
      required: [true, 'Full name is required'],
      trim: true,
    },

    phone: {
      type: String,
      unique: true,
      sparse: true, // Google-only users won't have a phone number
      trim: true,
      // E.164 format: +972501234567
      match: [/^\+[1-9]\d{7,14}$/, 'Please provide a valid phone number'],
    },

    // ── Google OAuth ──────────────────────────────────────────
    google_id: {
      type: String,
      unique: true,
      sparse: true,
    },

    email: {
      type: String,
      unique: true,
      sparse: true, // allows null/undefined to be non-unique
      lowercase: true,
      trim: true,
    },

    // ── Auth ──────────────────────────────────────────────────
    otp_code: {
      type: String,
      select: false, // never returned in queries by default
    },

    otp_expires_at: {
      type: Date,
      select: false,
    },

    is_verified: {
      type: Boolean,
      default: false,
    },

    /** App role: regular member vs admin (lawyers live in Lawyer collection) */
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },

    // ── Preferences ───────────────────────────────────────────
    preferred_language: {
      type: String,
      enum: ['en', 'he', 'ru', 'ar'],
      default: 'en',
    },

    // ── Location (last known) ─────────────────────────────────
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

    // ── Emergency History ─────────────────────────────────────
    emergency_events: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'EmergencyEvent',
      },
    ],

    // ── Account Status ────────────────────────────────────────
    is_active: {
      type: Boolean,
      default: true,
    },

    profile_photo_url: {
      type: String,
      default: null,
    },

    // ── Subscription (PayPal) ─────────────────────────────────
    is_subscribed: {
      type: Boolean,
      default: false,
    },

    subscription_expiry: {
      type: Date,
      default: null,
    },

    // ── Manually added by admin (exempt from payment) ─────────
    manually_added: {
      type: Boolean,
      default: false,
    },

    // ── Notification / App Settings ───────────────────────────
    settings: {
      notifyEmergency: { type: Boolean, default: true },
      notifyUpdates:   { type: Boolean, default: true },
      notifySms:       { type: Boolean, default: false },
    },

    /** Web Push (browser) — same shape as PushSubscription JSON */
    push_subscription: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
      select: false,
    },
    /** Firebase Cloud Messaging device token (mobile) */
    fcm_token: {
      type: String,
      default: null,
      select: false,
    },
    /** Secret for GET /api/calendar/export.ics?token= (iCal feed) */
    icalFeedToken: {
      type: String,
      default: null,
      select: false,
      index: true,
      sparse: true,
    },

    /** Google Calendar OAuth (separate from Sign-In) — AES-GCM blob, never log */
    gcalRefreshTokenEnc: {
      type: String,
      default: null,
      select: false,
    },
    gcalCalendarId: {
      type: String,
      default: 'primary',
    },
    /** Incremental sync token from Calendar API events.list */
    gcalEventsSyncToken: {
      type: String,
      default: null,
      select: false,
    },
    gcalLastSyncAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt, updatedAt
    versionKey: false,
  }
);

// ── Geo Index (for location-based queries) ─────────────────
UserSchema.index({ last_location: '2dsphere' });

module.exports = mongoose.model('User', UserSchema);
