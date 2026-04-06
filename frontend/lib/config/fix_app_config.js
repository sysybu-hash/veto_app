const fs = require('fs');
let c = fs.readFileSync('app_config.dart', 'utf8');
c = c.replace("static const String kDefaultTunnelHost = 'localhost';", "static const String kDefaultTunnelHost = 'veto-app-new.onrender.com';");
fs.writeFileSync('app_config.dart', c);
