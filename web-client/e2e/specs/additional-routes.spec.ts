import { test, expect } from "@playwright/test";
import { fetchCitizenJwt, fetchDevLoginJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText, captureScreenshot } from "../fixtures/themeChecks";

/**
 * Phase E.1 — closes the remaining gap from the full-site route mapping:
 * every route below had ZERO Playwright coverage before this spec (public
 * pages nobody thought to check because they're rarely visited, citizen
 * settings sub-pages, and admin pages beyond the dashboard/lawyers list).
 * Same hard gate as every other theme spec (assertNoInvisibleText) plus a
 * full-page screenshot per route/theme for manual visual review, since
 * automated checks can't catch overlap/spacing/RTL-alignment issues.
 */

const PUBLIC_ROUTES = ["/register/lawyer", "/cookies", "/payments/return", "/~offline"];

const CITIZEN_ROUTES = [
  "/privacy-rights",
  "/transparency",
  "/settings/profile",
  "/settings/security",
  "/settings/notifications",
  "/settings/billing",
  "/vault/generator",
];

test.describe("additional coverage — public routes", () => {
  for (const theme of ["light", "dark"] as const) {
    for (const route of PUBLIC_ROUTES) {
      test(`${route} (${theme}) has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await assertNoInvisibleText(page);
        await captureScreenshot(page, route.replace(/\//g, "_") || "root", theme);
      });
    }
  }
});

test.describe("additional coverage — onboarding (fresh citizen)", () => {
  test("onboarding has no invisible text in both themes", async ({ page, request }) => {
    // Onboarding only renders its full form for an account that hasn't
    // completed it yet — use a dedicated phone so this doesn't collide
    // with the shared E2E_CITIZEN_PHONE account used elsewhere (already
    // onboarded, which would just redirect away from /onboarding).
    const token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_ONBOARDING_PHONE ?? "+972500000099",
    });
    for (const theme of ["light", "dark"] as const) {
      await setTheme(page, theme);
      await injectJwt(page, token);
      await page.goto("/onboarding");
      await page.waitForLoadState("networkidle");
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_onboarding", theme);
    }
  });
});

test.describe("additional coverage — citizen routes", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001",
    });
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    for (const route of CITIZEN_ROUTES) {
      test(`${route} (${theme}) has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await expect(page).not.toHaveURL(/\/login/);
        await assertNoInvisibleText(page);
        await captureScreenshot(page, route.replace(/\//g, "_"), theme);
      });
    }
  }
});

test.describe("additional coverage — admin routes", () => {
  let token: string;
  let sampleUserId: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchDevLoginJwt(request, { role: "admin" });
    const apiBase = process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:5001";
    const res = await request.get(`${apiBase}/api/admin/users-with-status`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = (await res.json()) as { users?: Array<{ _id: string }> };
    sampleUserId = json.users?.[0]?._id ?? "000000000000000000000000";
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    for (const route of ["/admin", "/admin/settings", "/admin/vault"]) {
      test(`${route} (${theme}) has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await expect(page).not.toHaveURL(/\/login/);
        await assertNoInvisibleText(page);
        await captureScreenshot(page, route.replace(/\//g, "_"), theme);
      });
    }

    test(`/admin/users/[id] (${theme}) has no invisible text`, async ({ page }) => {
      await setTheme(page, theme);
      await page.goto(`/admin/users/${sampleUserId}`);
      await page.waitForLoadState("networkidle");
      await expect(page).not.toHaveURL(/\/login/);
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_admin_users_id", theme);
    });
  }
});
