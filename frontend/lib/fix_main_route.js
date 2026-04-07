const fs = require('fs');
let c = fs.readFileSync('main.dart', 'utf8');

// Add import
if (!c.includes("import 'screens/WazeMapScreen.dart';")) {
  c = c.replace("import 'screens/FilesVaultScreen.dart';", "import 'screens/FilesVaultScreen.dart';\nimport 'screens/WazeMapScreen.dart';");
}

// Add route
if (!c.includes("'/waze_map'")) {
  c = c.replace("'/file_vault': (context) => const FilesVaultScreen(),", "'/file_vault': (context) => const FilesVaultScreen(),\n        '/waze_map': (context) => const WazeMapScreen(),");
}

fs.writeFileSync('main.dart', c);
