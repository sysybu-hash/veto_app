const fs = require('fs');
let c = fs.readFileSync('AdminDashboard.dart', 'utf8');
c = c.replace(/baseUrl\}\/events\?limit=10/g, "baseUrl}/events/history?limit=10");
fs.writeFileSync('AdminDashboard.dart', c);
