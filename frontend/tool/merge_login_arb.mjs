import fs from "fs";
for (const loc of ["en", "he", "ru"]) {
  let arb = fs.readFileSync(`lib/l10n/app_${loc}.arb`, "utf8");
  const login = fs.readFileSync(`tool/_login_arb_${loc}.txt`, "utf8").trimEnd();
  arb = arb.replace(
    /\n(  "citizenShellSearchSnackbar": "[^"]*")\n\}/,
    `\n$1,\n${login}\n}`,
  );
  fs.writeFileSync(`lib/l10n/app_${loc}.arb`, arb);
  console.log("merged", loc);
}
