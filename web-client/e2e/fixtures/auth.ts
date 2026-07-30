import type { APIRequestContext, Page } from "@playwright/test";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:5001";

/**
 * Drops a JWT into the cookie the middleware reads and mirrors it to
 * localStorage (where the API client also reads from), so subsequent
 * navigations are authenticated. Shared by every dev-login fixture below.
 */
export async function injectJwt(page: Page, token: string): Promise<void> {
  const url = new URL(page.url() === "about:blank" ? "http://localhost:3000" : page.url());
  await page.context().addCookies([
    {
      name: "veto_jwt",
      value: token,
      domain: url.hostname,
      path: "/",
      httpOnly: false,
      secure: false,
      sameSite: "Lax",
    },
  ]);
  await page.addInitScript(([t]) => {
    try {
      localStorage.setItem("veto_jwt", t);
    } catch {
      /* ignore */
    }
  }, [token]);
}

/**
 * Logs the page in as a citizen using the dev-only OTP-in-JSON path.
 * Backend must be running with `RETURN_OTP_IN_JSON=1` (only honoured
 * outside of production).
 *
 * Stores the resulting JWT in the same cookie the middleware reads so
 * subsequent navigations are authenticated.
 */
/**
 * Fetches a citizen JWT via the OTP round-trip without touching a page —
 * intended to be called ONCE (e.g. in `test.beforeAll`) and reused across
 * many tests via `injectJwt`, since `request-otp`/`verify-otp` are rate
 * limited (`otpLimiter`: 5/10min/IP, `verifyOtpLimiter`: 8/10min/phone —
 * see `backend/src/routes/auth.routes.js`) and a per-test login exhausts
 * that budget within a handful of tests.
 */
export async function fetchCitizenJwt(
  request: APIRequestContext,
  { phone }: { phone: string },
): Promise<string> {
  // Ensure the test account exists (idempotent — register returns 409 if
  // it's already there, which we ignore).
  await request.post(`${API_BASE}/api/auth/register`, {
    data: { full_name: "E2E Test Citizen", phone, role: "user" },
  });

  // Step 1 — request OTP (returns the code in the JSON body in dev).
  const reqRes = await request.post(`${API_BASE}/api/auth/request-otp`, {
    data: { phone },
  });
  if (!reqRes.ok()) {
    throw new Error(`request-otp failed: ${reqRes.status()}`);
  }
  const reqJson = (await reqRes.json()) as { otp?: string };
  const otp = reqJson.otp;
  if (!otp) {
    throw new Error(
      "OTP not returned in JSON — set RETURN_OTP_IN_JSON=1 in dev backend.",
    );
  }

  // Step 2 — verify and grab JWT.
  const verifyRes = await request.post(`${API_BASE}/api/auth/verify-otp`, {
    data: { phone, otp },
  });
  if (!verifyRes.ok()) {
    throw new Error(`verify-otp failed: ${verifyRes.status()}`);
  }
  const verifyJson = (await verifyRes.json()) as { token?: string; jwt?: string };
  const token = verifyJson.token ?? verifyJson.jwt;
  if (!token) throw new Error("No JWT in verify-otp response");
  return token;
}

export async function loginAsCitizenViaOtp(
  page: Page,
  { phone }: { phone: string },
): Promise<void> {
  const token = await fetchCitizenJwt(page.request, { phone });
  await injectJwt(page, token);
}

/**
 * Logs the page in as `admin`/`lawyer`/`citizen` using the dev-only
 * `POST /api/auth/dev-login` shortcut (`backend/src/controllers/auth.controller.js`,
 * `devLogin`). Backend must be running with `NODE_ENV !== 'production'`
 * AND `DEV_LOGIN_ENABLED=1` — there is no production override; the
 * endpoint cannot run at all when `NODE_ENV==='production'`.
 *
 * Requires `DEV_LOGIN_USERNAME`/`DEV_LOGIN_PASSWORD` to be set in the test
 * environment (local `.env` or CI) — no hardcoded fallback here, since a
 * previously-hardcoded default credential ended up leaked into git
 * history. Pick any local-only value; it has no bearing on production.
 *
 * Unlike `loginAsCitizenViaOtp`, this needs no phone/SMS round trip —
 * it's what makes admin/lawyer-dashboard specs possible without real
 * credentials.
 *
 * Fetches a role JWT without touching a page — intended to be called ONCE
 * (e.g. in `test.beforeAll`) and reused across many tests via `injectJwt`.
 * `/api/auth/*` shares a mount-level `authLimiter` (20 req/15min/IP), which
 * a per-test dev-login call burns through quickly across a multi-route,
 * multi-theme spec.
 */
export async function fetchDevLoginJwt(
  request: APIRequestContext,
  { role }: { role: "admin" | "lawyer" | "citizen" },
): Promise<string> {
  const username = process.env.DEV_LOGIN_USERNAME;
  const password = process.env.DEV_LOGIN_PASSWORD;
  if (!username || !password) {
    throw new Error(
      "DEV_LOGIN_USERNAME/DEV_LOGIN_PASSWORD are not set — set them in backend/.env (local) or CI env.",
    );
  }
  const res = await request.post(`${API_BASE}/api/auth/dev-login`, {
    data: { username, password, role },
  });
  if (!res.ok()) {
    throw new Error(
      `dev-login failed (${res.status()}) — is the backend running with NODE_ENV!=='production' and DEV_LOGIN_ENABLED=1?`,
    );
  }
  const json = (await res.json()) as { token?: string };
  if (!json.token) throw new Error("No JWT in dev-login response");
  return json.token;
}

export async function loginAsRoleViaDevLogin(
  page: Page,
  { role }: { role: "admin" | "lawyer" | "citizen" },
): Promise<void> {
  const token = await fetchDevLoginJwt(page.request, { role });
  await injectJwt(page, token);
}
