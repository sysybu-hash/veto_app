import { chromium } from "playwright";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";
import fs from "fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const brochureDir = path.resolve(__dirname, "../../docs/lawyer-brochure");
const htmlPath = path.join(brochureDir, "brochure.html");
const outPath = path.join(brochureDir, "VETO_Legal_Lawyer_Briefing.pdf");
const desktopCopy = path.join(
  process.env.USERPROFILE || "",
  "Desktop",
  "VETO_Legal_Lawyer_Briefing.pdf",
);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  viewport: { width: 1240, height: 1754 },
});

await page.goto(pathToFileURL(htmlPath).href, {
  waitUntil: "networkidle",
  timeout: 120000,
});
await page.waitForTimeout(2500);

await page.pdf({
  path: outPath,
  format: "A4",
  printBackground: true,
  preferCSSPageSize: true,
  margin: { top: "0", right: "0", bottom: "0", left: "0" },
});

await browser.close();

fs.copyFileSync(outPath, desktopCopy);
console.log("wrote", outPath, fs.statSync(outPath).size);
console.log("desktop", desktopCopy);
