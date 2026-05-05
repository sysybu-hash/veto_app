import fs from "fs";
for (const loc of ["en", "he", "ru"]) {
  let arb = fs.readFileSync(`lib/l10n/app_${loc}.arb`, "utf8");
  const lawyer =
    fs.readFileSync(`tool/_extract_lawyerDash_${loc}.txt`, "utf8").trimEnd() +
    ",";
  const prof =
    fs.readFileSync(`tool/_extract_profScreen_${loc}.txt`, "utf8").trimEnd() +
    ",";
  arb = arb.replace(
    /(\n  "citizenExportFailed": "[^"]*",)\n(  "loginAuthSide)/,
    `$1\n${lawyer}\n${prof}\n$2`,
  );
  fs.writeFileSync(`lib/l10n/app_${loc}.arb`, arb);
  console.log("merged", loc);
}
