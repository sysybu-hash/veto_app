import { test, expect } from "@playwright/test";
import { fetchCitizenJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText } from "../fixtures/themeChecks";

/**
 * Phase B verification — the call UI (`CallShell` and its `_v2/components/*`)
 * was the component this whole UI overhaul started with (dark-on-dark
 * invisible text in light mode was the very first bug found), and got the
 * most direct token/`data-surface="stage"` fixes. It had never actually
 * been opened live in a browser after those fixes.
 *
 * Without a live Agora session (no second browser context acting as the
 * lawyer, no `agoraAppId` configured in this environment) we can't drive
 * the full in-call surface, but the pre-call/no-session fallback states
 * ARE reachable and ARE exactly the surfaces that had the invisible-text
 * bug (`CallShell.tsx`'s "no active session" branch, wrapped in
 * `data-surface="stage"`) — this checks both themes on that real,
 * rendered stage surface, matching the existing
 * `sos-call-vault.spec.ts` route-mount smoke test but adding the actual
 * theme regression check.
 */

test.describe("call UI — pre-call/no-session states", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_CITIZEN_CALL_PHONE ?? "+972500000002",
    });
  });

  test.beforeEach(async ({ page }) => {
    await injectJwt(page, token);
  });

  for (const theme of ["light", "dark"] as const) {
    test(`/call/[channel] no-session fallback (${theme}) has no invisible text`, async ({ page }) => {
      await setTheme(page, theme);
      await page.goto("/call/e2e-no-session-channel");
      await expect(page.getByText(/אין סשן|No active session/i)).toBeVisible({ timeout: 10_000 });
      await assertNoInvisibleText(page);
    });
  }
});
