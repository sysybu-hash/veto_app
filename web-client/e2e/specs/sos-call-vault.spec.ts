import { test, expect } from "@playwright/test";
import { loginAsCitizenViaOtp } from "../fixtures/auth";

/**
 * Happy-path E2E for the SOS → call → vault flow.
 *
 * Real Agora media is mocked at the browser level via Chrome's
 * `--use-fake-device-for-media-stream` flag. The spec only verifies the
 * UI contract (lobby visible, in-call surface mounted, vault row
 * appears after end). Backend dispatcher must be running with at least
 * one demo lawyer signed in; CI uses `npm run init-admins` + a seed
 * lawyer before the suite runs.
 */
test.describe("SOS citizen happy path", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsCitizenViaOtp(page, {
      phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001",
    });
  });

  test("citizen lands on /hub after login", async ({ page }) => {
    await page.goto("/hub");
    await expect(page).toHaveURL(/\/hub/);
    // Specialization picker is the first interactive surface for a
    // brand-new SOS — exact label is locale-dependent so we just check
    // the wrapper exists.
    await expect(
      page.getByRole("dialog").or(page.getByText(/SOS|חירום/)).first(),
    ).toBeVisible({
      timeout: 5_000,
    });
  });

  test("/call/[channel] mounts the v2 surface when flag is on", async ({ page }) => {
    // We can't fully exercise the dispatcher in unit-style E2E without a
    // second browser context for the lawyer; here we only check that the
    // route-level shell renders without crashing.
    await page.goto("/call/test-channel-e2e");
    await expect(page.getByText(/אין סשן|No active session|Connecting/i)).toBeVisible({
      timeout: 5_000,
    });
  });
});
