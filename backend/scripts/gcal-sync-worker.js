#!/usr/bin/env node
// ============================================================
//  Periodic Google Calendar sync — run via cron (e.g. every 10m)
//  Requires MONGO_URI + Google Calendar OAuth env + connected accounts
// ============================================================

const path = require('path');
const fs = require('fs');

(function loadEnv() {
  const candidates = [
    path.join(__dirname, '..', '.env'),
    path.join(process.cwd(), '.env'),
    path.join(process.cwd(), 'backend', '.env'),
  ];
  for (const envPath of candidates) {
    if (fs.existsSync(envPath)) {
      require('dotenv').config({ path: envPath });
      const local = path.join(path.dirname(envPath), '.env.local');
      if (fs.existsSync(local)) require('dotenv').config({ path: local, override: true });
      return;
    }
  }
  require('dotenv').config();
})();

const connectDB = require('../src/config/db');
const { syncAllAccounts } = require('../src/services/gcalSync.service');

async function main() {
  await connectDB();
  console.log('[gcal-sync-worker] start', new Date().toISOString());
  await syncAllAccounts();
  console.log('[gcal-sync-worker] done');
  process.exit(0);
}

main().catch((e) => {
  console.error('[gcal-sync-worker]', e);
  process.exit(1);
});
