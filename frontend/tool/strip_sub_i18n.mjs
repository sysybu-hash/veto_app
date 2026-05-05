import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const p = path.join(__dirname, "../lib/screens/subscription_admin_screen.dart");
let s = fs.readFileSync(p, "utf8");
const start = s.indexOf("// ── i18n ──────────────────────────────────────────────────────");
const end = s.indexOf("// ── Data model ────────────────────────────────────────────────");
if (start < 0 || end < 0) throw new Error("markers not found");
let before = s.slice(0, start);
const after = s.slice(end);
if (!before.includes("app_localizations.dart")) {
  before = before.replace(
    "import 'admin/_shell.dart';\n",
    "import 'admin/_shell.dart';\nimport '../l10n/app_localizations.dart';\nimport 'admin/admin_l10n_lookups.dart';\n"
  );
}
const mid =
  "String _sub(BuildContext context, String key) =>\n    subAdmT(AppLocalizations.of(context)!, key);\n\n";
fs.writeFileSync(p, before + mid + after);
console.log("ok");
