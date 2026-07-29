// ============================================================
//  documentRender/index.js — server-side PDF export with real,
//  selectable, correctly-shaped Hebrew text (Chromium's bidi/HarfBuzz
//  engine), proper page breaks, and a running header/footer with page
//  numbers. Replaces the client-side html2canvas+jsPDF rasterization
//  path (see web-client/src/app/vault/generator/page.tsx) which
//  produced non-selectable JPEG pages with naive image-slice
//  pagination that cut clauses mid-line.
// ============================================================

const { withBrowser, heeboFontDataUris, closeBrowser } = require('./browser');
const { renderDocumentHtml, renderLegacyDraftHtml, FOOTER_STAMP } = require('./template');
const { toDocxBuffer } = require('./docx');

/** Prints an already-built HTML string to a PDF buffer with the shared
 * A4 layout, running header/footer, and Hebrew-safe header/footer font
 * (Chromium does not inherit page `<style>` into header/footer
 * templates, so they need their own inline `@font-face`). */
async function printHtmlToPdf(html, { isRtl, hasHeebo, fonts }) {
  return withBrowser(async (browser) => {
    const page = await browser.newPage();
    try {
      await page.setContent(html, { waitUntil: 'networkidle0' });
      await page.evaluateHandle('document.fonts.ready');

      const fontFace = hasHeebo
        ? `@font-face { font-family: 'Heebo'; src: url('${fonts.regular}') format('truetype'); font-weight: 400; }`
        : '';
      const headerFooterStyle = `
        <style>
          ${fontFace}
          * { font-family: ${hasHeebo ? "'Heebo', " : ''}'Segoe UI', Arial, sans-serif; }
          .hf { width: 100%; font-size: 8pt; color: #6b7280; padding: 0 20mm; box-sizing: border-box;
                direction: ${isRtl ? 'rtl' : 'ltr'}; display: flex; justify-content: space-between; }
        </style>`;

      const headerTemplate = `${headerFooterStyle}<div class="hf"><span></span><span></span></div>`;
      const footerTemplate = `${headerFooterStyle}
        <div class="hf" style="justify-content:center; flex-direction:column; align-items:center; gap:1mm;">
          <span>${FOOTER_STAMP}</span>
          <span>${isRtl ? 'עמוד' : 'Page'} <span class="pageNumber"></span> ${isRtl ? 'מתוך' : 'of'} <span class="totalPages"></span></span>
        </div>`;

      const pdf = await page.pdf({
        format: 'A4',
        printBackground: true,
        preferCSSPageSize: true,
        displayHeaderFooter: true,
        headerTemplate,
        footerTemplate,
        margin: { top: '24mm', bottom: '26mm', left: '20mm', right: '20mm' },
      });
      // Puppeteer 25 returns a Uint8Array (not a Node Buffer) from
      // `page.pdf()` when no `path` option is given; normalize so callers
      // can rely on Buffer methods (`.slice`, `res.send`, etc.).
      return Buffer.from(pdf);
    } finally {
      await page.close();
    }
  });
}

/** @param {import('./template').SerializedLegalDocument} doc */
async function renderPdf(doc, opts = {}) {
  const lang = ['he', 'en', 'ru'].includes(opts.lang) ? opts.lang : 'he';
  const isRtl = lang === 'he';
  const fonts = heeboFontDataUris();
  const hasHeebo = !!fonts.regular;
  const html = renderDocumentHtml(doc, { lang, hasHeebo, heeboFontDataUris: fonts });
  return printHtmlToPdf(html, { isRtl, hasHeebo, fonts });
}

/**
 * PDF export for the legacy `{title, body}` draft shape (Flutter client,
 * `legalDocumentEngine.service.js` / `POST /api/legal-documents/export`).
 * Replaces the old PDFKit + `reverseHebrewLine` path, which reversed
 * Hebrew character order to fake RTL and broke on any line mixing
 * Hebrew with digits/Latin (ID numbers, dates, sums) — Chromium's real
 * bidi/HarfBuzz engine (same pipeline as `renderPdf` above) needs no
 * such hack.
 * @param {{ title: string, body: string, lang?: 'he'|'en'|'ru' }} draft
 */
async function renderLegacyDraftPdf(draft) {
  const lang = ['he', 'en', 'ru'].includes(draft.lang) ? draft.lang : 'he';
  const isRtl = lang === 'he';
  const fonts = heeboFontDataUris();
  const hasHeebo = !!fonts.regular;
  const html = renderLegacyDraftHtml(draft, { hasHeebo, heeboFontDataUris: fonts });
  return printHtmlToPdf(html, { isRtl, hasHeebo, fonts });
}

module.exports = { renderPdf, renderLegacyDraftPdf, toDocxBuffer, FOOTER_STAMP, closeBrowser };
