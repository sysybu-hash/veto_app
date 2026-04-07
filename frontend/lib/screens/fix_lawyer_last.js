const fs = require('fs');
let c = fs.readFileSync('LawyerDashboard.dart', 'utf8');

c = c.replace('final VoidCallback onHome;', 'final VoidCallback onHome;\\n  final VoidCallback onWaze;');
c = c.replace('required this.onHome,', 'required this.onHome,\\n    required this.onWaze,');
c = c.replace('onTap: onHome,', 'onTap: onHome,\\n                ),\\n                const SizedBox(width: 8),\\n                _HeaderAction(\\n                  icon: Icons.map_outlined,\\n                  tooltip: \\\'Waze\\\',\\n                  onTap: onWaze,');
c = c.replace('onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),', 'onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),\\n                          onWaze: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),');

fs.writeFileSync('LawyerDashboard.dart', c, 'utf8');
