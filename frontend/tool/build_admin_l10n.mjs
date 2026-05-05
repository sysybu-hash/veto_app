/**
 * Extracts admin i18n maps from Dart sources and merges into app_{he,en,ru}.arb
 * Prefixes: adm*, admShell*, adash*, subAdm*
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");
const lib = path.join(root, "lib");

function extractBraceMap(text, startNeedle) {
  const i = text.indexOf(startNeedle);
  if (i < 0) throw new Error("missing " + startNeedle);
  const start = text.indexOf("{", i);
  let depth = 0;
  for (let j = start; j < text.length; j++) {
    const c = text[j];
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return text.slice(start + 1, j);
    }
  }
  throw new Error("unclosed brace");
}

function parseKeyValues(body) {
  const out = {};
  const re = /'([^']+)':\s*'((?:[^'\\]|\\.)*)'/g;
  let m;
  while ((m = re.exec(body))) {
    out[m[1]] = m[2].replace(/\\'/g, "'").replace(/\\n/g, "\n");
  }
  return out;
}

function snakeToCamel(s) {
  return s
    .split("_")
    .map((p, i) => (i === 0 ? p : p.charAt(0).toUpperCase() + p.slice(1)))
    .join("");
}

function arbKey(prefix, key) {
  const camel = key.includes("_") ? snakeToCamel(key) : key;
  const cap = camel.charAt(0).toUpperCase() + camel.slice(1);
  return prefix + cap;
}

function mergeLangMaps(target, prefix, he, en, ru) {
  const keys = new Set([...Object.keys(he), ...Object.keys(en), ...Object.keys(ru)]);
  for (const k of keys) {
    const ak = arbKey(prefix, k);
    target.he[ak] = he[k] ?? en[k] ?? k;
    target.en[ak] = en[k] ?? he[k] ?? k;
    target.ru[ak] = ru[k] ?? en[k] ?? k;
  }
}

function readAdminI18n() {
  const text = fs.readFileSync(path.join(lib, "screens/admin/admin_i18n.dart"), "utf8");
  const he = parseKeyValues(extractBraceMap(text, "'he': {"));
  const en = parseKeyValues(extractBraceMap(text, "'en': {"));
  const ru = parseKeyValues(extractBraceMap(text, "'ru': {"));
  return { he, en, ru };
}

function readShellMaps() {
  const text = fs.readFileSync(path.join(lib, "screens/admin/_shell.dart"), "utf8");
  const he = parseKeyValues(extractBraceMap(text, "const he = {"));
  const en = parseKeyValues(extractBraceMap(text, "const en = {"));
  const ru = parseKeyValues(extractBraceMap(text, "const ru = {"));
  return { he, en, ru };
}

function readDashboardI18n() {
  const text = fs.readFileSync(path.join(lib, "screens/admin_dashboard.dart"), "utf8");
  const he = parseKeyValues(extractBraceMap(text, "'he': {"));
  const en = parseKeyValues(extractBraceMap(text, "'en': {"));
  const ru = parseKeyValues(extractBraceMap(text, "'ru': {"));
  return { he, en, ru };
}

function readSubscriptionI18n() {
  const text = fs.readFileSync(path.join(lib, "screens/subscription_admin_screen.dart"), "utf8");
  const he = parseKeyValues(extractBraceMap(text, "'he': {"));
  const en = parseKeyValues(extractBraceMap(text, "'en': {"));
  const ru = parseKeyValues(extractBraceMap(text, "'ru': {"));
  return { he, en, ru };
}

function arbEscape(s) {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t");
}

function mergeIntoArbFile(arbPath, newEntries) {
  let raw = fs.readFileSync(arbPath, "utf8").trimEnd();
  if (!raw.endsWith("}")) throw new Error("bad arb " + arbPath);
  raw = raw.slice(0, -1).trimEnd();
  if (!raw.endsWith(",")) raw += ",";
  const lines = Object.keys(newEntries)
    .sort()
    .map((k) => `  "${k}": "${arbEscape(newEntries[k])}"`);
  fs.writeFileSync(arbPath, raw + "\n" + lines.join(",\n") + "\n}\n");
}

function main() {
  const langs = { he: {}, en: {}, ru: {} };

  mergeLangMaps(langs, "adm", ...Object.values(readAdminI18n()));
  mergeLangMaps(langs, "admShell", ...Object.values(readShellMaps()));
  mergeLangMaps(langs, "adash", ...Object.values(readDashboardI18n()));
  mergeLangMaps(langs, "subAdm", ...Object.values(readSubscriptionI18n()));

  const l10nDir = path.join(lib, "l10n");
  mergeIntoArbFile(path.join(l10nDir, "app_he.arb"), langs.he);
  mergeIntoArbFile(path.join(l10nDir, "app_en.arb"), langs.en);
  mergeIntoArbFile(path.join(l10nDir, "app_ru.arb"), langs.ru);

  console.log("merged admin keys:", Object.keys(langs.en).length, "per locale");
}

main();
