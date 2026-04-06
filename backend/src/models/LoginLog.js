// ============================================================
//  LoginLog.js — Login / Auth attempt log
//  Every OTP request, verify, register and Google auth is logged.
// ============================================================

const mongoose = require('mongoose');

const LoginLogSchema = new mongoose.Schema(
  {
    phone:     { type: String, default: null },
    email:     { type: String, default: null },
    role:      { type: String, default: null },
    event: {
      type: String,
      enum: [
        'register', 'otp_request', 'otp_success', 'otp_fail',
        'google_login', 'google_fail',
      ],
      required: true,
    },
    success:   { type: Boolean, required: true },
    ip:        { type: String, default: null },
    user_agent:{ type: String, default: null },
    error_msg: { type: String, default: null },
    user_id:   { type: mongoose.Schema.Types.ObjectId, default: null },
  },
  { timestamps: true, versionKey: false },
);

LoginLogSchema.index({ createdAt: -1 });
LoginLogSchema.index({ phone: 1, createdAt: -1 });

module.exports = mongoose.model('LoginLog', LoginLogSchema);
