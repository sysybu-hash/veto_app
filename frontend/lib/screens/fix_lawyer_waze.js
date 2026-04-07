const fs = require('fs');
let c = fs.readFileSync('LawyerDashboard.dart', 'utf8');

const wazeBtn = 'IconButton(\\n              icon: const Icon(Icons.map_outlined, color: VetoPalette.primary),\\n              onPressed: () => Navigator.pushNamed(context, \\\'/waze_map\\\'),\\n              tooltip: isHe ? \\\'??? ?????\\\' : \\\'Navigation Map\\\',\\n            ),';

if (!c.includes("'/waze_map'")) {
  c = c.replace("onPressed: () => Navigator.pushNamed(context, '/settings'),", "onPressed: () => Navigator.pushNamed(context, '/settings'),\\n            ),\\n            " + wazeBtn);
}

fs.writeFileSync('LawyerDashboard.dart', c);
