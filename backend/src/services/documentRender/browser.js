// ============================================================
//  browser.js — singleton Puppeteer browser + a simple mutex queue.
//  Document export is low-frequency and CPU-heavy (Chromium layout);
//  one warm browser instance shared across requests avoids paying
//  Chromium's ~1s startup cost per export, and the queue keeps
//  concurrent exports from fighting over the same page count.
// ============================================================

const fs = require('fs');
const path = require('path');
const logger = require('../../lib/logger');

let browserPromise = null;
let idleTimer = null;
const IDLE_CLOSE_MS = 5 * 60 * 1000;

function scheduleIdleClose() {
  if (idleTimer) clearTimeout(idleTimer);
  idleTimer = setTimeout(async () => {
    if (browserPromise) {
      try {
        const browser = await browserPromise;
        await browser.close();
      } catch (err) {
        logger.warn({ err }, 'documentRender: error closing idle browser');
      }
      browserPromise = null;
    }
  }, IDLE_CLOSE_MS);
  idleTimer.unref?.();
}

async function getBrowser() {
  if (!browserPromise) {
    const puppeteer = require('puppeteer');
    browserPromise = puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
    });
    browserPromise.catch(() => {
      browserPromise = null;
    });
  }
  return browserPromise;
}

let queue = Promise.resolve();

/** Runs `fn(browser)` serialized behind the last queued export, and
 * resets the idle-close timer around it. */
function withBrowser(fn) {
  const run = queue.then(async () => {
    if (idleTimer) clearTimeout(idleTimer);
    const browser = await getBrowser();
    try {
      return await fn(browser);
    } finally {
      scheduleIdleClose();
    }
  });
  // Keep the queue alive even if this particular job rejects.
  queue = run.catch(() => {});
  return run;
}

// Chromium's PDF/Skia backend cannot embed OpenType *variable* fonts as
// proper CID TrueType — it silently falls back to Type 3 (per-glyph
// vector-drawn) embedding, which renders identically on screen/print but
// produces PDF text that is not selectable or searchable (no reliable
// ToUnicode mapping). `Heebo-Variable.ttf` is a variable font, so we use
// fixed-weight static instances (generated once via
// `python -m fontTools varLib.instancer`, see fonts/README) for the PDF
// path. Verified: static instances embed as `CID TrueType` / `Identity-H`
// with a full Unicode map; the variable font embeds as `Type 3`.
const FONT_DIR = path.join(__dirname, '..', '..', 'assets', 'fonts');
const FONT_FILES = {
  regular: path.join(FONT_DIR, 'Heebo-Regular-static.ttf'),
  bold: path.join(FONT_DIR, 'Heebo-Bold-static.ttf'),
};
const dataUriCache = {};

function fontDataUri(weight) {
  if (dataUriCache[weight] !== undefined) return dataUriCache[weight];
  try {
    const buf = fs.readFileSync(FONT_FILES[weight]);
    dataUriCache[weight] = `data:font/ttf;base64,${buf.toString('base64')}`;
  } catch {
    dataUriCache[weight] = '';
  }
  return dataUriCache[weight];
}

function heeboFontDataUris() {
  return { regular: fontDataUri('regular'), bold: fontDataUri('bold') };
}

/** Explicit shutdown — for graceful server shutdown and test suites,
 * where a lingering Chromium child process would otherwise keep the
 * Node process (or `node --test`) from exiting on its own. */
async function closeBrowser() {
  if (idleTimer) clearTimeout(idleTimer);
  if (!browserPromise) return;
  try {
    const browser = await browserPromise;
    await browser.close();
  } catch (err) {
    logger.warn({ err }, 'documentRender: error closing browser');
  }
  browserPromise = null;
}

module.exports = { withBrowser, heeboFontDataUris, closeBrowser };
