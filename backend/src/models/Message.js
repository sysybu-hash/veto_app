// ============================================================
//  Message.js — Chat messages between users and lawyers
// ============================================================

const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema(
  {
    sender_id:    { type: mongoose.Schema.Types.ObjectId, required: true },
    sender_role:  { type: String, enum: ['user', 'lawyer', 'admin'], required: true },
    receiver_id:  { type: mongoose.Schema.Types.ObjectId, required: true },
    receiver_role:{ type: String, enum: ['user', 'lawyer', 'admin'], required: true },
    event_id:     { type: mongoose.Schema.Types.ObjectId, ref: 'EmergencyEvent', default: null },
    text:         { type: String, required: true, maxlength: 4000 },
    read:         { type: Boolean, default: false },
    attachments:  [{ url: String, name: String, type: String }],
  },
  { timestamps: true, versionKey: false },
);

MessageSchema.index({ sender_id: 1, receiver_id: 1, createdAt: -1 });
MessageSchema.index({ receiver_id: 1, read: 1 });

module.exports = mongoose.model('Message', MessageSchema);
