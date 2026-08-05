/**
 * Capture live production screenshots for the lawyer brochure PDF.
 */
import { chromium } from "playwright";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, "screenshots");
const BASE = process.env.VETO_BROCHURE_BASE || "https://web-nine-gamma-76.vercel.app";

const pages = [
  { slug: "01-home", url: "/", fullPage: true },
  { slug: "02-pricing", url: "/pricing", fullPage: true },
  { slug: "03-contact", url: "/contact", fullPage: true },
  { slug: "04-playbooks", url: "/playbooks", fullPage: true },
  { slug: "05-login", url: "/login", fullPage: true },
  { slug: "06-register", url: "/register", fullPage: true },
  { slug: "07-register-lawyer", url: "/register/lawyer", fullPage: true },
  { slug: "08-terms", url: "/terms", fullPage: false },
  { slug: "09-privacy", url: "/privacy", fullPage: false },
  { slug: "10-hub-gate", url: "/hub", fullPage: true },
  { slug: "11-plans-gate", url: "/plans", fullPage: true },
  { slug: "12-dashboard-gate", url: "/dashboard", fullPage: true },
];

fs.mkdirSync(OUT, { recursive: true });

async function dismissCookies(page) {
  for (const label of ["קבלת הכרחיות", "אישור הכל", "Accept", "הבנתי"]) {
    const btn = page.getByRole("button", { name: label });
    if (await btn.count()) {
      try {
        await btn.first().click({ timeout: 1500 });
        await page.waitForTimeout(400);
        return;
      } catch {
        /* ignore */
      }
    }
  }
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  locale: "he-IL",
  colorScheme: "light",
  deviceScaleFactor: 2,
});
const page = await context.newPage();

for (const item of pages) {
  const target = `${BASE}${item.url}`;
  console.log("capture", target);
  try {
    await page.goto(target, { waitUntil: "networkidle", timeout: 60000 });
  } catch {
    await page.goto(target, { waitUntil: "domcontentloaded", timeout: 60000 });
  }
  await page.waitForTimeout(1200);
  await dismissCookies(page);
  await page.waitForTimeout(500);
  const file = path.join(OUT, `${item.slug}.png`);
  await page.screenshot({ path: file, fullPage: !!item.fullPage });
  console.log("wrote", file);
}

await browser.close();
console.log("done");
