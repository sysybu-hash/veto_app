const fs = require('fs');
let c = fs.readFileSync('LawyerDashboard.dart', 'utf8');

// 1. Add fields to _HeroHeader class
if (!c.includes('final VoidCallback onWaze;')) {
  c = c.replace('final VoidCallback onHome;', 'final VoidCallback onHome;\\n  final VoidCallback onWaze;');
}

// 2. Add to _HeroHeader constructor
if (!c.includes('required this.onWaze,')) {
  c = c.replace('required this.onHome,', 'required this.onHome,\\n    required this.onWaze,');
}

// 3. Add to _HeroHeader build method actions
const wazeAction = '_HeaderAction(\\n                  icon: Icons.map_outlined,\\n                  tooltip: \\\'Waze\\\',\\n                  onTap: onWaze,\\n                ),\\n                const SizedBox(width: 8),';

if (!c.includes('onTap: onWaze,')) {
  c = c.replace('_HeaderAction(\\n                  icon: Icons.home_outlined_rounded,', wazeAction + '\\n                _HeaderAction(\\n                  icon: Icons.home_outlined_rounded,');
}

// 4. Pass parameter from LawyerDashboard state
if (!c.includes('onWaze: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),')) {
  c = c.replace('onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),', 'onHome: () => Navigator.pushNamed(context, \\\'/landing\\\'),\\n                          onWaze: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),');
}

fs.writeFileSync('LawyerDashboard.dart', c);
