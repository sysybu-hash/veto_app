#!/usr/bin/env node
/**
 * Fail CI if any real .env file (not *.env.example) is tracked by git.
 */
const { execSync } = require('child_process');

let files;
try {
  files = execSync('git ls-files', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
    .trim()
    .split('\n')
    .filter(Boolean);
} catch {
  process.exit(0);
}

function isTrackedSecretEnvPath(f) {
  const lower = f.replace(/\\/g, '/').toLowerCase();
  if (lower.includes('.env.example')) return false;
  const base = lower.split('/').pop();
  if (base === '.env') return true;
  if (/^\.env\./.test(base)) return true;
  return false;
}

const bad = files.filter(isTrackedSecretEnvPath);
if (bad.length) {
  console.error('Tracked files look like environment secrets (remove from git):');
  bad.forEach((f) => console.error('  -', f));
  process.exit(1);
}

process.exit(0);
