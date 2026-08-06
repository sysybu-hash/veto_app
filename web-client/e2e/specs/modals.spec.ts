import { test, expect } from "@playwright/test";
import { fetchCitizenJwt, injectJwt } from "../fixtures/auth";
import { setTheme, assertNoInvisibleText, captureScreenshot } from "../fixtures/themeChecks";

/**
 * Phase E.2 — modal/dialog-specific visual checks. This is exactly the
 * class of bug found earlier this session (`text-inverse` misused on a
 * permanently-dark/colored surface): modals often introduce their own
 * `data-surface="stage"` wrapper or fixed-color backdrop that a page-level
 * theme check never opens, so they need to be driven open explicitly.
 */

test.describe("modal — CookieConsent (fresh visitor)", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`renders correctly on first visit (${theme})`, async ({ page }) => {
      await setTheme(page, theme);
      await page.goto("/");
      await page.waitForLoadState("networkidle");
      await expect(page.getByText("העדפות פרטיות")).toBeVisible({ timeout: 5_000 });
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_modal_cookie_consent", theme);
    });
  }
});

test.describe("modal — SpecializationDialog (via hub SOS confirm flow)", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_MODALS_PHONE ?? "+972500000098",
    });
  });

  for (const theme of ["light", "dark"] as const) {
    test(`opens after confirming SOS (${theme})`, async ({ page }) => {
      await setTheme(page, theme);
      await injectJwt(page, token);
      await page.goto("/hub");
      await page.waitForLoadState("networkidle");
      await page.getByRole("button", { name: "SOS" }).click();
      await page.getByRole("dialog").getByRole("button", { name: /שלח SOS|confirm/i }).click();
      await expect(page.getByText(/בחר את סוג עורך הדין|specialization/i).first()).toBeVisible({ timeout: 5_000 });
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_modal_specialization", theme);
    });
  }
});

test.describe("modal — VaultUploadModal", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001",
    });
  });

  for (const theme of ["light", "dark"] as const) {
    test(`opens from /vault upload button (${theme})`, async ({ page }) => {
      await setTheme(page, theme);
      await injectJwt(page, token);
      await page.goto("/vault");
      await page.waitForLoadState("networkidle");
      await page.getByRole("button", { name: /העלאת קובץ|upload file/i }).click();
      await expect(page.getByRole("dialog")).toBeVisible({ timeout: 5_000 });
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_modal_vault_upload", theme);
    });
  }
});

test.describe("modal — CreateEventModal", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001",
    });
  });

  for (const theme of ["light", "dark"] as const) {
    test(`opens from /calendar new-event button (${theme})`, async ({ page }) => {
      await setTheme(page, theme);
      await injectJwt(page, token);
      await page.goto("/calendar");
      await page.waitForLoadState("networkidle");
      // /calendar legitimately offers two "new event" CTAs: the toolbar one in
      // the header, and a second inside the agenda empty state when the day has
      // no events. Scope to the header so the locator stays unambiguous whether
      // or not the account has events.
      await page
        .locator("header")
        .getByRole("button", { name: /אירוע חדש|new event/i })
        .click();
      await expect(page.getByRole("dialog")).toBeVisible({ timeout: 5_000 });
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_modal_create_event", theme);
    });
  }
});

test.describe("modal — CreateTaskModal", () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    token = await fetchCitizenJwt(request, {
      phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001",
    });
  });

  for (const theme of ["light", "dark"] as const) {
    test(`opens from /productivity new-task button (${theme})`, async ({ page }) => {
      await setTheme(page, theme);
      await injectJwt(page, token);
      await page.goto("/productivity");
      await page.waitForLoadState("networkidle");
      await page.getByRole("button", { name: "משימות" }).click();
      await page.getByRole("button", { name: /משימה חדשה|new task/i }).click();
      await expect(page.getByRole("dialog")).toBeVisible({ timeout: 5_000 });
      await assertNoInvisibleText(page);
      await captureScreenshot(page, "_modal_create_task", theme);
    });
  }
});
