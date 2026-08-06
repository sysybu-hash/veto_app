#!/usr/bin/env node
/**
 * Phase 8 verification — browser-free WCAG contrast check.
 *
 * Parses the light (`:root`) and dark (`html.veto-dark`) token values out
 * of `web-client/src/app/globals.css` and asserts contrast ratios for the
 * pairings that actually get used together in the app (text-on-surface,
 * brand foreground on brand background, each state's foreground on its
 * own "soft" background) — in BOTH modes. Run in CI so a future token
 * edit that quietly breaks contrast fails the build instead of shipping.
 *
 * Usage: node scripts/check-contrast.mjs
 */
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CSS_PATH = path.resolve(__dirname, "../web-client/src/app/globals.css");

function parseTokenBlock(css, selectorRe) {
  const match = css.match(selectorRe);
  if (!match) return {};
  const block = match[1];
  const tokens = {};
  for (const m of block.matchAll(/--([\w-]+):\s*([^;]+);/g)) {
    tokens[m[1]] = m[2].trim();
  }
  return tokens;
}

function resolveVar(value, tokens, depth = 0) {
  if (depth > 10) return value;
  const varMatch = value.match(/^var\((--[\w-]+)\)$/);
  if (varMatch) {
    const name = varMatch[1].slice(2);
    if (tokens[name]) return resolveVar(tokens[name], tokens, depth + 1);
  }
  return value;
}

function parseColor(value) {
  value = value.trim();
  let m = value.match(/^#([0-9a-fA-F]{6})$/);
  if (m) {
    const n = parseInt(m[1], 16);
    return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, a: 1 };
  }
  m = value.match(/^#([0-9a-fA-F]{3})$/);
  if (m) {
    const [r, g, b] = [...m[1]].map((c) => parseInt(c + c, 16));
    return { r, g, b, a: 1 };
  }
  m = value.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$/);
  if (m) {
    return { r: +m[1], g: +m[2], b: +m[3], a: m[4] !== undefined ? +m[4] : 1 };
  }
  return null;
}

// Flatten `color` (possibly translucent) onto `bg` (assumed opaque).
function compositeOver(color, bg) {
  if (color.a >= 1) return color;
  const a = color.a;
  return {
    r: color.r * a + bg.r * (1 - a),
    g: color.g * a + bg.g * (1 - a),
    b: color.b * a + bg.b * (1 - a),
    a: 1,
  };
}

function relLuminance({ r, g, b }) {
  const toLinear = (c) => {
    const v = c / 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  const [R, G, B] = [toLinear(r), toLinear(g), toLinear(b)];
  return 0.2126 * R + 0.7152 * G + 0.0722 * B;
}

function contrastRatio(fg, bg) {
  const L1 = relLuminance(fg);
  const L2 = relLuminance(bg);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  return (lighter + 0.05) / (darker + 0.05);
}

function resolveColor(rawValue, tokens, fallbackBg) {
  const resolved = resolveVar(rawValue, tokens);
  const parsed = parseColor(resolved);
  if (!parsed) return null;
  return compositeOver(parsed, fallbackBg);
}

const css = readFileSync(CSS_PATH, "utf8");
const lightTokens = parseTokenBlock(css, /:root\s*\{([^}]+)\}/s);
const darkTokens = parseTokenBlock(css, /html\.veto-dark,\s*\nbody\.veto-dark\s*\{([^}]+)\}/s);

// Pairings to check: [label, fgTokenPath, bgTokenPath, minRatio]
const PAIRS = [
  ["primary text / canvas", "text-primary", "surface-canvas", 4.5],
  ["primary text / raised surface", "text-primary", "surface-raised", 4.5],
  ["secondary text / canvas", "text-secondary", "surface-canvas", 4.5],
  ["muted text / canvas", "text-muted", "surface-canvas", 3.0],
  ["brand fg / brand", "brand-fg", "veto-gold", 4.5],
  // Gold used as TEXT, not as a fill. --veto-gold itself only reaches ~2.2:1 on
  // the light canvas, which is why `text-brand-text` exists and why components
  // must not put raw text-veto-gold on a light surface. These two pairings are
  // the regression guard for that split — see --brand-text in globals.css.
  ["brand text / canvas", "brand-text", "surface-canvas", 4.5],
  ["brand text / raised surface", "brand-text", "surface-raised", 4.5],
  ["success fg / success", "success-fg", "success", 4.5],
  ["warning fg / warning", "warning-fg", "warning", 4.5],
  ["danger fg / danger", "danger-fg", "danger", 4.5],
  ["info fg / info", "info-fg", "info", 4.5],
  // The SOFT pairings — status text on its own tinted background. This is the
  // combination status pills and banners actually use, and it was the blind
  // spot here: only `-fg on solid` was checked, so `--success` on
  // `--success-soft` (3.5:1) shipped as a passing palette. Use the `-on-soft`
  // tokens for text inside a `bg-*-soft` container, never the base colour.
  ["success on soft", "success-on-soft", "success-soft", 4.5],
  ["warning on soft", "warning-on-soft", "warning-soft", 4.5],
  ["danger on soft", "danger-on-soft", "danger-soft", 4.5],
  ["info on soft", "info-on-soft", "info-soft", 4.5],
  ["brand on soft", "brand-on-soft", "brand-soft", 4.5],
];

function checkMode(modeName, tokens) {
  const canvasColor = resolveColor("var(--surface-canvas)", tokens, { r: 255, g: 255, b: 255 });
  if (!canvasColor) {
    console.error(`[${modeName}] could not resolve --surface-canvas — skipping mode`);
    return [];
  }
  const failures = [];
  for (const [label, fgKey, bgKey, minRatio] of PAIRS) {
    const bgRaw = tokens[bgKey];
    const fgRaw = tokens[fgKey];
    if (!bgRaw || !fgRaw) {
      failures.push(`[${modeName}] ${label}: token missing (--${fgKey} or --${bgKey})`);
      continue;
    }
    const bg = resolveColor(`var(--${bgKey})`, tokens, canvasColor) ?? canvasColor;
    const fg = resolveColor(`var(--${fgKey})`, tokens, bg);
    if (!fg) {
      failures.push(`[${modeName}] ${label}: could not parse color`);
      continue;
    }
    const ratio = contrastRatio(fg, bg);
    const ok = ratio >= minRatio;
    console.log(`${ok ? "✓" : "✗"} [${modeName}] ${label}: ${ratio.toFixed(2)}:1 (min ${minRatio}:1)`);
    if (!ok) failures.push(`[${modeName}] ${label}: ${ratio.toFixed(2)}:1 < required ${minRatio}:1`);
  }
  return failures;
}

const lightFailures = checkMode("light", lightTokens);
const darkFailures = checkMode("dark", { ...lightTokens, ...darkTokens });

const allFailures = [...lightFailures, ...darkFailures];
if (allFailures.length > 0) {
  console.error(`\n${allFailures.length} contrast failure(s):`);
  for (const f of allFailures) console.error(" - " + f);
  process.exit(1);
}
console.log(`\nAll ${PAIRS.length * 2} token pairings pass WCAG contrast in both modes.`);
