#!/usr/bin/env node
// ============================================================
//  health-ping.js — keeps Render Free web dyno warm
//  Triggered by cron every 14 min from render.yaml.
//  Hits HEALTH_URL with a 10s timeout, logs a single line, exits 0.
//  We treat any 2xx/3xx as success; 5xx still exits 0 so a flapping
//  backend doesn't spam Render with cron failure emails (the web
//  service has its own /health alerts).
// ============================================================

const url =
  process.env.HEALTH_URL ||
  'https://veto-app-new.onrender.com/health';

const controller = new AbortController();
const timer = setTimeout(() => controller.abort(), 10_000);
const startedAt = Date.now();

fetch(url, {
  method: 'GET',
  headers: { 'user-agent': 'veto-health-ping/1.0' },
  signal: controller.signal,
})
  .then(async (res) => {
    const text = await res.text().catch(() => '');
    const elapsed = Date.now() - startedAt;
    console.log(
      JSON.stringify({
        ok: res.ok,
        status: res.status,
        elapsed_ms: elapsed,
        body: text.slice(0, 200),
        url,
        ts: new Date().toISOString(),
      }),
    );
  })
  .catch((err) => {
    const elapsed = Date.now() - startedAt;
    console.warn(
      JSON.stringify({
        ok: false,
        error: err && err.message ? err.message : String(err),
        elapsed_ms: elapsed,
        url,
        ts: new Date().toISOString(),
      }),
    );
  })
  .finally(() => {
    clearTimeout(timer);
  });
