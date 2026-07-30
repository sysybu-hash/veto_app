import { test, expect } from "@playwright/test";
import jwt from "jsonwebtoken";
import { injectJwt } from "../fixtures/auth";

/**
 * Phase F verification — the owner-only role switcher (`POST /api/auth/view-as`)
 * replaces the old shared-password dev-login bypass for real production use.
 * A real Google OAuth login can't be automated in Playwright, so this mints a
 * JWT locally with the same `JWT_SECRET` the test backend uses, carrying
 * `isOwner: true` exactly as `googleAuth` would for the configured
 * `OWNER_EMAIL` — this is equivalent to what a real owner login produces,
 * without needing a live Google account in CI.
 */

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:5001";

function mintFakeOwnerJwt(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET is not set — required to mint a test owner JWT for view-as.spec.ts");
  }
  return jwt.sign(
    { userId: "e2e-owner-test-id", role: "user", full_name: "E2E Owner", preferred_language: "he", isOwner: true },
    secret,
    { expiresIn: "1h" },
  );
}

test.describe("owner view-as switcher", () => {
  test("non-owner JWT is rejected with 403", async ({ request }) => {
    const secret = process.env.JWT_SECRET;
    if (!secret) throw new Error("JWT_SECRET is not set");
    const nonOwnerToken = jwt.sign(
      { userId: "e2e-non-owner", role: "user", isOwner: false },
      secret,
      { expiresIn: "1h" },
    );
    const res = await request.post(`${API_BASE}/api/auth/view-as`, {
      headers: { Authorization: `Bearer ${nonOwnerToken}` },
      data: { role: "admin" },
    });
    expect(res.status()).toBe(403);
  });

  for (const target of [
    { role: "citizen", homeRoute: "/hub", expectedText: /SOS|חירום/ },
    { role: "lawyer", homeRoute: "/dashboard", expectedText: /דשבורד|עורך דין/ },
    { role: "admin", homeRoute: "/admin/dashboard", expectedText: /ניהול|VETO/ },
  ] as const) {
    test(`owner can view-as ${target.role} and reach ${target.homeRoute}`, async ({ page, request }) => {
      const ownerToken = mintFakeOwnerJwt();
      const res = await request.post(`${API_BASE}/api/auth/view-as`, {
        headers: { Authorization: `Bearer ${ownerToken}` },
        data: { role: target.role },
      });
      expect(res.ok()).toBeTruthy();
      const json = (await res.json()) as { token?: string };
      expect(json.token).toBeTruthy();

      await injectJwt(page, json.token!);
      await page.goto(target.homeRoute);
      await page.waitForLoadState("networkidle");
      await expect(page).not.toHaveURL(/\/login/);
      await expect(page.getByText(target.expectedText).first()).toBeVisible({ timeout: 10_000 });
    });
  }
});
