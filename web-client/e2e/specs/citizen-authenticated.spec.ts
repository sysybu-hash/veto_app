import { test, expect } from "@playwright/test";
import { fetchCitizenJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText, captureScreenshot } from "../fixtures/themeChecks";

/**
 * Phase B verification — citizen routes beyond the SOS happy path
 * (`sos-call-vault.spec.ts` only covers /hub) were migrated via codemod
 * + code review but never opened live in a browser.
 *
 * The JWT is fetched ONCE in `beforeAll` and injected per-test — the OTP
 * round trip is rate limited (`otpLimiter`: 5/10min/IP — see
 * `backend/src/routes/auth.routes.js`), and this spec has 16 tests
 * (8 routes x 2 themes), which blows past that budget if each test
 * re-authenticates.
 */

const CITIZEN_ROUTES = [
  "/hub",
  "/chat",
  "/vault",
  "/productivity",
  "/calendar",
  "/settings",
  "/family",
  "/plans",
];

test.describe("citizen authenticated routes", () => {
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
