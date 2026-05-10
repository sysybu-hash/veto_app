// ============================================================
//  billing.service.js
//  Pure helpers for VETO call billing — extracted from the
//  oversized call.controller.js so unit tests and other modules
//  can compose the math without pulling Express/Mongoose in.
// ============================================================

const User = require('../../models/User');
const {
  CONSULTATION_ILS,
  OVERTIME_ILS_PER_MIN,
  FREE_CALL_MINUTES,
} = require('../../config/pricing');

/**
 * Computes a billing breakdown for a call given its duration in seconds.
 * Always charges at least 1 minute and the base consultation fee.
 *
 * Return shape mirrors what `finishCallBilling` writes onto EmergencyEvent.
 */
function computeChargeFromSeconds(seconds) {
  const durationSeconds = Math.max(0, Math.ceil(Number(seconds) || 0));
  const minutes = Math.max(1, Math.ceil(durationSeconds / 60));
  const overtimeMinutes = Math.max(0, minutes - FREE_CALL_MINUTES);
  const overtimeIls = +(overtimeMinutes * OVERTIME_ILS_PER_MIN).toFixed(2);
  return {
    durationSeconds,
    minutes,
    baseIls: CONSULTATION_ILS,
    overtimeMinutes,
    overtimeIls,
    totalIls: +(CONSULTATION_ILS + overtimeIls).toFixed(2),
  };
}

/**
 * Returns true when the user account is exempt from billing — admins and
 * accounts that were `manually_added` (white-glove imports) never see a
 * charge for a consultation.
 */
async function isPaymentExemptUser(user) {
  if (!user?.userId) return false;
  if (user.role === 'admin') return true;
  const account = await User.findById(user.userId)
    .select('manually_added role')
    .lean();
  return account?.role === 'admin' || account?.manually_added === true;
}

module.exports = {
  computeChargeFromSeconds,
  isPaymentExemptUser,
};
