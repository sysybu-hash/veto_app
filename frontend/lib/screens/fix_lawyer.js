const fs = require('fs');
const path = require('path');

function replaceInFile(filePath, oldStr, newStr) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    if (!content.includes(oldStr)) {
      console.log(`Error: Could not find old_str in ${filePath}`);
      return false;
    }
    content = content.replace(oldStr, newStr);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Successfully updated ${filePath}`);
    return true;
  } catch (e) {
    console.log(`Failed to process ${filePath}: ${e.message}`);
    return false;
  }
}

const baseDir = "C:\\Users\\User\\Desktop\\VETO_App\\frontend\\lib\\screens";
const lawyerPath = path.join(baseDir, "LawyerDashboard.dart");
const oldLawyer = `    if (role == 'admin') {
      Navigator.of(context).pushReplacementNamed('/admin_settings');
      return;
    }
    if (role != 'lawyer') {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }`;
const newLawyer = `    // Allow admins to access the lawyer dashboard if they chose to do so
    if (role != 'lawyer' && role != 'admin') {
      Navigator.of(context).pushReplacementNamed('/veto_screen');
      return;
    }`;

replaceInFile(lawyerPath, oldLawyer, newLawyer);

