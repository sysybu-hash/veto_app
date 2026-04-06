const fs = require('fs');
const path = require('path');

const baseDir = "C:\\Users\\User\\Desktop\\VETO_App\\frontend\\lib\\screens";
const lawyerPath = path.join(baseDir, "LawyerDashboard.dart");

let content = fs.readFileSync(lawyerPath, 'utf8');

const regex = /if\s*\(role\s*==\s*'admin'\)\s*\{\s*Navigator\.of\(context\)\.pushReplacementNamed\('\/admin_settings'\);\s*return;\s*\}/g;

if (regex.test(content)) {
  content = content.replace(regex, "// Admins are allowed to be here");
  fs.writeFileSync(lawyerPath, content, 'utf8');
  console.log("Updated LawyerDashboard.dart admin check.");
} else {
  console.log("Regex not found for admin check.");
}

const regex2 = /if\s*\(role\s*!=\s*'lawyer'\)\s*\{\s*Navigator\.of\(context\)\.pushReplacementNamed\('\/veto_screen'\);\s*return;\s*\}/g;

if (regex2.test(content)) {
  content = content.replace(regex2, "if (role != 'lawyer' && role != 'admin') { Navigator.of(context).pushReplacementNamed('/veto_screen'); return; }");
  fs.writeFileSync(lawyerPath, content, 'utf8');
  console.log("Updated LawyerDashboard.dart lawyer check.");
} else {
  console.log("Regex not found for lawyer check.");
}
