const test = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { writeFileSync, unlinkSync } = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const { renderPdf, toDocxBuffer, FOOTER_STAMP, closeBrowser } = require('../src/services/documentRender');

// Without this, the warm Puppeteer/Chromium child process keeps `node
// --test`'s process alive past the last assertion, which the test
// runner surfaces as a whole-file failure even though every individual
// test passed.
test.after(async () => {
  await closeBrowser();
});

const FIXTURE = {
  title: 'הסכם שכירות למגורים',
  preamble: 'הסכם זה נערך ונחתם בין הצדדים המפורטים להלן.',
  parties: ['ישראל ישראלי, ת.ז. 123456789 (המשכיר)', 'דוד דוד, ת.ז. 987654321 (השוכר)'],
  definitions: ['"הנכס" — הדירה בכתובת רחוב הדוגמה 1.'],
  clauses: Array.from({ length: 18 }, (_, i) => `סעיף מספר ${i + 1}: תוכן לדוגמה כולל תאריך 01/01/2026 וסכום 100 ש"ח.`),
  attachments: ['נספח א׳'],
  completionChecklist: ['לוודא חתימת שני הצדדים'],
  legalNotes: ['מסמך זה אינו מהווה ייעוץ משפטי.'],
  signatures: [
    { role: 'המשכיר', name: 'ישראל ישראלי' },
    { role: 'השוכר', name: 'דוד דוד' },
  ],
};

test('renderPdf emits a real PDF with a Heebo CID-TrueType font (not Type 3)', async () => {
  const pdf = await renderPdf(FIXTURE, { lang: 'he' });
  assert.ok(Buffer.isBuffer(pdf));
  assert.equal(pdf.slice(0, 4).toString('utf8'), '%PDF');
  assert.ok(pdf.length > 5000, `pdf too small: ${pdf.length}`);

  const tmpPath = path.join(os.tmpdir(), `veto-doc-render-test-${Date.now()}.pdf`);
  writeFileSync(tmpPath, pdf);
  try {
    const fontsOut = execFileSync('pdffonts', [tmpPath], { encoding: 'utf8' });
    assert.match(fontsOut, /CID TrueType/, 'font must embed as CID TrueType, not Type 3 (unselectable text)');
    assert.doesNotMatch(fontsOut, /Type 3/, 'Type 3 embedding means the PDF text is not selectable/searchable');

    const rawTextOut = execFileSync('pdftotext', ['-enc', 'UTF-8', tmpPath, '-'], { encoding: 'utf8' });
    // Chromium inserts invisible Unicode bidi-isolate marks (U+2066-2069,
    // U+200E/F, U+202A-E) around Latin substrings embedded in RTL text
    // (e.g. "VETO LEGAL" inside the Hebrew footer stamp) — strip them
    // before doing exact substring comparisons.
    const textOut = rawTextOut.replace(/[‎‏‪-‮⁦-⁩]/g, '');
    const hebrewChars = [...textOut].filter((c) => c >= '֐' && c <= '׿').length;
    assert.ok(hebrewChars > 100, `expected substantial extractable Hebrew text, got ${hebrewChars} chars`);
    assert.ok(textOut.includes('123456789'), 'party ID number should extract intact (not reversed/scrambled)');
    assert.ok(textOut.includes('01/01/2026'), 'date should extract intact');
    // Poppler collapses/merges whitespace at Hebrew<->Latin direction-change
    // boundaries when extracting bidi text (a `pdftotext` quirk, not a
    // rendering defect — confirmed visually correct via pdftoppm). Assert
    // on the stamp's distinct word fragments rather than the exact literal
    // (which contains such a boundary around "VETO LEGAL").
    assert.ok(textOut.includes('VETO LEGAL'), 'footer stamp: "VETO LEGAL" should be present');
    for (const word of FOOTER_STAMP.split(' ').filter((w) => /^[֐-׿]+$/.test(w))) {
      assert.ok(textOut.includes(word), `footer stamp: Hebrew word "${word}" should be present`);
    }
  } catch (err) {
    if (err.code === 'ENOENT') {
      // poppler (pdftotext/pdffonts) not installed on this machine — skip
      // the content assertions but keep the basic PDF-shape check above.
      return;
    }
    throw err;
  } finally {
    try { unlinkSync(tmpPath); } catch { /* best effort */ }
  }
});

test('toDocxBuffer emits a DOCX with RTL/bidi on every paragraph and a Heebo font', async () => {
  const docx = await toDocxBuffer(FIXTURE, { lang: 'he' });
  assert.ok(Buffer.isBuffer(docx));
  assert.equal(docx[0], 0x50);
  assert.equal(docx[1], 0x4b);

  const tmpDir = path.join(os.tmpdir(), `veto-docx-test-${Date.now()}`);
  const tmpZip = `${tmpDir}.docx`;
  writeFileSync(tmpZip, docx);
  try {
    const xml = execFileSync('unzip', ['-p', tmpZip, 'word/document.xml'], { encoding: 'utf8' });
    const paragraphCount = (xml.match(/<w:p[ >]/g) || []).length;
    const bidiCount = (xml.match(/<w:bidi\/>/g) || []).length;
    const rtlCount = (xml.match(/<w:rtl\/>/g) || []).length;
    assert.ok(paragraphCount > 10, `expected multiple paragraphs, got ${paragraphCount}`);
    assert.equal(bidiCount, paragraphCount, 'every paragraph must be bidirectional');
    assert.equal(rtlCount, paragraphCount, 'every run must be marked rightToLeft');
    assert.match(xml, /w:ascii="Heebo"/, 'runs must use the Heebo font, not a Word default');

    const footerXml = execFileSync('unzip', ['-p', tmpZip, 'word/footer1.xml'], { encoding: 'utf8' });
    assert.match(footerXml, /PAGE/, 'footer must contain a PAGE field');
    assert.match(footerXml, /NUMPAGES/, 'footer must contain a NUMPAGES field');
  } catch (err) {
    if (err.code === 'ENOENT') return; // unzip not installed — skip XML assertions
    throw err;
  } finally {
    try { unlinkSync(tmpZip); } catch { /* best effort */ }
  }
});
