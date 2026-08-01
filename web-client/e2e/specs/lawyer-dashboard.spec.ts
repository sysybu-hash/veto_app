import { test, expect } from "@playwright/test";
import { fetchDevLoginJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText, captureScreenshot } from "../fixtures/themeChecks";

/**
 * Phase B verification — same rationale as admin-dashboard.spec.ts:
 * `(lawyer)/dashboard` was migrated via codemod + code review but never
 * opened live in a browser (requires auth). Token fetched once in
 * `beforeAll` — see admin-dashboard.spec.ts for why (auth rate limiter).
 *
 * `/vault` and `/chat` are shared citizen/lawyer routes (no dedicated
 * `(lawyer)` page — role-aware rendering off the same components), but
 * had never been opened live under a *lawyer* JWT specifically, nor had
 * any of these three routes ever had a screenshot captured for manual
 * review.
 */

const LAWYER_ROUTES = ["/dashboard", "/vault", "/chat"];

test.describe("lawyer dashboard", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchDevLoginJwt(request, { role: "lawyer" });
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    for (const route of LAWYER_ROUTES) {
      test(`${route} (${theme}) has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await expect(page).not.toHaveURL(/\/login/);
        await assertNoInvisibleText(page);
        await captureScreenshot(page, `_lawyer${route.replace(/\//g, "_")}`, theme);
      });
    }
  }
});
