// ============================================================
//  document.css.js — print stylesheet shared by the Puppeteer PDF
//  render and (as a string) available for a future in-browser
//  preview. A4, real margins, borders, and page-break rules so
//  clauses/signature blocks never get cut mid-line.
//
//  Kept as a `.js` export (not a static `.css` file) because it is
//  inlined into the rendered HTML — Puppeteer prints the page as
//  Chromium sees it, so the stylesheet must travel with the markup.
// ============================================================

const { FOOTER_STAMP } = require('./constants');

function documentCss({ isRtl, hasHeebo }) {
  return `
    @page {
      size: A4 portrait;
      margin: 24mm 20mm 26mm;
    }
    @page :first {
      margin-top: 30mm;
    }
    html, body {
      margin: 0;
      padding: 0;
      background: #ffffff;
      color: #0f172a;
    }
    body {
      direction: ${isRtl ? "rtl" : "ltr"};
      font-family: ${hasHeebo ? "'Heebo', " : ""}'Segoe UI', Arial, sans-serif;
      font-size: 11.5pt;
      line-height: 1.65;
    }
    .doc-frame {
      border: 1.2pt solid #0f172a;
      border-radius: 4pt;
      padding: 8mm;
    }
    h1, h2, h3 {
      break-after: avoid-page;
      font-weight: 800;
    }
    h1.doc-title {
      text-align: center;
      font-size: 20pt;
      margin: 0 0 6mm;
      text-decoration: underline;
      text-underline-offset: 4pt;
    }
    h2.section-title {
      font-size: 13pt;
      margin: 6mm 0 3mm;
    }
    p.preamble {
      white-space: pre-wrap;
      margin: 0 0 6mm;
    }
    .section-box {
      border: 0.8pt solid #94a3b8;
      border-radius: 3pt;
      padding: 4mm;
      margin: 0 0 6mm;
      break-inside: avoid-page;
    }
    .checklist-box {
      border: 0.8pt solid #d97706;
      background: #fffbeb;
      border-radius: 3pt;
      padding: 4mm;
      margin: 8mm 0 0;
    }
    ol, ul {
      margin: 0;
      padding-inline-start: 6mm;
    }
    ol.plain, ul.plain {
      list-style: none;
      padding-inline-start: 0;
    }
    li, p, tr {
      break-inside: avoid-page;
      orphans: 3;
      widows: 3;
    }
    li.numbered {
      display: flex;
      gap: 3mm;
      margin: 0 0 2mm;
    }
    li.numbered .idx {
      font-weight: 800;
      flex: none;
    }
    .signatures {
      break-before: page;
      margin-top: 12mm;
    }
    .signatures-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10mm;
      margin-top: 10mm;
    }
    .sig-line {
      border-bottom: 0.8pt solid #64748b;
      height: 10mm;
      margin-bottom: 2mm;
    }
    .sig-role {
      font-weight: 700;
    }
    .sig-name {
      font-size: 10pt;
      color: #475569;
    }
    .legal-notes {
      color: #334155;
      font-size: 10pt;
    }
    a[href]::after { content: ""; }
  `;
}

module.exports = { documentCss, FOOTER_STAMP };
