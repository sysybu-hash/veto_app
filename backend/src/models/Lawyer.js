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

    // Uniqueness is enforced by a partial index below, NOT by `sparse`.
    // A sparse index only skips documents where the field is ABSENT — an
    // explicit `null` is still indexed, so `default: null` + sparse unique
    // meant only one email-less lawyer could ever exist (E11000 on the
    // second). Same trap that was already fixed for User.phone.
    email: {
      type: String,
      required: false,
      lowercase: true,
      trim: true,
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

    /** Updated on socket connect / location heartbeat — used to detect stale is_online. */
    last_seen: {
      type: Date,
      default: null,
      index: true,
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

    trust: {
      license_verified: { type: Boolean, default: false },
      identity_verified: { type: Boolean, default: false },
      response_score: { type: Number, default: 0, min: 0, max: 100 },
      last_reviewed_at: { type: Date, default: null },
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

    fcm_token: {
      type: String,
      default: null,
      select: false,
    },
    icalFeedToken: {
      type: String,
      default: null,
      select: false,
      index: true,
      sparse: true,
    },

    gcalRefreshTokenEnc: {
      type: String,
      default: null,
      select: false,
    },
    gcalCalendarId: {
      type: String,
      default: 'primary',
    },
    gcalEventsSyncToken: {
      type: String,
      default: null,
      select: false,
    },
    gcalLastSyncAt: {
      type: Date,
      default: null,
    },

    // ── Response Config ───────────────────────────────────────
    response_minutes: {
      type: Number,
      default: 15,
    },

    // ── Payout destination (admin-managed) ─────────────────────
    payout: {
      method: {
        type: String,
        enum: ['bank_transfer', 'paypal', 'bit', 'manual'],
        default: 'manual',
      },
      paypal_email: { type: String, default: null, trim: true, lowercase: true },
      bank_holder_name: { type: String, default: '', trim: true },
      bank_name: { type: String, default: '', trim: true },
      bank_iban: { type: String, default: '', trim: true },
      bank_branch: { type: String, default: '', trim: true },
      bank_account: { type: String, default: '', trim: true },
      notes: { type: String, default: '', maxlength: 500 },
      /** Optional per-lawyer override of default call fee (ILS). null = use global. */
      custom_call_fee_ils: { type: Number, default: null, min: 0 },
      /** Optional per-lawyer overtime share 0–1. null = use global. */
      custom_overtime_share: { type: Number, default: null, min: 0, max: 1 },
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

// Unique only across lawyers that actually HAVE an email string. Mirrors
// User.phone's `phone_partial_unique` — see the comment on the email field.
LawyerSchema.index(
  { email: 1 },
  {
    unique: true,
    name: 'email_partial_unique',
    partialFilterExpression: {
      email: { $exists: true, $type: 'string' },
    },
  },
);

// Keep email absent (not null) so email-less lawyers never collide.
LawyerSchema.pre('save', function unsetEmptyEmail(next) {
  if (this.email === null || this.email === '') {
    this.set('email', undefined);
  }
  next();
});

module.exports = mongoose.model('Lawyer', LawyerSchema);
