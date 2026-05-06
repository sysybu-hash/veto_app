/**
 * מריץ Prisma עם DATABASE_URL מתוך veto_legal/.env — דורס ערך שכבר קיים
 * במשתני סביבה של Windows (Prisma לא מחליף משתנים קיימים).
 */
const { spawnSync } = require("child_process");
const { existsSync, readFileSync } = require("fs");
const { resolve } = require("path");

const root = resolve(__dirname, "..");
const envFile = resolve(root, ".env");

function parseDatabaseUrl() {
  if (!existsSync(envFile)) return null;
  const text = readFileSync(envFile, "utf8");
  for (const raw of text.split("\n")) {
    const line = raw.replace(/\r$/, "").trim();
    if (!line || line.startsWith("#")) continue;
    if (!line.startsWith("DATABASE_URL=")) continue;
    let v = line.slice("DATABASE_URL=".length).trim();
    if (
      (v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))
    ) {
      v = v.slice(1, -1);
    }
    return v || null;
  }
  return null;
}

const dbUrl = parseDatabaseUrl();
if (!dbUrl) {
  console.error(
    "חסר DATABASE_URL בקובץ .env בשורש הפרויקט (שורה: DATABASE_URL=...)",
  );
  process.exit(1);
}

const prismaSub = process.argv.slice(2);
if (prismaSub.length === 0) {
  console.error(
    "שימוש: node scripts/prisma-from-root-env.cjs db push | generate | …",
  );
  process.exit(1);
}

const result = spawnSync(
  "npx",
  [
    "--prefix",
    "web-client",
    "prisma",
    ...prismaSub,
    "--schema",
    "web-client/prisma/schema.prisma",
  ],
  {
    cwd: root,
    stdio: "inherit",
    shell: true,
    env: { ...process.env, DATABASE_URL: dbUrl },
  },
);

process.exit(result.status === null ? 1 : result.status);
