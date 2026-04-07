const fs = require('fs');
let c = fs.readFileSync('VetoScreen.dart', 'utf8');

const targetStr = "onPressed: () => Navigator.pushNamed(context, '/files_vault'),";
const wazeBtn = "onPressed: () => Navigator.pushNamed(context, '/files_vault'),\\n      ),\\n      IconButton(\\n          icon: const Icon(Icons.map_outlined),\\n          color: Colors.white70,\\n          onPressed: () => Navigator.pushNamed(context, '/waze_map'),\\n          tooltip: _langKey == 'he' ? 'ניווט Waze' : 'Waze Navigation',";

c = c.replace(targetStr, wazeBtn);
fs.writeFileSync('VetoScreen.dart', c, 'utf8');
