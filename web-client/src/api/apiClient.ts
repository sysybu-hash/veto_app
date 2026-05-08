import { clearJwt, getJwt } from "@/lib/authToken";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export { apiUrl, tunnelBypassHeaders };

function mergeHeaders(auth: HeadersInit, extra?: HeadersInit): Headers {
  const h = new Headers(extra);
  new Headers(auth).forEach((value, key) => {
    h.set(key, value);
  });
  return h;
}

/** Clears JWT storage/cookies and sends user to login (stale dev-user / expired tokens). */
async function invalidateSessionIfNeeded(res: Response): Promise<void> {
  if (typeof window === "undefined") return;
  const path = window.location.pathname;
  if (path.startsWith("/login") || path.startsWith("/register")) return;

  if (res.status !== 401 && res.status !== 400) return;

  let snippet = "";
  try {
    snippet = (await res.clone().text()).slice(0, 1200);
  } catch {
    return;
  }

  const shouldLogout =
    res.status === 401 ||
    /invalid value for (_id|user_id)/i.test(snippet) ||
    /\bunauthorized\b/i.test(snippet) ||
    /no token provided/i.test(snippet) ||
    /invalid or expired token/i.test(snippet);

  if (!shouldLogout) return;

  clearJwt();
  window.location.assign("/login");
}

/**
 * Headers for authenticated JSON requests (Bearer JWT + localtunnel bypass when needed).
 */
export function authJsonHeaders(): HeadersInit {
  const token = getJwt();
  if (!token) {
    throw new Error("Not authenticated");
  }
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
    ...tunnelBypassHeaders(),
  };
}

/**
 * Headers for authenticated multipart uploads. Do not set `Content-Type`:
 * the browser must supply the multipart boundary.
 */
export function authMultipartHeaders(): HeadersInit {
  const token = getJwt();
  if (!token) {
    throw new Error("Not authenticated");
  }
  return {
    Authorization: `Bearer ${token}`,
    ...tunnelBypassHeaders(),
  };
}

/**
 * Authenticated `fetch` — clears session and redirects to `/login` on 401 or
 * auth-related 400 (invalid Mongo id / Unauthorized).
 */
export async function authFetch(
  input: string | URL,
  init: RequestInit = {},
): Promise<Response> {
  const headers = mergeHeaders(authJsonHeaders(), init.headers);
  const res = await fetch(input, { ...init, headers });
  await invalidateSessionIfNeeded(res);
  return res;
}

/** Same as {@link authFetch} for multipart (no forced JSON Content-Type). */
export async function authMultipartFetch(
  input: string | URL,
  init: RequestInit = {},
): Promise<Response> {
  const headers = mergeHeaders(authMultipartHeaders(), init.headers);
  const res = await fetch(input, { ...init, headers });
  await invalidateSessionIfNeeded(res);
  return res;
}
