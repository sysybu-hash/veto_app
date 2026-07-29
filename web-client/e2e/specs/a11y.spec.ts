import { test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import type { Result } from "axe-core";
import { fetchCitizenJwt, fetchDevLoginJwt, injectJwt } from "../fixtures/auth";
import { setTheme } from "../fixtures/themeChecks";

function reportViolations(route: string, theme: string, violations: Result[]): void {
  const summary = violations.map((v) => ({ id: v.id, impact: v.impact, nodes: v.nodes.length }));
  test.info().annotations.push({ type: "axe-violations", description: JSON.stringify(summary) });
  if (summary.length > 0) {
    console.log(`[a11y] ${route} (${theme}):`, summary);
  }
}

/**
 * Phase D.1 — automated accessibility scan (axe-core) across every route
 * already covered by a Playwright spec (public + the Phase B authenticated
 * additions). Report-only for now: this is the FIRST time axe has run
 * against this app, so real findings are expected and get triaged before
 * this can become a blocking gate (same rollout pattern used for the
 * `npm audit` gates — see ci.yml).
 */

const PUBLIC_ROUTES = ["/", "/login", "/register", "/pricing", "/privacy", "/terms"];

test.describe("accessibility — public routes", () => {
  for (const theme of ["light", "dark"] as const) {
    for (const route of PUBLIC_ROUTES) {
      test(`${route} (${theme}) axe scan`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        const results = await new AxeBuilder({ page }).analyze();
        reportViolations(route, theme, results.violations);
      });
    }
  }
});

test.describe("accessibility — authenticated routes", () => {
  let citizenToken: string;
  let adminToken: string;
  let lawyerToken: string;

  test.beforeAll(async ({ request }) => {
    [citizenToken, adminToken, lawyerToken] = await Promise.all([
      fetchCitizenJwt(request, { phone: process.env.E2E_CITIZEN_PHONE ?? "+972500000001" }),
      fetchDevLoginJwt(request, { role: "admin" }),
      fetchDevLoginJwt(request, { role: "lawyer" }),
    ]);
  });

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
  const ADMIN_ROUTES = ["/admin/dashboard", "/admin/lawyers"];

  for (const route of CITIZEN_ROUTES) {
    test(`citizen ${route} axe scan`, async ({ page }) => {
      await injectJwt(page, citizenToken);
      await page.goto(route);
      await page.waitForLoadState("networkidle");
      const results = await new AxeBuilder({ page }).analyze();
      reportViolations(route, "citizen", results.violations);
    });
  }

  for (const route of ADMIN_ROUTES) {
    test(`admin ${route} axe scan`, async ({ page }) => {
      await injectJwt(page, adminToken);
      await page.goto(route);
      await page.waitForLoadState("networkidle");
      const results = await new AxeBuilder({ page }).analyze();
      reportViolations(route, "admin", results.violations);
    });
  }

  test("lawyer /dashboard axe scan", async ({ page }) => {
    await injectJwt(page, lawyerToken);
    await page.goto("/dashboard");
    await page.waitForLoadState("networkidle");
    const results = await new AxeBuilder({ page }).analyze();
    reportViolations("/dashboard", "lawyer", results.violations);
  });
});
