import type { Page } from "@playwright/test";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:5001";

/**
 * Logs the page in as a citizen using the dev-only OTP-in-JSON path.
 * Backend must be running with `RETURN_OTP_IN_JSON=1` (only honoured
 * outside of production).
 *
 * Stores the resulting JWT in the same cookie the middleware reads so
 * subsequent navigations are authenticated.
 */
export async function loginAsCitizenViaOtp(
  page: Page,
  { phone }: { phone: string },
): Promise<void> {
  // Step 1 — request OTP (returns the code in the JSON body in dev).
  const reqRes = await page.request.post(`${API_BASE}/api/auth/request-otp`, {
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
  const verifyRes = await page.request.post(`${API_BASE}/api/auth/verify-otp`, {
    data: { phone, otp },
  });
  if (!verifyRes.ok()) {
    throw new Error(`verify-otp failed: ${verifyRes.status()}`);
  }
  const verifyJson = (await verifyRes.json()) as { token?: string; jwt?: string };
  const token = verifyJson.token ?? verifyJson.jwt;
  if (!token) throw new Error("No JWT in verify-otp response");

  // Step 3 — drop the JWT into the cookie the middleware reads.
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

  // Mirror to localStorage too, where the API client also reads from.
  await page.addInitScript(([t]) => {
    try {
      localStorage.setItem("veto_jwt", t);
    } catch {
      /* ignore */
    }
  }, [token]);
}
