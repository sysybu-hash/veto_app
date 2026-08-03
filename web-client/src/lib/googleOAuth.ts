/**
 * Shared Google OAuth (implicit) helpers for /login and /register.
 *
 * Redirect URI is always `{origin}/login` so Authorized redirect URIs in
 * Google Cloud stay a single path. Register starts the same flow; the
 * callback lands on /login and completes there.
 */

export const GOOGLE_OAUTH_STATE_KEY = "veto_google_oauth_state";

export function googleOAuthRedirectUri(): string {
  if (typeof window !== "undefined") {
    return new URL("/login", window.location.origin).href;
  }
  const fromEnv = process.env.NEXT_PUBLIC_GOOGLE_OAUTH_REDIRECT_URI?.trim();
  if (fromEnv) {
    try {
      return new URL("/login", new URL(fromEnv).origin).href;
    } catch {
      return fromEnv;
    }
  }
  return "http://localhost:3000/login";
}

export function buildGoogleImplicitAuthUrl(
  clientId: string,
  redirectUri: string,
  state: string,
): string {
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "token",
    scope: "openid email profile",
    include_granted_scopes: "true",
    prompt: "select_account",
    state,
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

export type BeginGoogleOAuthResult =
  | { ok: true }
  | {
      ok: false;
      reason:
        | "missing_client_id"
        | "storage"
        | "legacy_redirect";
      legacyUrl?: string;
    };

/**
 * Starts the Google implicit OAuth redirect. On success the browser navigates
 * away; callers should treat `{ ok: true }` as "navigation in progress".
 */
export function beginGoogleImplicitLogin(options?: {
  next?: string | null;
}): BeginGoogleOAuthResult {
  const legacyGoogleLoginUrl =
    process.env.NEXT_PUBLIC_GOOGLE_LOGIN_URL?.trim() ?? "";
  if (legacyGoogleLoginUrl) {
    window.location.href = legacyGoogleLoginUrl;
    return { ok: false, reason: "legacy_redirect", legacyUrl: legacyGoogleLoginUrl };
  }

  const googleClientId =
    process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID?.trim() ?? "";
  if (!googleClientId) {
    return { ok: false, reason: "missing_client_id" };
  }

  const redirectUri = googleOAuthRedirectUri();
  const state =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

  try {
    sessionStorage.setItem(
      GOOGLE_OAUTH_STATE_KEY,
      JSON.stringify({ state, next: options?.next ?? null }),
    );
  } catch {
    return { ok: false, reason: "storage" };
  }

  window.location.assign(
    buildGoogleImplicitAuthUrl(googleClientId, redirectUri, state),
  );
  return { ok: true };
}
