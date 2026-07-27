// ============================================================
//  pricing.js — single source of truth for plans & charges.
//  Prices are stored in NIS (₪) for display and converted to USD
//  for PayPal capture (PayPal merchant cannot capture ILS for
//  this account, so we use a fixed conversion factor).
//
//  ILS_TO_USD is a STATIC rate, not a live FX fetch — deliberately: this affects real
//  money capture, and a live rate source adds a runtime dependency (and failure mode)
//  on a free-tier budget with no monitoring for it. Instead: track when it was last set
//  and warn loudly (not fail) once it's stale, so a human updates it periodically instead
//  of it silently drifting from the real market rate for months/years.
//  Update ILS_TO_USD *and* ILS_TO_USD_SET_AT together — see backend/ENV_GUIDE.md.
// ============================================================

const ILS_TO_USD = Number(process.env.ILS_TO_USD || '0.275');
const ILS_TO_USD_SET_AT = process.env.ILS_TO_USD_SET_AT || '2026-01-01';
const ILS_TO_USD_STALE_DAYS = 90;

(function warnIfRateIsStale() {
  const setAt = new Date(ILS_TO_USD_SET_AT);
  if (Number.isNaN(setAt.getTime())) return;
  const ageDays = (Date.now() - setAt.getTime()) / (1000 * 60 * 60 * 24);
  if (ageDays > ILS_TO_USD_STALE_DAYS) {
    // Lazy require to avoid a hard dependency cycle at module-load time.
    const logger = require('../lib/logger');
    logger.warn(
      { ILS_TO_USD, ILS_TO_USD_SET_AT, ageDays: Math.round(ageDays) },
      `[pricing] ILS_TO_USD conversion rate is ${Math.round(ageDays)} days old — review against the current market rate and update ILS_TO_USD + ILS_TO_USD_SET_AT.`,
    );
  }
})();

function ilsToUsd(ils) {
  return (Number(ils) * ILS_TO_USD).toFixed(2);
}

const PLANS = {
  demo: {
    id: 'demo',
    label: 'Demo',
    monthlyIls: 0,
    durationDays: 30,
    consultationsIncluded: 0,
    sosAllowed: false,
    familySeats: 1,
  },
  standard: {
    id: 'standard',
    label: 'Standard',
    monthlyIls: 19.9,
    durationDays: 31,
    consultationsIncluded: 0,
    sosAllowed: true,
    familySeats: 1,
  },
  family: {
    id: 'family',
    label: 'Family',
    monthlyIls: 199.99,
    durationDays: 31,
    consultationsIncluded: 2,
    sosAllowed: true,
    familySeats: 4,
  },
};

const CONSULTATION_ILS = 79.9;
const OVERTIME_ILS_PER_MIN = 0.5;
const FREE_CALL_MINUTES = 15;

module.exports = {
  PLANS,
  CONSULTATION_ILS,
  OVERTIME_ILS_PER_MIN,
  FREE_CALL_MINUTES,
  ILS_TO_USD,
  ilsToUsd,
};
