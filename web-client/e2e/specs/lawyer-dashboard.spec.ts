import { test, expect } from "@playwright/test";
import { fetchDevLoginJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText } from "../fixtures/themeChecks";

/**
 * Phase B verification — same rationale as admin-dashboard.spec.ts:
 * `(lawyer)/dashboard` was migrated via codemod + code review but never
 * opened live in a browser (requires auth). Token fetched once in
 * `beforeAll` — see admin-dashboard.spec.ts for why (auth rate limiter).
 */

test.describe("lawyer dashboard", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchDevLoginJwt(request, { role: "lawyer" });
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    test(`/dashboard (${theme}) has no invisible text`, async ({ page }) => {
      await setTheme(page, theme);
      await page.goto("/dashboard");
      await page.waitForLoadState("networkidle");
      await expect(page).not.toHaveURL(/\/login/);
      await assertNoInvisibleText(page);
    });
  }
});
