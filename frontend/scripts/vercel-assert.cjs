/**
 * Vercel build step when the project "Root Directory" is `frontend/`.
 * Parent `../scripts/` is *not* part of the Vercel upload — this file must live here.
 * Verifies `flutter build web` output exists (CI or committed prebuild).
 */
const fs = require('fs');
const path = require('path');

const p = path.join(process.cwd(), 'build', 'web', 'index.html');
if (!fs.existsSync(p)) {
  console.error(
    'VETO: prebuilt Flutter web not found. Expected:\n' +
    '  ' +
    p +
    '\n' +
    'From `frontend/`: flutter build web --release (or npm run build:web from repo root) then commit build/web or build in CI before deploy.',
  );
  process.exit(1);
}
console.log('VETO: using prebuilt web at', path.join(process.cwd(), 'build', 'web'));
process.exit(0);
