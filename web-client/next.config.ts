import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import type { NextConfig } from "next";

/** תיקיית web-client — כדי ש-Turbopack לא יבחר בטעות lockfile בשורש המשתמש (למשל C:\Users\User). */
const webClientRoot = dirname(fileURLToPath(import.meta.url));

/**
 * טוען DATABASE_URL מקובץ ה-.env בשורש ה-repo (veto_legal/.env) כשאין אחד ב-web-client —
 * מתאים למשתמשים שמנהלים סודות רק במקום אחד.
 */
function loadDatabaseUrlFromMonorepoRoot(): void {
  if (process.env.DATABASE_URL?.trim()) return;
  const rootEnv = resolve(process.cwd(), "..", ".env");
  if (!existsSync(rootEnv)) return;
  const text = readFileSync(rootEnv, "utf8");
  for (const raw of text.split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq === -1) continue;
    const key = line.slice(0, eq).trim();
    if (key !== "DATABASE_URL") continue;
    let val = line.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    if (val) process.env.DATABASE_URL = val;
    break;
  }
}

loadDatabaseUrlFromMonorepoRoot();

const nextConfig: NextConfig = {
  turbopack: {
    root: webClientRoot,
  },
};

export default nextConfig;
