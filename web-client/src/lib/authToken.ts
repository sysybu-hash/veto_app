import { apiUrl } from "@/lib/env";

/**
 * Web JWT storage for VETO (parity with Flutter secure storage key `jwt`).
 * Dev: paste token in /login; production flows should use OTP here too.
 */
const STORAGE_KEY = "veto_jwt";

/** Primary cookie — must match `middleware.ts` and `jwtCookie.ts`. */
export const VETO_JWT_COOKIE_NAME = "veto_jwt";

/** Fallback names read by `middleware.ts` for the same JWT value. */
const LEGACY_SESSION_COOKIE_NAMES = ["veto_session", "jwt"] as const;

const COOKIE_MAX_AGE_SEC = 60 * 60 * 24 * 7;

function cookieBaseAttrs(): string {
  if (typeof window === "undefined") return "Path=/; SameSite=Lax";
  const isSecure = window.location.protocol === "https:";
  return `Path=/; SameSite=Lax${isSecure ? "; Secure" : ""}`;
}

/** Writes JWT to all cookies the Edge middleware may read (same encoded value). */
export function syncAllJwtCookies(token: string | null): void {
  if (typeof document === "undefined") return;
  const attrs = cookieBaseAttrs();
  if (token) {
    const enc = encodeURIComponent(token);
    document.cookie = `${VETO_JWT_COOKIE_NAME}=${enc}; Max-Age=${COOKIE_MAX_AGE_SEC}; ${attrs}`;
    for (const name of LEGACY_SESSION_COOKIE_NAMES) {
      document.cookie = `${name}=${enc}; Max-Age=${COOKIE_MAX_AGE_SEC}; ${attrs}`;
    }
  } else {
    document.cookie = `${VETO_JWT_COOKIE_NAME}=; Max-Age=0; ${attrs}`;
    for (const name of LEGACY_SESSION_COOKIE_NAMES) {
      document.cookie = `${name}=; Max-Age=0; ${attrs}`;
    }
  }
}

function hasPrimaryJwtCookie(): boolean {
  if (typeof document === "undefined") return false;
  const prefix = `${VETO_JWT_COOKIE_NAME}=`;
  return document.cookie.split(";").some((c) => c.trim().startsWith(prefix));
}

export function getJwt(): string | null {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

/**
 * Persist JWT: cookies first (so middleware sees them), then localStorage.
 * For navigation immediately after login, prefer `prepareLoginSession` so the
 * cookie round-trip completes before `router.push/replace`.
 */
export function setJwt(token: string): void {
  if (typeof window === "undefined") return;
  syncAllJwtCookies(token);
  try {
    window.localStorage.setItem(STORAGE_KEY, token);
  } catch {
    /* ignore */
  }
}

export function clearJwt(): void {
  if (typeof window === "undefined") return;
  syncAllJwtCookies(null);
  try {
    window.localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore */
  }
}

/** Call on app load so server actions / RSC see the same JWT as localStorage. */
export function syncJwtCookieFromStorage(): void {
  if (typeof window === "undefined") return;
  try {
    const token = window.localStorage.getItem(STORAGE_KEY);
    syncAllJwtCookies(token);
  } catch {
    /* ignore */
  }
}

/**
 * Sets cookies + storage, then waits until the browser has applied cookie updates
 * before client navigation (avoids middleware redirect to /login race).
 */
export async function prepareLoginSession(token: string): Promise<void> {
  setJwt(token);
  await new Promise<void>((resolve) => {
    requestAnimationFrame(() => {
      queueMicrotask(resolve);
    });
  });
  if (typeof document !== "undefined" && !hasPrimaryJwtCookie()) {
    syncAllJwtCookies(token);
    try {
      window.localStorage.setItem(STORAGE_KEY, token);
    } catch {
      /* ignore */
    }
    await new Promise<void>((r) => queueMicrotask(r));
  }
}

/** Best-effort decode of JWT payload `role` (no signature verification). */
export function getRoleFromJwt(): string | null {
  return decodeJwtField<string>("role");
}

/**
 * True only for the one real, Google-verified owner identity (see
 * `OWNER_EMAIL` in `backend/src/controllers/auth.controller.js`). Every JWT
 * issued via `/api/auth/view-as` also carries this so the switcher stays
 * available after switching views.
 */
export function isOwnerFromJwt(): boolean {
  return decodeJwtField<boolean>("isOwner") === true;
}

/**
 * True only for a JWT issued by `/api/auth/view-as` (the owner is currently
 * looking at a switched-to role), as opposed to the owner's own real login
 * session. Used to show a persistent "viewing as X" indicator so the owner
 * never loses track of which identity is active.
 */
export function isViewingAsFromJwt(): boolean {
  return decodeJwtField<boolean>("viewingAs") === true;
}

/** Best-effort decode of the user id (`userId` or `id` or `sub`). */
export function getUserIdFromJwt(): string | null {
  const direct =
    decodeJwtField<string>("userId") ??
    decodeJwtField<string>("id") ??
    decodeJwtField<string>("sub");
  return direct ? String(direct) : null;
}

/** sessionStorage key for the owner's real (non-view-as) JWT, stashed the
 * first time they switch views so "return to my view" can restore it
 * without a fresh Google login. Cleared once they're back on it. */
const OWNER_SESSION_KEY = "veto_owner_session_jwt";

/**
 * Owner-only role switch — calls `POST /api/auth/view-as` with the current
 * JWT and swaps in the returned token for the requested role, without a
 * logout/login round trip. Throws on non-owner/network failure so the
 * caller (the nav switcher) can surface an error instead of silently
 * failing to switch.
 */
export async function viewAs(role: "citizen" | "lawyer" | "admin"): Promise<void> {
  const current = getJwt();
  if (!current) throw new Error("Not logged in.");
  const res = await fetch(apiUrl("/api/auth/view-as"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${current}`,
    },
    body: JSON.stringify({ role }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}) as { error?: string });
    throw new Error(body.error || `view-as failed (${res.status})`);
  }
  const json = (await res.json()) as { token?: string };
  if (!json.token) throw new Error("No token in view-as response");

  // Stash the real owner session before switching away from it for the
  // first time, so "return to my view" can restore it without re-login.
  if (!isViewingAsFromJwt() && typeof window !== "undefined") {
    try {
      window.sessionStorage.setItem(OWNER_SESSION_KEY, current);
    } catch {
      /* ignore */
    }
  }

  await prepareLoginSession(json.token);
}

/** True if a stashed owner session is available to return to. */
export function hasOwnerSessionToReturnTo(): boolean {
  if (typeof window === "undefined") return false;
  try {
    return !!window.sessionStorage.getItem(OWNER_SESSION_KEY);
  } catch {
    return false;
  }
}

/** Restores the owner's real session stashed before their first view-as
 * switch, so they can leave a switched view without logging in again. */
export async function returnToOwnerView(): Promise<void> {
  if (typeof window === "undefined") return;
  let stashed: string | null = null;
  try {
    stashed = window.sessionStorage.getItem(OWNER_SESSION_KEY);
  } catch {
    /* ignore */
  }
  if (!stashed) throw new Error("No owner session to return to.");
  await prepareLoginSession(stashed);
  try {
    window.sessionStorage.removeItem(OWNER_SESSION_KEY);
  } catch {
    /* ignore */
  }
}

function decodeJwtField<T>(field: string): T | null {
  const token = getJwt();
  if (!token) return null;
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    const payload = JSON.parse(json) as Record<string, unknown>;
    const value = payload[field];
    return value === undefined ? null : (value as T);
  } catch {
    return null;
  }
}
