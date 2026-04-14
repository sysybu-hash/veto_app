const fs = require('fs');
let c = fs.readFileSync('veto_screen.dart', 'utf8');

// Find the precise IconButton for files_vault and replace it with TWO buttons: files_vault and waze_map
const oldPart = IconButton(
          icon: const Icon(Icons.folder_special_outlined),
          color: Colors.white70,
          onPressed: () => Navigator.pushNamed(context, '/files_vault'),
          tooltip: _langKey == 'he' ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище' : 'File Vault'),;

const newPart = IconButton(
          icon: const Icon(Icons.folder_special_outlined),
          color: Colors.white70,
          onPressed: () => Navigator.pushNamed(context, '/files_vault'),
          tooltip: _langKey == 'he' ? 'כספת קבצים' : _langKey == 'ru' ? 'Хранилище' : 'File Vault'),
      IconButton(
          icon: const Icon(Icons.map_outlined),
          color: Colors.white70,
          onPressed: () => Navigator.pushNamed(context, '/waze_map'),
          tooltip: _langKey == 'he' ? 'ניווט Waze' : 'Waze Navigation'),;

c = c.replace(oldPart, newPart);
fs.writeFileSync('veto_screen.dart', c, 'utf8');
