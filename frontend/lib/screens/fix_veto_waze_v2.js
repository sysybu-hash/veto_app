const fs = require('fs');
let c = fs.readFileSync('veto_screen.dart', 'utf8');

const wazeBtn = 'IconButton(\\n          icon: const Icon(Icons.map_outlined),\\n          color: Colors.white70,\\n          onPressed: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),\\n          tooltip: _langKey == \\\'he\\\' ? \\\'????? Waze\\\' : \\\'Waze Navigation\\\',\\n      ),';

if (!c.includes("'/waze_map'")) {
  c = c.replace("onPressed: () => Navigator.pushNamed(context, '/files_vault'),", "onPressed: () => Navigator.pushNamed(context, '/files_vault'),\\n      ),\\n      " + wazeBtn);
}

fs.writeFileSync('veto_screen.dart', c);
