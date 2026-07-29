import { test, expect } from "@playwright/test";
import { fetchDevLoginJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText } from "../fixtures/themeChecks";

/**
 * Phase B verification — the admin console was migrated to semantic
 * tokens via codemod + code review during the UI overhaul, but never
 * actually opened in a live browser (it requires auth). This closes
 * that gap: real login via the dev-only `/api/auth/dev-login` shortcut,
 * then the same invisible-text hard gate used on public routes.
 *
 * The JWT is fetched ONCE in `beforeAll` and injected per-test — dev-login
 * shares the `/api/auth` mount-level rate limiter (20 req/15min/IP), which
 * a per-test login call exhausts within a handful of route/theme combos.
 */

const ADMIN_ROUTES = ["/admin/dashboard", "/admin/lawyers"];

test.describe("admin console", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchDevLoginJwt(request, { role: "admin" });
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    for (const route of ADMIN_ROUTES) {
      test(`${route} (${theme}) has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await expect(page).not.toHaveURL(/\/login/);
        await assertNoInvisibleText(page);
      });
    }
  }
});
