const mongoose = require('mongoose');

const PasskeyChallengeSchema = new mongoose.Schema(
  {
    account_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    role: {
      type: String,
      enum: ['user', 'lawyer', 'admin'],
      required: true,
      index: true,
    },
    purpose: {
      type: String,
      enum: ['register', 'login'],
      required: true,
      index: true,
    },
    challenge: {
      type: String,
      required: true,
    },
    expires_at: {
      type: Date,
      required: true,
      index: { expires: 0 },
    },
  },
  { timestamps: true, versionKey: false },
);

module.exports = mongoose.model('PasskeyChallenge', PasskeyChallengeSchema);
