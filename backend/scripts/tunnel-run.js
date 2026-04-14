/**
 * Runs localtunnel via the official API and prints the REAL public URL.
 * The `lt` CLI often shows "your url is: …" that does not match --subdomain
 * when the requested name is taken — this script surfaces the mismatch clearly.
 *
 * Usage (from backend/): npm run tunnel
 * Env: PORT (default 5001), TUNNEL_SUBDOMAIN (default sweet-turkey-60)
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const localtunnel = require('localtunnel');

const PORT = Number(process.env.PORT) || 5001;
const WANTED = process.env.TUNNEL_SUBDOMAIN || 'sweet-turkey-60';

function hostFromTunnelUrl(url) {
  try {
    return new URL(url).host;
  } catch {
    return String(url)
      .replace(/^https?:\/\//i, '')
      .split('/')[0];
  }
}

function banner(lines) {
  const w = Math.max(...lines.map((s) => s.length), 20) + 4;
  const bar = '═'.repeat(w);
  console.log('');
  console.log(bar);
  for (const line of lines) console.log(`  ${line}`);
  console.log(bar);
  console.log('');
}

(async () => {
  const tunnel = await localtunnel({
    port: PORT,
    subdomain: WANTED,
  });

  const publicUrl = tunnel.url;
  const host = hostFromTunnelUrl(publicUrl);
  const wantedPrefix = `${WANTED}.loca.lt`;
  const matchesDefault = host === wantedPrefix;

  const lines = [
    'VETO localtunnel',
    '',
    `Local port:     ${PORT}`,
    `Requested name: ${WANTED}`,
    `Public URL:     ${publicUrl}`,
    `Hostname:       ${host}`,
  ];

  if (!matchesDefault) {
    lines.push('');
    lines.push('! Subdomain was NOT available (or server assigned a different id).');
    lines.push('! Flutter default is sweet-turkey-60.loca.lt — it will NOT hit this tunnel.');
    lines.push('');
    lines.push('Run Flutter with:');
    lines.push(`  flutter run --dart-define=VETO_HOST=${host}`);
  } else {
    lines.push('');
    lines.push('OK — matches AppConfig.kDefaultTunnelHost (no dart-define needed).');
  }

  banner(lines);

  tunnel.on('close', () => {
    console.log('Tunnel closed.');
    process.exit(0);
  });

  const shutdown = () => {
    try {
      tunnel.close();
    } catch {
      process.exit(0);
    }
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
