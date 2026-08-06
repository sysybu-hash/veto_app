const mongoose = require('mongoose');

/**
 * A seat on a family plan that has been offered to a phone number which is not
 * a registered user yet.
 *
 * Before this existed, adding a family member required that person to already
 * have an account — the owner got "User with that phone is not registered" and
 * had to phone them, wait for them to sign up, and come back. The seat is now
 * reserved here and claimed automatically the moment they register with that
 * number.
 *
 * Reserved seats count against the plan's limit exactly like real members do,
 * so an owner cannot over-commit by inviting six people and letting them race.
 */
const FamilyInviteSchema = new mongoose.Schema(
  {
    owner_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    /** Always E.164, normalised by the caller before it reaches here. */
    phone: { type: String, required: true, index: true },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'cancelled', 'expired'],
      default: 'pending',
      index: true,
    },
    invited_by_name: { type: String, default: '' },
    accepted_at: { type: Date, default: null },
    accepted_user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    /** Seats are not held forever; an unclaimed invite frees up after this. */
    expires_at: { type: Date, required: true },
    notified: {
      sms: { type: Boolean, default: false },
      email: { type: Boolean, default: false },
    },
  },
  { timestamps: true },
);

// One live invite per phone per owner. Partial so cancelled/expired rows do not
// block re-inviting the same person later.
FamilyInviteSchema.index(
  { owner_id: 1, phone: 1 },
  {
    unique: true,
    name: 'one_pending_invite_per_phone',
    partialFilterExpression: { status: 'pending' },
  },
);

module.exports = mongoose.model('FamilyInvite', FamilyInviteSchema);
