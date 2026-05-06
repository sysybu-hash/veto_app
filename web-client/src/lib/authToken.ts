/**
 * Web JWT storage for VETO (parity with Flutter secure storage key `jwt`).
 * Dev: paste token in /login; production flows should use OTP here too.
 */
const STORAGE_KEY = "veto_jwt";

/** Must match `jwtCookie.ts` — duplicated here to avoid importing server code in client bundles. */
const COOKIE_NAME = "veto_jwt";
const COOKIE_MAX_AGE_SEC = 60 * 60 * 24 * 7;

function syncJwtCookie(token: string | null) {
  if (typeof document === "undefined") return;
  const isSecure = window.location.protocol === "https:";
  if (token) {
    const enc = encodeURIComponent(token);
    document.cookie = `${COOKIE_NAME}=${enc}; Path=/; Max-Age=${COOKIE_MAX_AGE_SEC}; SameSite=Lax${isSecure ? "; Secure" : ""}`;
  } else {
    document.cookie = `${COOKIE_NAME}=; Path=/; Max-Age=0; SameSite=Lax${isSecure ? "; Secure" : ""}`;
  }
}

export function getJwt(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export function setJwt(token: string): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(STORAGE_KEY, token);
    syncJwtCookie(token);
  } catch {
    /* ignore */
  }
}

export function clearJwt(): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.removeItem(STORAGE_KEY);
    syncJwtCookie(null);
  } catch {
    /* ignore */
  }
}

/** Call on app load so server actions RSC see the same JWT as localStorage. */
export function syncJwtCookieFromStorage(): void {
  if (typeof window === "undefined") return;
  try {
    const token = window.localStorage.getItem(STORAGE_KEY);
    syncJwtCookie(token);
  } catch {
    /* ignore */
  }
}

/** Best-effort decode of JWT payload `role` (no signature verification). */
export function getRoleFromJwt(): string | null {
  const token = getJwt();
  if (!token) return null;
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    const payload = JSON.parse(json) as { role?: string };
    return typeof payload.role === "string" ? payload.role : null;
  } catch {
    return null;
  }
}
