const fs = require('fs');
let content = fs.readFileSync('frontend/lib/screens/landing_screen.dart', 'utf-8');
let lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('VETO AI')) {
    lines[i] = "            code == 'he' ? 'שאל את VETO AI' : code == 'ru' ? 'Спросить VETO AI' : 'Ask VETO AI',";
  }
}
fs.writeFileSync('frontend/lib/screens/landing_screen.dart', lines.join('\n'), 'utf-8');
