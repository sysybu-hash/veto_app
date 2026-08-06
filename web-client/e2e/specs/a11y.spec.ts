import { expect, test } from "@playwright/test";
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

/** Fails the test on any violation, naming the offending nodes. */
function assertNoViolations(route: string, who: string, violations: Result[]): void {
  expect(
    violations,
    `axe violations on ${route} (${who}): ${JSON.stringify(
      violations.map((v) => ({
        id: v.id,
        nodes: v.nodes.map((n) => ({
          target: n.target.join(" "),
          html: n.html.slice(0, 200),
          why: (n.failureSummary || "").replace(/\n/g, " ").slice(0, 200),
        })),
      })),
      null,
      2,
    )}`,
  ).toHaveLength(0);
}

/**
 * Shared scan settings. Reduced motion is emulated so axe never samples an
 * element mid-fade (which blends colours and produced a ~1-in-3 flake), and
 * because it is a real user setting the app supports.
 */
async function prepare(page: import("@playwright/test").Page, route: string) {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto(route);
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(400);
}

/**
 * Automated accessibility scan (axe-core).
 *
 * PUBLIC routes are a BLOCKING gate: every violation found on the first run
 * (all of them colour-contrast, from brand gold used as text on light surfaces
 * and as a fill under white text) has been fixed via the --brand-text /
 * --brand-fg token split in globals.css. These pages are the marketing surface
 * and the EN 301 549 / WCAG 2.1 AA obligation — a regression here must fail the
 * build, not print a warning. Fix the violation rather than relaxing this.
 *
 * AUTHENTICATED routes are now blocking too. Their findings were `region`
 * (page content outside any landmark — fixed by giving each route group's
 * layout a single <main>), `heading-order` (h1 → h3 jumps), and one empty
 * table header. Pages must NOT render their own <main>: the group layout owns
 * that landmark, and a second one is a `landmark-no-duplicate-main` failure.
 */

const PUBLIC_ROUTES = [
  "/",
  "/login",
  "/register",
  "/register/lawyer",
  "/pricing",
  "/privacy",
  "/terms",
  "/contact",
  "/cookies",
  "/playbooks",
  "/accessibility",
  "/transparency",
];

test.describe("accessibility — public routes", () => {
  for (const theme of ["light", "dark"] as const) {
    for (const route of PUBLIC_ROUTES) {
      test(`${route} (${theme}) axe scan`, async ({ page }) => {
        // Scan with reduced motion on. Two reasons: it is a real user setting
        // the app must support, and it makes the gate deterministic — sampling
        // an element mid-fade makes axe compute a blended colour, which used to
        // fail this scan roughly one run in three under load.
        await page.emulateMedia({ reducedMotion: "reduce" });
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        // Reveal scroll-triggered sections so the scan covers the whole page.
        await page.evaluate(async () => {
          const step = window.innerHeight / 2;
          for (let y = 0; y < document.body.scrollHeight; y += step) {
            window.scrollTo(0, y);
            await new Promise((r) => setTimeout(r, 100));
          }
          window.scrollTo(0, 0);
        });
        await page.waitForTimeout(600);
        const results = await new AxeBuilder({ page }).analyze();
        reportViolations(route, theme, results.violations);
        expect(
          results.violations,
          `axe violations on ${route} (${theme}): ${JSON.stringify(
            results.violations.map((v) => ({
              id: v.id,
              nodes: v.nodes.map((n) => ({
                target: n.target.join(" "),
                html: n.html.slice(0, 200),
                why: (n.failureSummary || "").replace(/\n/g, " ").slice(0, 200),
              })),
            })),
            null,
            2,
          )}`,
        ).toHaveLength(0);
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
  const ADMIN_ROUTES = [
    "/admin/dashboard",
    "/admin/lawyers",
    "/admin/finance",
    "/admin/settings",
  ];
  const LAWYER_ROUTES = ["/dashboard", "/vault", "/chat"];

  for (const route of CITIZEN_ROUTES) {
    test(`citizen ${route} axe scan`, async ({ page }) => {
      await injectJwt(page, citizenToken);
      await prepare(page, route);
      const results = await new AxeBuilder({ page }).analyze();
      reportViolations(route, "citizen", results.violations);
      assertNoViolations(route, "citizen", results.violations);
    });
  }

  for (const route of ADMIN_ROUTES) {
    test(`admin ${route} axe scan`, async ({ page }) => {
      await injectJwt(page, adminToken);
      await prepare(page, route);
      const results = await new AxeBuilder({ page }).analyze();
      reportViolations(route, "admin", results.violations);
      assertNoViolations(route, "admin", results.violations);
    });
  }

  for (const route of LAWYER_ROUTES) {
    test(`lawyer ${route} axe scan`, async ({ page }) => {
      await injectJwt(page, lawyerToken);
      await prepare(page, route);
      const results = await new AxeBuilder({ page }).analyze();
      reportViolations(route, "lawyer", results.violations);
      assertNoViolations(route, "lawyer", results.violations);
    });
  }
});
