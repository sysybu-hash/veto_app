/**
 * Vercel build step: the Flutter app is not compiled on Vercel (no Flutter in the image).
 * This script only verifies that `npm run build:web` was run locally and committed.
 */
const fs = require('fs');
const path = require('path');

const root = process.cwd();
const candidates = [
  path.join(root, 'frontend', 'build', 'web', 'index.html'),
  path.join(root, 'build', 'web', 'index.html'),
];

const hit = candidates.find((p) => fs.existsSync(p));
if (!hit) {
  console.error(
    'VETO: prebuilt Flutter web not found. From repo root run:\n' +
    '  npm run build:web\n' +
    'then commit frontend/build/web (git add -f frontend/build/web) and push.\n' +
    'Searched:\n' +
    candidates.map((p) => '  ' + p).join('\n'),
  );
  process.exit(1);
}
console.log('VETO: using prebuilt web at', path.dirname(hit));
process.exit(0);
