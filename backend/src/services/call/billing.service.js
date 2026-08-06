// ============================================================
//  billing.service.js
//  Pure helpers for VETO call billing — extracted from the
//  oversized call.controller.js so unit tests and other modules
//  can compose the math without pulling Express/Mongoose in.
// ============================================================

const User = require('../../models/User');
const { getPricing } = require('../pricingSettings.service');

/**
 * Computes a billing breakdown for a call given its duration in seconds.
 * Always charges at least 1 minute and the base consultation fee.
 *
 * Rates come from the live pricing settings (admin-editable) rather than
 * module constants, so a price change takes effect on the next call without a
 * deploy. `rates` can be passed explicitly to price a call against a specific
 * set of numbers — used by tests and by anything that needs to reproduce a
 * historical charge instead of the current tariff.
 *
 * Return shape mirrors what `finishCallBilling` writes onto EmergencyEvent.
 */
function computeChargeFromSeconds(seconds, rates = getPricing()) {
  const consultationIls = Number(rates.consultationIls) || 0;
  const overtimePerMin = Number(rates.overtimeIlsPerMin) || 0;
  const freeMinutes = Number(rates.freeCallMinutes) || 0;

  const durationSeconds = Math.max(0, Math.ceil(Number(seconds) || 0));
  const minutes = Math.max(1, Math.ceil(durationSeconds / 60));
  const overtimeMinutes = Math.max(0, minutes - freeMinutes);
  const overtimeIls = +(overtimeMinutes * overtimePerMin).toFixed(2);
  return {
    durationSeconds,
    minutes,
    baseIls: consultationIls,
    overtimeMinutes,
    overtimeIls,
    totalIls: +(consultationIls + overtimeIls).toFixed(2),
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
