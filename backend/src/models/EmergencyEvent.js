// ============================================================
//  EmergencyEvent.js — Mongoose Schema
//  VETO Legal Emergency App
// ============================================================

const mongoose = require('mongoose');

// ── Sub-schema: Evidence Item ──────────────────────────────
const EvidenceItemSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['photo', 'video', 'audio'],
      required: true,
    },

    cloud_url: {
      type: String,
      required: true, // S3 / Cloudinary / Firebase Storage URL
    },

    timestamp: {
      type: Date,
      default: Date.now,
    },

    gps_location: {
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

    duration_seconds: {
      type: Number,
      default: null, // for video/audio only
    },

    file_size_bytes: {
      type: Number,
      default: null,
    },
  },
  { _id: false }
);

// ── Sub-schema: Dispatch Attempt ───────────────────────────
// Tracks which lawyers were notified and their responses
const DispatchAttemptSchema = new mongoose.Schema(
  {
    lawyer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lawyer',
      required: true,
    },

    notified_at: {
      type: Date,
      default: Date.now,
    },

    response: {
      type: String,
      enum: ['pending', 'accepted', 'rejected', 'no_response'],
      default: 'pending',
    },

    responded_at: {
      type: Date,
      default: null,
    },
  },
  { _id: false }
);

// ── Main EmergencyEvent Schema ─────────────────────────────
const EmergencyEventSchema = new mongoose.Schema(
  {
    // ── Parties ───────────────────────────────────────────────
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User ID is required'],
      index: true,
    },

    assigned_lawyer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Lawyer',
      default: null, // null until a lawyer accepts
    },

    /** Per-event shared secret for Agora E2EE (not the user JWT). Use .select('+e2ee_secret') when needed. */
    e2ee_secret: {
      type: String,
      select: false,
    },

    // ── Status ────────────────────────────────────────────────
    status: {
      type: String,
      enum: [
        'dispatching',  // VETO pressed, searching for lawyer
        'accepted',     // A lawyer has accepted
        'in_progress',  // Call / consultation ongoing
        'completed',    // Event resolved
        'cancelled',    // User cancelled before lawyer accepted
        'failed',       // No lawyer responded in time
        'documentation', // User-only evidence session (no SOS / dispatch)
      ],
      default: 'dispatching',
      index: true,
    },

    // ── Timestamps ────────────────────────────────────────────
    triggered_at: {
      type: Date,
      default: Date.now, // when user pressed VETO
    },

    accepted_at: {
      type: Date,
      default: null,
    },

    completed_at: {
      type: Date,
      default: null,
    },

    // ── Location (where the event occurred) ───────────────────
    event_location: {
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

    location_address: {
      type: String,
      default: null, // reverse-geocoded human-readable address
    },

    // ── Language ──────────────────────────────────────────────
    language: {
      type: String,
      enum: ['en', 'he', 'ar', 'ru'],
      default: 'en', // user's preferred_language at event time
    },

    // ── Call Info ─────────────────────────────────────────────
    call_type: {
      type: String,
      enum: ['video', 'audio', 'chat', 'pending'],
      default: 'pending',
    },

    // WebRTC room identifier — equals the eventId for simplicity
    room_id: {
      type: String,
      default: null,
    },

    // Legacy field kept for backward compatibility (unused in new flow)
    call_link: {
      type: String,
      default: null,
    },

    // ── Call Recording & Transcription ────────────────────────
    call_started_at: {
      type: Date,
      default: null,
    },

    call_duration_seconds: {
      type: Number,
      default: null,
    },

    charge_status: {
      type: String,
      enum: ['none', 'pending', 'paid', 'waived'],
      default: 'none',
      index: true,
    },

    charge_minutes: {
      type: Number,
      default: 0,
    },

    charge_overtime_minutes: {
      type: Number,
      default: 0,
    },

    charge_amount_ils: {
      type: Number,
      default: 0,
    },

    charge_order_id: {
      type: String,
      default: null,
      index: true,
    },

    charge_capture_id: {
      type: String,
      default: null,
    },

    charge_calculated_at: {
      type: Date,
      default: null,
    },

    charge_paid_at: {
      type: Date,
      default: null,
    },

    recording_url: {
      type: String,
      default: null, // Cloudinary URL of the call recording
    },

    recording_public_id: {
      type: String,
      default: null,
    },

    recording_saved_decision: {
      type: String,
      enum: ['pending', 'saved', 'deleted'],
      default: 'pending',
      index: true,
    },

    recording_transcription_status: {
      type: String,
      enum: ['idle', 'pending', 'ready', 'failed'],
      default: 'idle',
    },

    screen_recording_url: {
      type: String,
      default: null,
    },

    screen_recording_public_id: {
      type: String,
      default: null,
    },

    /** Agora Cloud Recording (REST) — active session metadata; cleared after upload */
    agora_cloud_recording_resource_id: {
      type: String,
      default: null,
    },
    agora_cloud_recording_sid: {
      type: String,
      default: null,
    },
    agora_cloud_recording_uid: {
      type: Number,
      default: null,
    },

    // Cloudinary upload metadata (persisted; was dropped before schema existed)
    recording_duration_seconds: {
      type: Number,
      default: null,
    },

    recording_size_bytes: {
      type: Number,
      default: null,
    },

    call_transcript: {
      type: String,
      maxlength: 50000,
      default: null, // Full transcript generated by Gemini
    },

    transcript_language: {
      type: String,
      enum: ['en', 'he', 'ar', 'ru'],
      default: null,
    },

    // ── Call v2 (Phase 3 rewrite) ────────────────────────────
    /**
     * GDPR consent for cloud recording. Both timestamps must be set
     * before /api/calls/:eventId/cloud-recording/start will accept.
     * Cleared (set to null) when the call ends — consent does not
     * persist across separate sessions.
     */
    recording_consent: {
      citizen_at: { type: Date, default: null },
      lawyer_at:  { type: Date, default: null },
    },

    /**
     * Persisted in-call chat (replaces socket-only `call-chat-message`).
     * Survives reload, accessible after the call ends.
     */
    call_chat_messages: {
      type: [
        {
          author_role: { type: String, enum: ['user', 'lawyer'], required: true },
          author_id: { type: mongoose.Schema.Types.ObjectId, required: true },
          text: { type: String, maxlength: 4000, required: true },
          ts: { type: Date, default: Date.now },
        },
      ],
      default: [],
    },

    /**
     * Real-time transcription segments produced by Agora RTT.
     * `is_final: false` rows are interim hypotheses and may get replaced
     * by a final row sharing the same `segment_id`.
     */
    transcript_realtime_segments: {
      type: [
        {
          segment_id: { type: String, default: null },
          speaker: { type: String, default: null },
          speaker_uid: { type: Number, default: null },
          text: { type: String, default: '' },
          lang: { type: String, default: null },
          ts: { type: Date, default: Date.now },
          is_final: { type: Boolean, default: false },
        },
      ],
      default: [],
    },

    /** Agora Real-Time Transcription task id — non-null while RTT is running. */
    agora_rtt_task_id: {
      type: String,
      default: null,
    },

    /** Files dropped/shared during the call (Cloudinary URLs). */
    shared_files: {
      type: [
        {
          cloud_url: { type: String, required: true },
          mime: { type: String, default: null },
          size: { type: Number, default: 0 },
          by_role: { type: String, enum: ['user', 'lawyer'], required: true },
          by_id: { type: mongoose.Schema.Types.ObjectId, required: true },
          original_name: { type: String, default: null },
          ts: { type: Date, default: Date.now },
        },
      ],
      default: [],
    },

    // ── Smart Dispatch Log ────────────────────────────────────
    dispatch_attempts: {
      type: [DispatchAttemptSchema],
      default: [],
    },

    lawyers_notified_count: {
      type: Number,
      default: 0, // total lawyers alerted
    },

    time_to_accept_seconds: {
      type: Number,
      default: null, // seconds from dispatch to first acceptance
    },

    // ── Evidence ──────────────────────────────────────────────
    evidence: {
      type: [EvidenceItemSchema],
      default: [],
    },

    // ── Notes ─────────────────────────────────────────────────
    user_notes: {
      type: String,
      maxlength: 1000,
      default: '',
    },

    lawyer_notes: {
      type: String,
      maxlength: 1000,
      default: '',
    },

    // ── Rating (post-event) ───────────────────────────────────
    user_rating: {
      score: { type: Number, min: 1, max: 5, default: null },
      comment: { type: String, maxlength: 300, default: '' },
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// ── Indexes ────────────────────────────────────────────────
EmergencyEventSchema.index({ event_location: '2dsphere' });
EmergencyEventSchema.index({ user_id: 1, status: 1 });
EmergencyEventSchema.index({ assigned_lawyer_id: 1, status: 1 });

module.exports = mongoose.model('EmergencyEvent', EmergencyEventSchema);
