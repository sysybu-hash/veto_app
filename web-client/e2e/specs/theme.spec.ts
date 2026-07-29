import { test, expect, type Page } from "@playwright/test";

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
 * runnable without a full backend/DB/OTP setup.
 */

const PUBLIC_ROUTES = ["/", "/login", "/register", "/pricing", "/privacy", "/terms"];

async function setTheme(page: Page, theme: "light" | "dark") {
  await page.context().addCookies([
    { name: "veto-theme", value: theme, domain: "localhost", path: "/" },
  ]);
}

async function assertNoInvisibleText(page: Page) {
  const offenders = await page.evaluate(() => {
    function parseRgb(value: string): [number, number, number, number] | null {
      const m = value.match(/rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)(?:,\s*([\d.]+))?\)/);
      if (!m) return null;
      return [Number(m[1]), Number(m[2]), Number(m[3]), m[4] !== undefined ? Number(m[4]) : 1];
    }
    const bad: string[] = [];
    const all = document.querySelectorAll<HTMLElement>("body *");
    for (const el of Array.from(all)) {
      const text = el.textContent?.trim();
      if (!text || text.length === 0) continue;
      // Only check elements whose own direct text (not just descendants') is visible.
      const hasOwnText = Array.from(el.childNodes).some(
        (n) => n.nodeType === Node.TEXT_NODE && (n.textContent || "").trim().length > 0,
      );
      if (!hasOwnText) continue;

      const style = getComputedStyle(el);
      if (style.display === "none" || style.visibility === "hidden" || Number(style.opacity) === 0) continue;
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;

      const color = parseRgb(style.color);
      if (!color || color[3] === 0) continue;

      // Collect every background layer from the element up to an opaque
      // ancestor (or <html>), then alpha-composite them down to a single
      // effective color — a translucent tint (e.g. `bg-brand-soft` at 14%
      // alpha) is NOT the same visual background as its own base hue at
      // full opacity, and comparing against the raw uncomposited layer
      // produces false positives.
      const layers: Array<[number, number, number, number]> = [];
      let node: HTMLElement | null = el;
      let hitBackgroundImage = false;
      while (node) {
        const nodeStyle = getComputedStyle(node);
        // `bg-gradient-to-*` (and any other background-image) paints via a
        // different property than `background-color`, which stays
        // "rgba(0,0,0,0)" — walking past it as if it were transparent
        // would composite against whatever's further up (usually wrong).
        // We can't cheaply sample the actual rendered gradient color, so
        // bail out of the check entirely rather than risk a false report.
        if (nodeStyle.backgroundImage && nodeStyle.backgroundImage !== "none") {
          hitBackgroundImage = true;
          break;
        }
        const bgColor = parseRgb(nodeStyle.backgroundColor);
        if (bgColor && bgColor[3] > 0) {
          layers.push(bgColor);
          if (bgColor[3] >= 1) break; // fully opaque — nothing further matters
        }
        node = node.parentElement;
      }
      if (hitBackgroundImage) continue;
      if (layers.length === 0) continue;
      let bg: [number, number, number, number] = [255, 255, 255, 1]; // page default if nothing opaque found
      for (let i = layers.length - 1; i >= 0; i--) {
        const [r, g, b, a] = layers[i];
        bg = [r * a + bg[0] * (1 - a), g * a + bg[1] * (1 - a), b * a + bg[2] * (1 - a), 1];
      }

      const dist = Math.sqrt((color[0] - bg[0]) ** 2 + (color[1] - bg[1]) ** 2 + (color[2] - bg[2]) ** 2);
      if (dist < 12) {
        bad.push(`"${text.slice(0, 40)}" color=${style.color} resolvedBg=rgba(${bg.map((n) => Math.round(n)).join(",")}) tag=${el.tagName}`);
      }
    }
    return bad;
  });
  expect(offenders, `text near-invisible against its background: ${offenders.join("; ")}`).toEqual([]);
}

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

      // Informational only: `.veto-light [class*="..."]` substring
      // overrides in globals.css are the Phase-3/7 migration target and
      // are only *fully* removed once every route no longer needs them
      // (see UI overhaul plan, Phase 3.3). Reports progress without
      // blocking the suite on an intentionally multi-route migration.
      test(`${route} substring-override usage (informational)`, async ({ page }) => {
        await setTheme(page, theme);
        await page.goto(route);
        await page.waitForLoadState("networkidle");
        const offenders = await page.evaluate(() => {
          const bad: string[] = [];
          for (const sheet of Array.from(document.styleSheets)) {
            let rules: CSSRuleList;
            try {
              rules = sheet.cssRules;
            } catch {
              continue;
            }
            for (const rule of Array.from(rules)) {
              const text = (rule as CSSStyleRule).selectorText;
              if (text && text.includes('[class*=')) bad.push(text);
            }
          }
          return bad;
        });
        test.info().annotations.push({
          type: "substring-selectors-loaded",
          description: String(offenders.length),
        });
      });
    }
  });
}
