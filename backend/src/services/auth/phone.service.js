// ============================================================
//  phone.service.js
//  Phone normalisation + admin allow-list — extracted from
//  auth.controller.js so registration, OTP, and admin scripts
//  share a single source of truth.
// ============================================================

/**
 * Strip the leading `+` for stable comparison.
 * Use this *only* for comparisons; we always store the canonical
 * E.164 form returned by `normalizePhoneForVeto`.
 */
function cleanPhone(phone) {
  return String(phone).replace(/\+/g, '');
}

/**
 * Convert any reasonable user input into canonical E.164 (`+...`).
 * Returns `null` if the value can't be parsed as a valid number.
 *
 * Accepts:
 *   `+972501111111`, `972501111111`, `0501111111`, `501111111` (IL mobile),
 *   any other 8–15 digit international form starting `1-9`.
 */
function normalizePhoneForVeto(raw) {
  if (raw == null) return null;
  const trimmed = String(raw).trim();
  if (!trimmed) return null;

  const s = trimmed.replace(/[\s\-().]/g, '');
  if (!s) return null;

  let d;
  if (s.startsWith('+')) {
    d = s.slice(1).replace(/\D/g, '');
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  d = s.replace(/\D/g, '');
  if (!d) return null;

  if (d.startsWith('972')) {
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  if (d.startsWith('0')) {
    const rest = d.slice(1);
    if (!/^[1-9]\d{6,12}$/.test(rest)) return null;
    return `+972${rest}`;
  }

  if (d.length === 9 && d.startsWith('5')) {
    return `+972${d}`;
  }

  if (/^[1-9]\d{7,14}$/.test(d)) {
    return `+${d}`;
  }

  return null;
}

/**
 * Hard-coded admin phones.
 * Treated as admins regardless of stored `role` so we can recover from a
 * mistakenly-edited document.
 */
function isAdminPhone(phone) {
  const clean = cleanPhone(phone);
  return clean === '972525640021' || clean === '972506400030';
}

module.exports = {
  cleanPhone,
  normalizePhoneForVeto,
  isAdminPhone,
};
