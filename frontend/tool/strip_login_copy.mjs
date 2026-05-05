import fs from "fs";
const path = "lib/screens/login_screen.dart";
let s = fs.readFileSync(path, "utf8");
const start = s.indexOf("const _copy = <String, Map<String, String>>{");
if (start < 0) throw new Error("no _copy");
const pre = s.lastIndexOf("\n\n", start);
const cutStart = pre >= 0 ? pre + 2 : start;
const end = s.indexOf("const TextStyle _kAuthMktBodyStyle");
if (end < 0) throw new Error("no TextStyle");
const insert = `import '../l10n/app_localizations.dart';
import 'login_l10n_lookup.dart';

String _t(BuildContext context, String key) =>
    loginT(AppLocalizations.of(context)!, key);

`;
s = s.slice(0, cutStart) + insert + s.slice(end);
fs.writeFileSync(path, s);
console.log("stripped _copy");
