import { expect, type Page } from "@playwright/test";

/** Sets the `veto-theme` cookie the same way `ThemeProvider` writes it,
 * so a fresh page load renders in the requested mode from SSR. */
export async function setTheme(page: Page, theme: "light" | "dark") {
  await page.context().addCookies([
    { name: "veto-theme", value: theme, domain: "localhost", path: "/" },
  ]);
}

/**
 * Hard gate: no visible element has a text color that is
 * (near-)identical to its own background — the failure class that made
 * the call UI invisible in light mode (see the UI-overhaul plan,
 * Phase 3/8). Shared across every theme-correctness spec (public routes
 * in `theme.spec.ts`, and the authenticated routes in
 * admin-dashboard/lawyer-dashboard/citizen-authenticated/call-ui specs).
 */
export async function assertNoInvisibleText(page: Page) {
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

/**
 * Full-page screenshot for manual visual review, saved under
 * `e2e/screenshots/<name>/<theme>.png`. Purely additive — never asserts,
 * so a screenshot failure never blocks the suite; it's an artifact for a
 * human (or Claude) to scan for issues the automated checks can't catch
 * (overlap, RTL misalignment, spacing, cut-off icons).
 */
export async function captureScreenshot(page: Page, name: string, theme: "light" | "dark") {
  await page.screenshot({
    path: `e2e/screenshots/${name}/${theme}.png`,
    fullPage: true,
  });
}

/** Informational-only count of `.veto-light [class*="..."]` substring
 * overrides still loaded (see globals.css) — the Phase 3/7 migration
 * target. Reports progress via a test annotation without blocking. */
export async function countSubstringOverrides(page: Page): Promise<number> {
  return page.evaluate(() => {
    let count = 0;
    for (const sheet of Array.from(document.styleSheets)) {
      let rules: CSSRuleList;
      try {
        rules = sheet.cssRules;
      } catch {
        continue;
      }
      for (const rule of Array.from(rules)) {
        const text = (rule as CSSStyleRule).selectorText;
        if (text && text.includes('[class*=')) count++;
      }
    }
    return count;
  });
}
