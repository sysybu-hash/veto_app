/**
 * Normalize phone input to E.164 (+...) — must match backend `normalizePhoneForVeto`.
 * Accepts +972501111111, 972501111111, 0501111111, 501111111 (IL mobile), other intl.
 */
export function normalizePhoneForVeto(
  raw: string | null | undefined,
): string | null {
  if (raw == null) return null;
  const trimmed = String(raw).trim();
  if (!trimmed) return null;

  const s = trimmed.replace(/[\s\-().]/g, "");
  if (!s) return null;

  let d: string;
  if (s.startsWith("+")) {
    d = s.slice(1).replace(/\D/g, "");
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  d = s.replace(/\D/g, "");
  if (!d) return null;

  if (d.startsWith("972")) {
    if (!/^[1-9]\d{7,14}$/.test(d)) return null;
    return `+${d}`;
  }

  if (d.startsWith("0")) {
    const rest = d.slice(1);
    if (!/^[1-9]\d{6,12}$/.test(rest)) return null;
    return `+972${rest}`;
  }

  if (d.length === 9 && d.startsWith("5")) {
    return `+972${d}`;
  }

  if (/^[1-9]\d{7,14}$/.test(d)) {
    return `+${d}`;
  }

  return null;
}
