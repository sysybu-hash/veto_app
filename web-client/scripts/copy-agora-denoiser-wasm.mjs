/**
 * Copy Agora AI Denoiser WASM blobs into `public/agora-ai-denoiser` so
 * `AIDenoiserExtension({ assetsPath: "/agora-ai-denoiser" })` resolves in
 * production (Vercel) — the package ships binaries under `external/`.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const src = path.join(
  root,
  "node_modules",
  "agora-extension-ai-denoiser",
  "external",
);
const dest = path.join(root, "public", "agora-ai-denoiser");

if (!fs.existsSync(src)) {
  console.warn(
    "[copy-agora-denoiser-wasm] skip: agora-extension-ai-denoiser/external not found (npm install incomplete?)",
  );
  process.exit(0);
}

fs.mkdirSync(dest, { recursive: true });
for (const name of fs.readdirSync(src)) {
  const from = path.join(src, name);
  const to = path.join(dest, name);
  if (fs.statSync(from).isFile()) {
    fs.copyFileSync(from, to);
  }
}
console.log("[copy-agora-denoiser-wasm] copied to", dest);
