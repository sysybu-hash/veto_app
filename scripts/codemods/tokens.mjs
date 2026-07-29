#!/usr/bin/env node
/**
 * Phase 3 color-token codemod.
 *
 * Rewrites hardcoded Tailwind color/shape utility tokens in `className`
 * string/template literals to the semantic tokens defined in
 * `web-client/src/app/globals.css`. Since every semantic token is
 * dual-mode by construction (same CSS var name, different value per
 * `:root` / `html.veto-dark`), any `dark:` companion of a token we just
 * rewrote is now redundant and is dropped.
 *
 * Usage:
 *   node scripts/codemods/tokens.mjs --dry     # report only
 *   node scripts/codemods/tokens.mjs           # rewrite files in place
 *   node scripts/codemods/tokens.mjs src/app/login  # scope to a path
 */
import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../../web-client/src");

const args = process.argv.slice(2);
const dry = args.includes("--dry");
const scopeArg = args.find((a) => !a.startsWith("--"));
const SCOPE = scopeArg ? path.resolve(__dirname, "../../web-client", scopeArg) : ROOT;

// --- exact-token map (order matters: longer/more specific first) ---
const EXACT_MAP = new Map(
  Object.entries({
    // text
    "text-slate-950": "text-primary",
    "text-slate-900": "text-primary",
    "text-slate-800": "text-primary",
    "text-slate-700": "text-secondary",
    "text-slate-600": "text-secondary",
    "text-slate-500": "text-muted",
    "text-slate-400": "text-muted",
    "text-gray-900": "text-primary",
    "text-gray-800": "text-primary",
    "text-gray-700": "text-secondary",
    "text-gray-600": "text-secondary",
    "text-gray-500": "text-muted",
    "text-gray-400": "text-muted",
    "text-white": "text-inverse",
    // borders
    "border-slate-200": "border-subtle",
    "border-slate-300": "border-default",
    "border-slate-400": "border-strong",
    "divide-slate-200": "divide-subtle",
    // backgrounds
    "bg-white": "bg-surface-overlay",
    "bg-slate-50": "bg-surface-sunken",
    "bg-gray-50": "bg-surface-sunken",
    // radius drift -> panel token
    "rounded-[28px]": "rounded-panel",
    "rounded-[2rem]": "rounded-panel",
    "rounded-[2.4rem]": "rounded-panel",
  }),
);

// --- regex-based token map (bracketed/opacity variants) ---
// Only exact, information-preserving mappings belong here — anything that
// would silently drop an opacity/alpha suffix (e.g. bg-slate-900/35 used as
// a scrim) is deliberately NOT included; those need a human to pick the
// right token (surface-raised vs surface-scrim vs surface-inverse).
const REGEX_MAP = [
  [/^bg-white\/9[0-9]$/, "bg-surface-raised-2"],
  [/^bg-white\/8[0-9]$/, "bg-surface-raised"],
  [/^border-white\/1[0-9]$/, "border-subtle"],
  [/^border-white\/2[0-9]$/, "border-default"],
];

// hex -> brand ramp (the 6 untokenized shades found in the audit)
const HEX_MAP = new Map(
  Object.entries({
    "#c5a059": "veto-gold",
    "#C5A059": "veto-gold",
    "#d4b06a": "veto-gold-light",
    "#9b7430": "veto-gold-dark",
    "#6f5528": "veto-gold-deep",
    "#e8c987": "brand-100",
    "#d8b867": "brand-200",
    "#b08d4a": "brand-600",
    "#8a6d35": "brand-700",
    "#8a6d3d": "brand-700",
    "#75551f": "brand-deep",
  }),
);

// logical-property direction map (LTR/RTL parity, Phase 3.5)
const DIR_MAP = new Map(
  Object.entries({
    "ml-": "ms-",
    "mr-": "me-",
    "pl-": "ps-",
    "pr-": "pe-",
    "text-left": "text-start",
    "text-right": "text-end",
    "left-": "start-",
    "right-": "end-",
  }),
);

function mapHexToken(prefix, hex) {
  const name = HEX_MAP.get(hex);
  if (!name) return null;
  return `${prefix}-${name}`;
}

function rewriteToken(token) {
  // hex arbitrary values: text-[#xxxxxx], bg-[#xxxxxx], border-[#xxxxxx], from-/to-/via-
  const hexMatch = token.match(/^(text|bg|border|from|to|via|ring|divide|outline|fill|stroke)-\[(#[0-9a-fA-F]{3,8})\]$/);
  if (hexMatch) {
    const mapped = mapHexToken(hexMatch[1], hexMatch[2]);
    if (mapped) return mapped;
  }

  if (EXACT_MAP.has(token)) return EXACT_MAP.get(token);

  for (const [re, replacement] of REGEX_MAP) {
    if (re.test(token)) return replacement;
  }

  // logical property direction fixes (only for plain LTR-biased utilities,
  // skip if already using rtl:/ltr: variants which are intentional)
  for (const [from, to] of DIR_MAP) {
    if (token.startsWith(from) && !token.startsWith("rtl:") && !token.startsWith("ltr:")) {
      const rest = token.slice(from.length);
      if (/^\d|^\[|^auto|^px|^full/.test(rest) || from.startsWith("text-")) {
        return to + rest;
      }
    }
  }

  return null;
}

// Tokens we tokenized above have a stable, theme-independent replacement,
// so any `dark:` variant of the SAME base becomes redundant once we see
// both in one className string.
function processClassString(str) {
  const tokens = str.split(/(\s+)/); // keep whitespace for stable reconstruction
  const rewrittenBases = new Set();
  const out = [];

  // first pass: rewrite non-dark tokens, remember which bases were touched
  for (const t of tokens) {
    if (/^\s+$/.test(t) || t === "") {
      out.push(t);
      continue;
    }
    if (t.startsWith("dark:")) {
      out.push(t); // handled in second pass
      continue;
    }
    const rewritten = rewriteToken(t);
    if (rewritten) {
      rewrittenBases.add(t);
      out.push(rewritten);
    } else {
      out.push(t);
    }
  }

  // second pass: drop dark: companions whose base was just tokenized
  const finalOut = out.map((t) => {
    if (!t.startsWith("dark:")) return t;
    const base = t.slice(5);
    if (rewrittenBases.has(base)) return null; // drop — redundant now
    const rewrittenDark = rewriteToken(base);
    if (rewrittenDark) return null; // base independently tokenizes elsewhere -> also redundant
    return t;
  });

  return finalOut.filter((t) => t !== null).join("").replace(/\s+/g, " ").trim();
}

const CLASS_ATTR_RE = /className="([^"]*)"/g;
let skippedTemplateLiterals = 0;
let rewrittenTemplateLiterals = 0;

// Rewrite tokens in a text fragment while preserving exact whitespace —
// used for template-literal static segments and ternary arms, where
// trimming/collapsing (as `processClassString` does) would corrupt the
// surrounding string concatenation.
function rewriteClassesPreserveWhitespace(text) {
  const tokens = text.split(/(\s+)/);
  const rewrittenBases = new Set();
  const out = tokens.map((t) => {
    if (/^\s*$/.test(t) || t.startsWith("dark:")) return t;
    const r = rewriteToken(t);
    if (r) {
      rewrittenBases.add(t);
      return r;
    }
    return t;
  });
  return out
    .map((t) => {
      if (!t.startsWith("dark:")) return t;
      const base = t.slice(5);
      if (rewrittenBases.has(base) || rewriteToken(base)) return null;
      return t;
    })
    .filter((t) => t !== null)
    .join("");
}

// Split a template-literal body into static text / `${...}` expression
// parts. Returns null if braces are unbalanced (shouldn't happen for
// valid source, but bail rather than guess).
function splitTemplate(content) {
  const parts = [];
  let i = 0;
  while (i < content.length) {
    const idx = content.indexOf("${", i);
    if (idx === -1) {
      parts.push({ type: "static", text: content.slice(i) });
      break;
    }
    parts.push({ type: "static", text: content.slice(i, idx) });
    let depth = 1;
    let j = idx + 2;
    while (j < content.length && depth > 0) {
      if (content[j] === "{") depth++;
      else if (content[j] === "}") depth--;
      j++;
    }
    if (depth !== 0) return null;
    parts.push({ type: "expr", raw: content.slice(idx + 2, j - 1) });
    i = j;
  }
  return parts;
}

const TERNARY_STRINGS_RE = /^([\s\S]*?)\?\s*"([^"]*)"\s*:\s*"([^"]*)"\s*$/;

// Rewrite a single `className={`...`}` body. Handles two safe shapes per
// `${...}` interpolation: (1) no string literals at all (a plain variable
// or `cn(...)` call — left untouched, nothing to rewrite), or (2) exactly
// `cond ? "classesA" : "classesB"` (the overwhelming majority of the 326
// flagged sites — active/selected nav & list-item styling). Anything else
// (nested ternaries, template literals inside the expression, multiple
// string arms) causes that specific template literal to be left
// completely unchanged rather than guessed at.
function processTemplateLiteral(content) {
  const parts = splitTemplate(content);
  if (!parts) return null;

  let changed = false;
  const out = parts.map((part) => {
    if (part.type === "static") {
      const rewritten = rewriteClassesPreserveWhitespace(part.text);
      if (rewritten !== part.text) changed = true;
      return rewritten;
    }
    const hasStringLiteral = /["'`]/.test(part.raw);
    if (!hasStringLiteral) return "${" + part.raw + "}";

    const m = part.raw.match(TERNARY_STRINGS_RE);
    if (!m) return SKIP; // unrecognized shape with a string literal — unsafe to touch
    const [, cond, thenStr, elseStr] = m;
    const thenRewritten = rewriteClassesPreserveWhitespace(thenStr);
    const elseRewritten = rewriteClassesPreserveWhitespace(elseStr);
    if (thenRewritten !== thenStr || elseRewritten !== elseStr) changed = true;
    return `\${${cond}? "${thenRewritten}" : "${elseRewritten}"}`;
  });

  if (out.includes(SKIP)) return null;
  return changed ? out.join("") : null;
}

const SKIP = Symbol("skip");

function processFile(filePath) {
  const src = readFileSync(filePath, "utf8");
  let changed = false;

  const next = src
    .replace(CLASS_ATTR_RE, (match, classes) => {
      const rewritten = processClassString(classes);
      if (rewritten !== classes) changed = true;
      return `className="${rewritten}"`;
    })
    .replace(/className=\{`([^`]*)`\}/g, (match, body) => {
      const rewritten = processTemplateLiteral(body);
      if (rewritten === null) {
        skippedTemplateLiterals++;
        return match;
      }
      changed = true;
      rewrittenTemplateLiterals++;
      return "className={`" + rewritten + "`}";
    });

  if (changed && !dry) {
    writeFileSync(filePath, next, "utf8");
  }
  return changed;
}

function walk(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    if (entry === "node_modules" || entry === ".next") continue;
    const full = path.join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) walk(full, files);
    else if (/\.(tsx|ts)$/.test(entry) && !entry.endsWith(".d.ts")) files.push(full);
  }
  return files;
}

const files = walk(SCOPE);
let touched = 0;
for (const f of files) {
  if (processFile(f)) {
    touched++;
    console.log((dry ? "[dry] would change: " : "changed: ") + path.relative(ROOT, f));
  }
}
console.log(`\n${touched} file(s) ${dry ? "would be" : "were"} touched out of ${files.length} scanned.`);
if (rewrittenTemplateLiterals > 0) {
  console.log(`${rewrittenTemplateLiterals} className={\`...\`} template-literal usage(s) were tokenized.`);
}
if (skippedTemplateLiterals > 0) {
  console.log(
    `${skippedTemplateLiterals} className={\`...\`} template-literal usage(s) have an unrecognized shape — left untouched, review manually.`,
  );
}
