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
const { renderDocumentHtml, FOOTER_STAMP } = require('./template');
const { toDocxBuffer } = require('./docx');

/** @param {import('./template').SerializedLegalDocument} doc */
async function renderPdf(doc, opts = {}) {
  const lang = ['he', 'en', 'ru'].includes(opts.lang) ? opts.lang : 'he';
  const isRtl = lang === 'he';
  const fonts = heeboFontDataUris();
  const hasHeebo = !!fonts.regular;

  const html = renderDocumentHtml(doc, { lang, hasHeebo, heeboFontDataUris: fonts });

  return withBrowser(async (browser) => {
    const page = await browser.newPage();
    try {
      await page.setContent(html, { waitUntil: 'networkidle0' });
      await page.evaluateHandle('document.fonts.ready');

      // Chromium does NOT inherit page <style> into header/footer
      // templates — they need their own inline @font-face or Hebrew
      // page numbers silently fall back to a non-Hebrew system font.
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

module.exports = { renderPdf, toDocxBuffer, FOOTER_STAMP, closeBrowser };
