/**
 * Render brochure.html → VETO_Legal_Lawyer_Briefing.pdf
 * Run from web-client so playwright resolves:
 *   node ../docs/lawyer-brochure/build-pdf.mjs
 */
import { chromium } from "playwright";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const htmlPath = path.join(__dirname, "brochure.html");
const outPath = path.join(__dirname, "VETO_Legal_Lawyer_Briefing.pdf");
const desktopCopy = path.join(
  process.env.USERPROFILE || "",
  "Desktop",
  "VETO_Legal_Lawyer_Briefing.pdf",
);

if (!fs.existsSync(htmlPath)) {
  throw new Error(`Missing ${htmlPath}`);
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  viewport: { width: 1240, height: 1754 },
});

await page.goto(pathToFileURL(htmlPath).href, {
  waitUntil: "networkidle",
  timeout: 120000,
});
// Allow Google Fonts to settle
await page.waitForTimeout(2500);

await page.pdf({
  path: outPath,
  format: "A4",
  printBackground: true,
  preferCSSPageSize: true,
  margin: { top: "0", right: "0", bottom: "0", left: "0" },
});

await browser.close();

if (desktopCopy) {
  try {
    fs.copyFileSync(outPath, desktopCopy);
    console.log("copied", desktopCopy);
  } catch (e) {
    console.warn("desktop copy skipped:", e.message);
  }
}

console.log("wrote", outPath);
console.log("bytes", fs.statSync(outPath).size);
