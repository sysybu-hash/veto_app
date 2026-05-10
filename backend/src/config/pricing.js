// ============================================================
//  pricing.js — single source of truth for plans & charges.
//  Prices are stored in NIS (₪) for display and converted to USD
//  for PayPal capture (PayPal merchant cannot capture ILS for
//  this account, so we use a fixed conversion factor).
// ============================================================

const ILS_TO_USD = Number(process.env.ILS_TO_USD || '0.275');

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
