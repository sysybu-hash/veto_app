// ============================================================
//  pricingSettings.service.js — live, admin-editable pricing.
//
//  Prices used to be literals in config/pricing.js, so changing the cost of a
//  consultation meant a commit and a deploy. They now live in a single
//  AppSetting document that the admin console edits, with the old constants
//  kept as the fallback when nothing has been saved yet.
//
//  Reads are served from an in-memory cache because the hot paths that need
//  them (finishCallBilling, the payout ledger) are synchronous and run per
//  call. The cache is warmed at boot, refreshed on every write, and re-read on
//  a timer so a second server instance picks up another instance's change.
//
//  IMPORTANT: changing a price must never alter money that was already
//  recorded. LawyerEarning snapshots base_fee_ils and commission_rate per row,
//  and EmergencyEvent snapshots charge_amount_ils — nothing here rewrites them.
// ============================================================

const AppSetting = require('../models/AppSetting');
const logger = require('../lib/logger');
const {
  CONSULTATION_ILS,
  OVERTIME_ILS_PER_MIN,
  FREE_CALL_MINUTES,
  LAWYER_CALL_FEE_ILS,
  LAWYER_OVERTIME_SHARE,
  PLANS,
} = require('../config/pricing');

const SETTING_KEY = 'pricing_v1';
const REFRESH_MS = 30_000;

/**
 * Every editable price, with the bounds the admin console is held to.
 * `max` values are sanity rails, not business policy — they exist so a typo
 * (49900 instead of 499) cannot be saved.
 */
const FIELDS = {
  consultationIls: { min: 0, max: 5000, label: 'מחיר ייעוץ (שיחת SOS)' },
  overtimeIlsPerMin: { min: 0, max: 100, label: 'מחיר דקת חריגה' },
  freeCallMinutes: { min: 0, max: 240, integer: true, label: 'דקות ללא חיוב' },
  lawyerCallFeeIls: { min: 0, max: 5000, label: 'שכר עו״ד לשיחה' },
  lawyerOvertimeShare: { min: 0, max: 1, label: 'חלק עו״ד בחריגה (0–1)' },
};

/** Values shipped in code / env — used until an admin saves something else. */
function codeDefaults() {
  return {
    consultationIls: CONSULTATION_ILS,
    overtimeIlsPerMin: OVERTIME_ILS_PER_MIN,
    freeCallMinutes: FREE_CALL_MINUTES,
    lawyerCallFeeIls: LAWYER_CALL_FEE_ILS,
    lawyerOvertimeShare: LAWYER_OVERTIME_SHARE,
  };
}

let cache = codeDefaults();
let cacheLoadedAt = 0;
let refreshTimer = null;

function round2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

/**
 * Coerces and range-checks a patch. Returns { values, errors } rather than
 * throwing on the first problem so the console can show every bad field.
 */
function validate(patch, base = cache) {
  const values = { ...base };
  const errors = [];
  for (const [key, spec] of Object.entries(FIELDS)) {
    if (patch[key] === undefined || patch[key] === '') continue;
    const raw = Number(patch[key]);
    if (!Number.isFinite(raw)) {
      errors.push(`${spec.label}: ערך לא מספרי.`);
      continue;
    }
    if (spec.integer && !Number.isInteger(raw)) {
      errors.push(`${spec.label}: חייב להיות מספר שלם.`);
      continue;
    }
    if (raw < spec.min || raw > spec.max) {
      errors.push(`${spec.label}: מחוץ לטווח המותר (${spec.min}–${spec.max}).`);
      continue;
    }
    values[key] = spec.integer ? raw : round2(raw);
  }
  return { values, errors };
}

/** Current prices, straight from cache. Safe to call on hot paths. */
function getPricing() {
  return { ...cache };
}

async function loadPricing({ force = false } = {}) {
  if (!force && Date.now() - cacheLoadedAt < REFRESH_MS) return getPricing();
  try {
    const doc = await AppSetting.findOne({ key: SETTING_KEY }).lean();
    const stored = doc?.value && typeof doc.value === 'object' ? doc.value : {};
    const { values } = validate(stored, codeDefaults());
    cache = values;
    cacheLoadedAt = Date.now();
  } catch (err) {
    // Never let a settings read break billing — fall back to what we have.
    logger.warn({ err }, '[pricing] could not load settings, keeping cache');
  }
  return getPricing();
}

/** Warms the cache and keeps it fresh across instances. Call once at boot. */
function startPricingRefresh() {
  if (refreshTimer) return;
  void loadPricing({ force: true });
  refreshTimer = setInterval(() => {
    void loadPricing({ force: true });
  }, REFRESH_MS);
  if (typeof refreshTimer.unref === 'function') refreshTimer.unref();
}

function stopPricingRefresh() {
  if (refreshTimer) clearInterval(refreshTimer);
  refreshTimer = null;
}

/**
 * Persists a patch. Returns the full new pricing plus the previous values so
 * the caller can write a meaningful audit entry.
 */
async function updatePricing(patch, adminId = null) {
  const before = getPricing();
  const { values, errors } = validate(patch, before);
  if (errors.length) {
    const err = new Error(errors.join(' '));
    err.status = 400;
    err.fields = errors;
    throw err;
  }

  await AppSetting.findOneAndUpdate(
    { key: SETTING_KEY },
    { $set: { value: values, updated_by: adminId } },
    { upsert: true, new: true },
  );

  cache = values;
  cacheLoadedAt = Date.now();

  const changed = Object.keys(FIELDS).filter((k) => before[k] !== values[k]);
  logger.warn(
    { changed: changed.map((k) => `${k}: ${before[k]} → ${values[k]}`), adminId },
    '[pricing] rates changed',
  );
  return { before, after: getPricing(), changed };
}

/**
 * Subscription plans are NOT editable here. PayPal bills recurring plans
 * against its own plan objects, so a price stored on our side would only
 * change the label while PayPal kept charging the old amount. Exposed
 * read-only with the live PayPal plan id so the console can say so plainly.
 */
function subscriptionPlansReadOnly() {
  return Object.values(PLANS).map((p) => ({
    id: p.id,
    label: p.label,
    monthlyIls: p.monthlyIls,
    familySeats: p.familySeats,
    consultationsIncluded: p.consultationsIncluded,
    paypalPlanIdEnv:
      p.id === 'standard'
        ? 'PAYPAL_STANDARD_PLAN_ID'
        : p.id === 'family'
          ? 'PAYPAL_FAMILY_PLAN_ID'
          : null,
    paypalPlanIdSet:
      p.id === 'standard'
        ? Boolean(process.env.PAYPAL_STANDARD_PLAN_ID)
        : p.id === 'family'
          ? Boolean(process.env.PAYPAL_FAMILY_PLAN_ID)
          : false,
  }));
}

module.exports = {
  FIELDS,
  SETTING_KEY,
  codeDefaults,
  validate,
  getPricing,
  loadPricing,
  startPricingRefresh,
  stopPricingRefresh,
  updatePricing,
  subscriptionPlansReadOnly,
  round2,
};
