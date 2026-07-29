import { test } from "@playwright/test";
import { setTheme, assertNoInvisibleText, countSubstringOverrides } from "../fixtures/themeChecks";

/**
 * Phase 8 verification — theme correctness across public routes that
 * don't require auth.
 *
 * The hard gate: no visible element has a text color that is
 * (near-)identical to its own background — the failure class that made
 * the call UI invisible in light mode. A second, informational-only
 * test reports how many `.veto-light [class*="..."]` substring-override
 * rules are still loaded (see globals.css) — these are the Phase 3/7
 * migration target and are only removed once every route is migrated,
 * so they're tracked but don't block the suite.
 *
 * Runs against routes that render without authentication so it stays
 * runnable without a full backend/DB/OTP setup. See
 * admin-dashboard/lawyer-dashboard/citizen-authenticated/call-ui specs
 * for the same checks against authenticated routes.
 */

const PUBLIC_ROUTES = ["/", "/login", "/register", "/pricing", "/privacy", "/terms"];

for (const theme of ["light", "dark"] as const) {
  test.describe(`theme correctness — ${theme} mode`, () => {
    for (const route of PUBLIC_ROUTES) {
      // Hard gate: this is the actual regression check (the exact failure
      // class that made the call UI invisible in light mode). Must always
      // pass — a route failing this has a real dark-on-dark/light-on-light
      // bug, not a "known incomplete migration" situation.
      test(`${route} has no invisible text`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        await assertNoInvisibleText(page);
      });

      // Informational only: see countSubstringOverrides doc comment.
      test(`${route} substring-override usage (informational)`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        const count = await countSubstringOverrides(page);
        test.info().annotations.push({
          type: "substring-selectors-loaded",
          description: String(count),
        });
      });
    }
  });
}
