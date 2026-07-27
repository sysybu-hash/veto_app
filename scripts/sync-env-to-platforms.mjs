#!/usr/bin/env node
/**
 * Push selected variables from a local .env file to Vercel (web-client) and/or Render (backend).
 *
 * Prerequisites (shell env — do NOT commit these to git):
 *   VERCEL_TOKEN          — https://vercel.com/account/tokens
 *   VERCEL_PROJECT_ID     — Project Settings → General → Project ID (prj_…)
 *   VERCEL_TEAM_ID        — optional; team slug or id under Settings → Team (team_…)
 *   RENDER_API_KEY        — https://dashboard.render.com/u/settings#api-keys
 *   RENDER_SERVICE_ID     — Dashboard → Web Service → Settings → copy Service ID (srv-…)
 *
 * Usage:
 *   node scripts/sync-env-to-platforms.mjs --dry-run
 *   node scripts/sync-env-to-platforms.mjs --vercel --target production
 *   node scripts/sync-env-to-platforms.mjs --render
 *   node scripts/sync-env-to-platforms.mjs --vercel --render --target production
 *
 * Default .env path (first match):
 *   1) web-client/.env  (recommended — single file for Next + keys shared with Render)
 *   2) repo root .env
 * Override: ENV_FILE=... or --env-file path
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");

const ALLOW = JSON.parse(
  fs.readFileSync(path.join(__dirname, "env-sync.allowlists.json"), "utf8"),
);

/** Prefer web-client/.env when present (matches Next.js local dev). */
function resolveDefaultEnvFile() {
  const webClient = path.join(REPO_ROOT, "web-client", ".env");
  const rootEnv = path.join(REPO_ROOT, ".env");
  if (fs.existsSync(webClient)) return webClient;
  if (fs.existsSync(rootEnv)) return rootEnv;
  return webClient;
}

function parseArgs(argv) {
  const flags = new Set();
  let target = "production";
  const envFromShell = process.env.ENV_FILE?.trim();
  let envFile = envFromShell
    ? path.resolve(envFromShell)
    : resolveDefaultEnvFile();
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--dry-run") flags.add("dry-run");
    else if (a === "--vercel") flags.add("vercel");
    else if (a === "--render") flags.add("render");
    else if (a === "--help" || a === "-h") flags.add("help");
    else if (a === "--target" && argv[i + 1]) {
      target = argv[++i];
    } else if (a === "--env-file" && argv[i + 1]) {
      envFile = path.resolve(argv[++i]);
    }
  }
  return { flags, target, envFile };
}

/** Minimal .env parser: KEY=VALUE, supports unquoted and double-quoted values, ignores comments. */
function parseDotEnv(content) {
  /** @type {Record<string, string>} */
  const out = {};
  for (let line of content.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const eq = t.indexOf("=");
    if (eq <= 0) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if (val.startsWith('"') && val.endsWith('"') && val.length >= 2) {
      val = val.slice(1, -1).replace(/\\n/g, "\n").replace(/\\"/g, '"');
    } else if (val.startsWith("'") && val.endsWith("'") && val.length >= 2) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

async function vercelListEnv({ token, projectId, teamId }) {
  const q = teamId ? `?teamId=${encodeURIComponent(teamId)}` : "";
  const res = await fetch(
    `https://api.vercel.com/v9/projects/${encodeURIComponent(projectId)}/env${q}`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Vercel list env failed: ${res.status} ${t}`);
  }
  const data = await res.json();
  return Array.isArray(data.envs) ? data.envs : [];
}

async function vercelUpsertEnv({
  token,
  projectId,
  teamId,
  key,
  value,
  target,
  dryRun,
}) {
  const q = teamId ? `?teamId=${encodeURIComponent(teamId)}` : "";
  const envs = await vercelListEnv({ token, projectId, teamId });
  const targets = [target];
  const existing = envs.find(
    (e) => e.key === key && (e.target || []).includes(target),
  );

  if (dryRun) {
    console.log(`[vercel] ${existing ? "update" : "create"} ${key} → ${targets.join(",")}`);
    return;
  }

  const type = key.startsWith("NEXT_PUBLIC_") ? "plain" : "encrypted";

  if (existing?.id) {
    const res = await fetch(
      `https://api.vercel.com/v9/projects/${encodeURIComponent(projectId)}/env/${existing.id}${q}`,
      {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ value, target: targets, type }),
      },
    );
    if (!res.ok) {
      const t = await res.text();
      throw new Error(`Vercel PATCH ${key}: ${res.status} ${t}`);
    }
    return;
  }

  const res = await fetch(
    `https://api.vercel.com/v10/projects/${encodeURIComponent(projectId)}/env${q}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key,
        value,
        type,
        target: targets,
      }),
    },
  );
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Vercel POST ${key}: ${res.status} ${t}`);
  }
}

async function renderGetEnv({ apiKey, serviceId }) {
  const res = await fetch(
    `https://api.render.com/v1/services/${encodeURIComponent(serviceId)}/env-vars?limit=100`,
    { headers: { Authorization: `Bearer ${apiKey}` } },
  );
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Render list env failed: ${res.status} ${t}`);
  }
  const data = await res.json();
  if (Array.isArray(data)) return data;
  if (Array.isArray(data.envVars)) return data.envVars;
  return [];
}

async function renderPutMergedEnv({ apiKey, serviceId, updates, dryRun }) {
  const current = await renderGetEnv({ apiKey, serviceId });
  const byKey = new Map();
  for (const row of current) {
    if (row?.key) byKey.set(row.key, row.value ?? "");
  }
  for (const [k, v] of Object.entries(updates)) {
    byKey.set(k, v);
  }
  const body = [...byKey.entries()].map(([key, value]) => ({ key, value }));

  if (dryRun) {
    console.log(`[render] merged PUT ${updates ? Object.keys(updates).length : 0} updated keys (total ${body.length} vars on service)`);
    for (const k of Object.keys(updates)) console.log(`  - ${k}`);
    return;
  }

  const res = await fetch(
    `https://api.render.com/v1/services/${encodeURIComponent(serviceId)}/env-vars`,
    {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`Render PUT env-vars: ${res.status} ${t}`);
  }
}

function printHelp() {
  console.log(`
sync-env-to-platforms.mjs — push allowlisted keys from .env to Vercel / Render

  ENV_FILE=path/to/.env   optional (default: web-client/.env if it exists, else .env at repo root)

  --vercel --render       which platforms (at least one)
  --target production     Vercel target: production | preview | development
  --dry-run
  --env-file <path>

Shell secrets (never commit):
  VERCEL_TOKEN VERCEL_PROJECT_ID [VERCEL_TEAM_ID]
  RENDER_API_KEY RENDER_SERVICE_ID
`);
}

function main() {
  const { flags, target, envFile } = parseArgs(process.argv);
  if (flags.has("help")) {
    printHelp();
    process.exit(0);
  }

  const dryRun = flags.has("dry-run");
  const doVercel = flags.has("vercel");
  const doRender = flags.has("render");

  if (!doVercel && !doRender) {
    console.error("Specify --vercel and/or --render. Use --dry-run to preview. Example:");
    console.error("  VERCEL_TOKEN=... VERCEL_PROJECT_ID=prj_... node scripts/sync-env-to-platforms.mjs --vercel --target production --dry-run");
    process.exit(1);
  }

  if (!fs.existsSync(envFile)) {
    console.error(`Missing env file: ${envFile}`);
    process.exit(1);
  }

  console.log(`[env-sync] source file: ${envFile}`);

  const raw = fs.readFileSync(envFile, "utf8");
  const all = parseDotEnv(raw);

  (async () => {
    if (doVercel) {
      const token = process.env.VERCEL_TOKEN?.trim();
      const projectId = process.env.VERCEL_PROJECT_ID?.trim();
      const teamId = process.env.VERCEL_TEAM_ID?.trim() || "";
      if (!token || !projectId) {
        throw new Error("Vercel: set VERCEL_TOKEN and VERCEL_PROJECT_ID in the shell before running.");
      }
      for (const key of ALLOW.vercel) {
        if (!(key in all)) continue;
        const value = all[key];
        if (value === undefined || value === "") {
          console.warn(`[vercel] skip empty: ${key}`);
          continue;
        }
        await vercelUpsertEnv({
          token,
          projectId,
          teamId,
          key,
          value,
          target,
          dryRun,
        });
      }
      console.log(dryRun ? "[vercel] dry-run done." : "[vercel] sync done.");
    }

    if (doRender) {
      const apiKey = process.env.RENDER_API_KEY?.trim();
      const serviceId = process.env.RENDER_SERVICE_ID?.trim();
      if (!apiKey || !serviceId) {
        throw new Error("Render: set RENDER_API_KEY and RENDER_SERVICE_ID in the shell before running.");
      }
      /** @type {Record<string, string>} */
      const updates = {};
      for (const key of ALLOW.render) {
        let value = all[key];
        if (
          (value === undefined || value === "") &&
          key === "GOOGLE_CLIENT_ID" &&
          all.NEXT_PUBLIC_GOOGLE_CLIENT_ID
        ) {
          value = all.NEXT_PUBLIC_GOOGLE_CLIENT_ID;
        }
        if (
          (value === undefined || value === "") &&
          key === "PAYPAL_CLIENT_ID" &&
          all.NEXT_PUBLIC_PAYPAL_CLIENT_ID
        ) {
          value = all.NEXT_PUBLIC_PAYPAL_CLIENT_ID;
        }
        if (
          (value === undefined || value === "") &&
          key === "AGORA_APP_ID" &&
          all.NEXT_PUBLIC_AGORA_APP_ID
        ) {
          value = all.NEXT_PUBLIC_AGORA_APP_ID;
        }
        if (value === undefined || value === "") {
          console.warn(`[render] skip empty: ${key}`);
          continue;
        }
        updates[key] = value;
      }
      await renderPutMergedEnv({ apiKey, serviceId, updates, dryRun });
      console.log(dryRun ? "[render] dry-run done." : "[render] sync done.");
    }
  })().catch((e) => {
    console.error(e?.message || e);
    process.exit(1);
  });
}

main();
