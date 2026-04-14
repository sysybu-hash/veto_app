const fs = require('fs');
const content = fs.readFileSync('veto_screen.dart', 'utf8');

const oldStr = "onPressed: () => Navigator.pushNamed(context, '/files_vault'),";
const newBtn = "onPressed: () => Navigator.pushNamed(context, '/files_vault'),\n      ),\n      IconButton(\n          icon: const Icon(Icons.map_outlined),\n          color: Colors.white70,\n          onPressed: () => Navigator.pushNamed(context, '/waze_map'),\n          tooltip: _langKey == 'he' ? '????? Waze' : 'Waze Navigation',";

const newContent = content.replace(oldStr, newBtn);
fs.writeFileSync('veto_screen.dart', newContent, 'utf8');
