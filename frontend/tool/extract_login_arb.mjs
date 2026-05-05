import fs from "fs";
const text = fs.readFileSync("lib/screens/login_screen.dart", "utf8");
function parseBlock(locale) {
  const startMark = `'${locale}': {`;
  const start = text.indexOf(startMark);
  if (start < 0) throw new Error("no " + locale);
  let i = start + startMark.length;
  let depth = 1;
  while (i < text.length && depth > 0) {
    if (text[i] === "{") depth++;
    else if (text[i] === "}") depth--;
    i++;
  }
  const block = text.slice(start + startMark.length, i - 1);
  const out = {};
  const re = /'([^']+)':\s*((?:'(?:\\'|[^'])*'|"(?:\\"|[^"])*"))/gs;
  let m;
  while ((m = re.exec(block))) {
    const k = m[1];
    let raw = m[2];
    let v;
    if (raw.startsWith("'")) v = raw.slice(1, -1).replace(/\\'/g, "'");
    else v = raw.slice(1, -1).replace(/\\"/g, '"');
    out[k] = v;
  }
  return out;
}
function toArbKey(k) {
  return (
    "login" +
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
  const lines = keys.map((k) => `  "${toArbKey(k)}": "${esc(map[k])}"`);
  fs.writeFileSync(`tool/_login_arb_${loc}.txt`, lines.join(",\n") + "\n");
}
console.log("keys", keys.length);
