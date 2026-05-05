import fs from "fs";
const [file, anchorSubstr, prefix] = process.argv.slice(2);
if (!file || !anchorSubstr || !prefix) {
  console.error(
    "Usage: node extract_static_copy.mjs <dart-file> <anchor-substring> <arbPrefix>",
  );
  process.exit(1);
}
const text = fs.readFileSync(file, "utf8");
const anchor = text.indexOf(anchorSubstr);
if (anchor < 0) throw new Error("anchor not found");
const start = text.indexOf("{", anchor) + 1;
let depth = 1,
  i = start;
while (i < text.length && depth > 0) {
  if (text[i] === "{") depth++;
  else if (text[i] === "}") depth--;
  i++;
}
const block = text.slice(start, i - 1);
function parseBlock(locale) {
  const sm = `'${locale}': {`;
  const s = block.indexOf(sm);
  if (s < 0) throw new Error("no locale " + locale);
  const st = s + sm.length;
  let d = 1,
    j = st;
  while (j < block.length && d > 0) {
    if (block[j] === "{") d++;
    else if (block[j] === "}") d--;
    j++;
  }
  const b = block.slice(st, j - 1);
  const out = {};
  const re = /'([^']+)':\s*((?:'(?:\\'|[^'])*'|"(?:\\"|[^"])*"))/gs;
  let m;
  while ((m = re.exec(b))) {
    const k = m[1];
    let raw = m[2];
    let v;
    if (raw.startsWith("'")) v = raw.slice(1, -1).replace(/\\'/g, "'");
    else v = raw.slice(1, -1).replace(/\\"/g, '"');
    out[k] = v;
  }
  return out;
}
function toKey(k) {
  return (
    prefix +
    k.split("_").map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join("")
  );
}
function esc(s) {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r");
}
const he = parseBlock("he");
const en = parseBlock("en");
const ru = parseBlock("ru");
const keys = Object.keys(he).sort();
for (const loc of ["en", "he", "ru"]) {
  const map = { en, he, ru }[loc];
  const lines = keys.map((k) => `  "${toKey(k)}": "${esc(map[k])}"`);
  fs.writeFileSync(
    `tool/_extract_${prefix}_${loc}.txt`,
    lines.join(",\n") + "\n",
  );
}
console.log(prefix, "keys", keys.length);
