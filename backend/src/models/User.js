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
      // Sparse skips *missing* fields. Do NOT store null/'' — Mongo indexes
      // null and then only one Google-only user can exist (E11000 on phone).
      sparse: true,
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

    /** Plan: 'demo' | 'standard' | 'family' | null (none) */
    subscription_plan: {
      type: String,
      enum: ['demo', 'standard', 'family', null],
      default: null,
    },

    /** PayPal Billing Subscription id (I-...). */
    paypal_subscription_id: {
      type: String,
      default: null,
      index: true,
      sparse: true,
    },

    /** PayPal subscription lifecycle status, e.g. APPROVAL_PENDING, ACTIVE, CANCELLED. */
    subscription_status: {
      type: String,
      default: null,
    },

    /** PayPal plan id used for the active billing subscription. */
    subscription_plan_id: {
      type: String,
      default: null,
    },

    /** Current paid period end as reported by PayPal/webhook or inferred locally. */
    subscription_current_period_end: {
      type: Date,
      default: null,
    },

    /** When the citizen first activated the demo plan (one-time per user). */
    demo_started_at: {
      type: Date,
      default: null,
    },

    /** Consultations bundled with the active plan (refreshed each period). */
    consultations_included: {
      type: Number,
      default: 0,
    },

    /** Consultations consumed since the current period started. */
    consultations_used: {
      type: Number,
      default: 0,
    },

    /** Token of a paid (but not yet consumed) consultation - required to start SOS. */
    pending_consultation_token: {
      type: String,
      default: null,
      select: false,
    },

    passkeys: {
      type: [
        {
          credential_id: { type: String, required: true },
          public_key: { type: Buffer, required: true },
          counter: { type: Number, default: 0 },
          transports: { type: [String], default: [] },
          device_name: { type: String, default: 'Passkey' },
          created_at: { type: Date, default: Date.now },
          last_used_at: { type: Date, default: null },
        },
      ],
      default: [],
      select: false,
    },

    /** Family plan: id of the user who owns the family seat (self for owner). */
    family_owner_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // ── Manually added by admin (exempt from payment) ─────────
    manually_added: {
      type: Boolean,
      default: false,
    },

    /** First-run onboarding (web citizen flow) — language / basics */
    onboarding_completed: {
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

// Keep phone absent (not null) so the sparse unique index allows many
// Google-only accounts without a phone number.
UserSchema.pre('save', function unsetEmptyPhone(next) {
  if (this.phone === null || this.phone === '') {
    this.set('phone', undefined);
    if (this._doc && Object.prototype.hasOwnProperty.call(this._doc, 'phone')) {
      delete this._doc.phone;
    }
  }
  next();
});

module.exports = mongoose.model('User', UserSchema);
