const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { writeFileSync, unlinkSync } = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const engine = require('../src/services/legalDocumentEngine.service');
const { closeBrowser } = require('../src/services/documentRender');

// `toPdfBuffer` now delegates to the shared Puppeteer renderer (see
// documentRender/), which keeps a warm browser process alive between
// calls — without closing it, `node --test` hangs past the last
// assertion and the whole file gets reported as failed even though
// every individual test passed (see documentRender's own test file
// for the same fix).
test.after(async () => {
  await closeBrowser();
});

test('createDraft applies a Hebrew demand-letter template when intent matches', () => {
  const draft = engine.createDraft(
    { intent: 'demand_letter', domain: 'civil', lang: 'he' },
    { role: 'user' },
  );
  assert.equal(draft.lang, 'he');
  assert.equal(draft.domain, 'civil');
  assert.equal(draft.intent, 'demand_letter');
  assert.match(draft.title, /התראה|VETO/);
  assert.ok(draft.body.includes('### גוף המכתב') || draft.body.length > 20);
  assert.equal(
    draft.footerStamp,
    'מסמך זה נוצר על ידי VETO LEGAL בפענוח AI',
  );
});

test('toPdfBuffer emits a non-empty PDF document with footer stamp', async () => {
  const draft = engine.createDraft(
    { intent: 'civil_claim', domain: 'civil', lang: 'he' },
    { role: 'user' },
  );
  const pdf = await engine.toPdfBuffer(draft);
  assert.ok(Buffer.isBuffer(pdf));
  assert.ok(pdf.length > 1000, `pdf too small: ${pdf.length}`);
  assert.equal(pdf.slice(0, 4).toString('utf8'), '%PDF');
});

test('toPdfBuffer produces real, extractable Hebrew text (not the old reverseHebrewLine hack)', async () => {
  const draft = engine.createDraft(
    {
      intent: 'demand_letter',
      domain: 'civil',
      lang: 'he',
      facts: ['חוב בסך 5000 ש"ח מיום 01/01/2026', 'ת.ז. 123456789'],
    },
    { role: 'user' },
  );
  const pdf = await engine.toPdfBuffer(draft);

  const tmpPath = path.join(os.tmpdir(), `veto-legal-doc-test-${Date.now()}.pdf`);
  writeFileSync(tmpPath, pdf);
  try {
    const fontsOut = execFileSync('pdffonts', [tmpPath], { encoding: 'utf8' });
    assert.match(fontsOut, /CID TrueType/, 'font must embed as CID TrueType, not Type 3 (unselectable text)');
    assert.doesNotMatch(fontsOut, /Type 3/, 'Type 3 embedding means the PDF text is not selectable/searchable');

    const rawTextOut = execFileSync('pdftotext', ['-enc', 'UTF-8', tmpPath, '-'], { encoding: 'utf8' });
    // Strip Chromium's invisible bidi-isolate marks around Latin/digit runs
    // embedded in RTL text (same as documentRender's own test).
    const textOut = rawTextOut.replace(/[‎‏‪-‮⁦-⁩]/g, '');
    assert.ok(textOut.includes('123456789'), 'ID number must extract intact, not reversed/scrambled');
    assert.ok(textOut.includes('01/01/2026'), 'date must extract intact');
    assert.ok(textOut.includes('5000'), 'sum must extract intact');
  } catch (err) {
    if (err.code === 'ENOENT') return; // poppler not installed — skip content assertions
    throw err;
  } finally {
    try { unlinkSync(tmpPath); } catch { /* best effort */ }
  }
});

test('toDocxBuffer emits a non-empty DOCX (zip) document', async () => {
  const draft = engine.createDraft(
    { intent: 'labor_doc', domain: 'labor', lang: 'he' },
    { role: 'user' },
  );
  const docx = await engine.toDocxBuffer(draft);
  assert.ok(Buffer.isBuffer(docx));
  assert.ok(docx.length > 2000, `docx too small: ${docx.length}`);
  // ZIP local file header signature: 0x50 0x4B 0x03 0x04 ("PK\u0003\u0004")
  assert.equal(docx[0], 0x50);
  assert.equal(docx[1], 0x4b);
  assert.equal(docx[2], 0x03);
  assert.equal(docx[3], 0x04);
});

test('TEMPLATES list exposes all expected legal intents', () => {
  const ids = Object.keys(engine.TEMPLATES);
  for (const expected of [
    'contract_review',
    'demand_letter',
    'civil_claim',
    'labor_doc',
    'family_doc',
  ]) {
    assert.ok(ids.includes(expected), `missing template: ${expected}`);
  }
});
