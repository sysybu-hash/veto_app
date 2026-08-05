// ============================================================
//  srvFallback.js — mongodb+srv:// expansion for broken DNS stacks
//
//  LOCAL DEVELOPMENT AID ONLY. Some Windows machines cannot answer the SRV
//  lookup Node performs for `mongodb+srv://`, so `mongoose.connect` dies with
//  `querySrv ENOTFOUND`. This module resolves the SRV/TXT records out-of-band
//  and rewrites the URI into the equivalent `mongodb://host1,host2/...` form.
//
//  It is never exercised on Render/Linux: the PowerShell path is gated on
//  process.platform === 'win32', and db.js only calls in here after a real
//  querySrv failure. Kept out of db.js so the connection flow stays readable.
// ============================================================

const { execFile } = require('child_process');
const dnsPromises = require('dns').promises;
const logger = require('../lib/logger');

const POWERSHELL_TIMEOUT_MS = 15000;

function winResolveSrv(hostname) {
  return new Promise((resolve, reject) => {
    const script = [
      `$r = Resolve-DnsName '_mongodb._tcp.${hostname}' -Type SRV -ErrorAction Stop;`,
      `$r | ForEach-Object { $_.NameTarget + ':' + $_.Port } | ConvertTo-Json -Compress`,
    ].join(' ');
    execFile(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-Command', script],
      { timeout: POWERSHELL_TIMEOUT_MS, windowsHide: true },
      (err, stdout) => {
        if (err) return reject(err);
        try {
          const parsed = JSON.parse(String(stdout || '').trim() || '[]');
          const rows = Array.isArray(parsed) ? parsed : [parsed];
          const hosts = rows
            .map((line) => {
              const [name, port] = String(line).split(':');
              return name
                ? { name: name.replace(/\.$/, ''), port: Number(port) || 27017 }
                : null;
            })
            .filter(Boolean);
          if (!hosts.length) reject(new Error('empty SRV from PowerShell'));
          else resolve(hosts);
        } catch (e) {
          reject(e);
        }
      },
    );
  });
}

async function resolveSrvHosts(hostname) {
  try {
    const srvs = await dnsPromises.resolveSrv(`_mongodb._tcp.${hostname}`);
    return srvs.map((s) => ({
      name: String(s.name).replace(/\.$/, ''),
      port: s.port || 27017,
    }));
  } catch (err) {
    if (process.platform === 'win32') {
      logger.warn(
        { err: String(err.message || err) },
        '[DB] Node SRV DNS failed — falling back to Windows Resolve-DnsName',
      );
      return winResolveSrv(hostname);
    }
    throw err;
  }
}

async function resolveTxtOptions(hostname) {
  try {
    const txt = await dnsPromises.resolveTxt(hostname);
    return txt
      .map((parts) => (Array.isArray(parts) ? parts.join('') : String(parts)))
      .join('');
  } catch {
    if (process.platform !== 'win32') return '';
    return new Promise((resolve) => {
      const script = [
        `try {`,
        `  (Resolve-DnsName '${hostname}' -Type TXT -ErrorAction Stop |`,
        `    ForEach-Object { $_.Strings -join '' }) -join '&'`,
        `} catch { '' }`,
      ].join(' ');
      execFile(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        { timeout: 10000, windowsHide: true },
        (err, stdout) => {
          if (err) return resolve('');
          resolve(String(stdout || '').trim());
        },
      );
    });
  }
}

/**
 * Convert mongodb+srv:// to an explicit mongodb:// host list. Returns the URI
 * unchanged when it is not an SRV URI.
 */
async function expandSrvUri(uri) {
  if (!uri.startsWith('mongodb+srv://')) return uri;
  const asUrl = new URL(uri.replace(/^mongodb\+srv:\/\//, 'https://'));
  const hostname = asUrl.hostname;
  const auth =
    asUrl.username || asUrl.password
      ? `${decodeURIComponent(asUrl.username)}:${decodeURIComponent(asUrl.password)}@`
      : '';
  const dbName = (asUrl.pathname || '/').replace(/^\//, '') || '';
  const hosts = await resolveSrvHosts(hostname);
  const hostList = hosts.map((h) => `${h.name}:${h.port}`).join(',');
  const txt = await resolveTxtOptions(hostname);
  const params = new URLSearchParams(asUrl.searchParams);
  params.set('ssl', 'true');
  if (txt) {
    for (const part of txt.split('&')) {
      const [k, v] = part.split('=');
      if (k && v && !params.has(k)) params.set(k, v);
    }
  }
  if (!params.has('authSource')) params.set('authSource', 'admin');
  const qs = params.toString();
  return `mongodb://${auth}${hostList}/${dbName}${qs ? `?${qs}` : ''}`;
}

module.exports = { expandSrvUri };
