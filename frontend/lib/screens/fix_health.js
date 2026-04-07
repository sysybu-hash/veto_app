const fs = require('fs');
let c = fs.readFileSync('AdminDashboard.dart', 'utf8');
const oldStr = "Uri.parse('\'),";
const newStr = "Uri.parse(AppConfig.healthCheckUrl),";
c = c.replace(/Uri\.parse\('\$\{AppConfig\.baseUrl\}'\),/g, "Uri.parse(AppConfig.healthCheckUrl),");
fs.writeFileSync('AdminDashboard.dart', c);
