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
      required: [true, 'Phone number is required'],
      unique: true,
      trim: true,
      // E.164 format: +972501234567
      match: [/^\+[1-9]\d{7,14}$/, 'Please provide a valid phone number'],
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
      enum: ['en', 'he', 'ar'],
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
  },
  {
    timestamps: true, // createdAt, updatedAt
    versionKey: false,
  }
);

// ── Geo Index (for location-based queries) ─────────────────
UserSchema.index({ last_location: '2dsphere' });

module.exports = mongoose.model('User', UserSchema);
