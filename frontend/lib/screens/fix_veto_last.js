const fs = require('fs');
let c = fs.readFileSync('VetoScreen.dart', 'utf8');

const oldStr = "onPressed: () => Navigator.pushNamed(context, '/files_vault'),";
const insertText = "\\n      IconButton(\\n          icon: const Icon(Icons.map_outlined),\\n          color: Colors.white70,\\n          onPressed: () => Navigator.pushNamed(context, '/waze_map'),\\n          tooltip: _langKey == 'he' ? 'ניווט Waze' : 'Waze Navigation'),";

c = c.replace(oldStr, oldStr + insertText);
fs.writeFileSync('VetoScreen.dart', c, 'utf8');
