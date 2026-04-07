const fs = require('fs');
let c = fs.readFileSync('LawyerDashboard.dart', 'utf8');

c = c.replace('final VoidCallback onHome;', 'final VoidCallback onHome;\n  final VoidCallback onWaze;');
c = c.replace('required this.onHome,', 'required this.onHome,\n    required this.onWaze,');

const wazeAction = '_HeaderAction(\n                icon: Icons.map_outlined,\n                tooltip: \\\'Waze\\\',\n                onTap: onWaze,\n              ),\n              const SizedBox(width: 8),';
c = c.replace('_HeaderAction(\n                icon: Icons.home_outlined_rounded,', wazeAction + '\n              _HeaderAction(\n                icon: Icons.home_outlined_rounded,');

c = c.replace('onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),', 'onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),\n                          onWaze: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),');

fs.writeFileSync('LawyerDashboard.dart', c, 'utf8');
