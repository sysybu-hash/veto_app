// ============================================================
//  template.js — structured legal-document draft -> print-ready HTML
//
//  Input shape matches `SerializedLegalDocument` in
//  web-client/src/lib/documentSerialize.ts:
//    { title, preamble, parties, definitions, clauses, attachments,
//      completionChecklist, legalNotes, signatures: {role, name}[] }
// ============================================================

const { documentCss } = require('./document.css');
const { FOOTER_STAMP } = require('./constants');

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function numberedList(items, { plain = false } = {}) {
  if (!items || !items.length) return '';
  return `<ol class="${plain ? 'plain' : ''}">${items
    .map(
      (item, i) =>
        `<li class="numbered"><span class="idx">${i + 1}.</span><span>${escapeHtml(item)}</span></li>`,
    )
    .join('')}</ol>`;
}

function section(title, bodyHtml, { boxed = true, extraClass = '' } = {}) {
  if (!bodyHtml) return '';
  return `<section class="${boxed ? 'section-box' : ''} ${extraClass}">
    <h2 class="section-title">${escapeHtml(title)}</h2>
    ${bodyHtml}
  </section>`;
}

/**
 * @param {object} doc SerializedLegalDocument
 * @param {object} opts { lang?: 'he'|'en'|'ru', hasHeebo: boolean, heeboFontDataUris?: { regular: string, bold: string } }
 */
function renderDocumentHtml(doc, opts = {}) {
  const lang = ['he', 'en', 'ru'].includes(opts.lang) ? opts.lang : 'he';
  const isRtl = lang === 'he';
  const hasHeebo = !!opts.hasHeebo;

  const partiesHtml = section(isRtl ? 'הצדדים' : 'Parties', numberedList(doc.parties));
  const definitionsHtml = section(isRtl ? 'הגדרות' : 'Definitions', numberedList(doc.definitions));
  const clausesHtml = `<h2 class="section-title">${isRtl ? 'סעיפים' : 'Clauses'}</h2>${numberedList(doc.clauses)}`;
  const attachmentsHtml = section(
    isRtl ? 'נספחים מומלצים' : 'Recommended attachments',
    doc.attachments && doc.attachments.length
      ? `<ul>${doc.attachments.map((a) => `<li>${escapeHtml(a)}</li>`).join('')}</ul>`
      : '',
    { boxed: false },
  );
  const checklistHtml = doc.completionChecklist && doc.completionChecklist.length
    ? `<section class="checklist-box">
        <h2 class="section-title">${isRtl ? "צ'קליסט לפני שימוש" : 'Pre-use checklist'}</h2>
        ${numberedList(doc.completionChecklist)}
      </section>`
    : '';
  const legalNotesHtml = section(
    isRtl ? 'הערות משפטיות' : 'Legal notes',
    doc.legalNotes && doc.legalNotes.length
      ? `<ul class="legal-notes">${doc.legalNotes.map((n) => `<li>${escapeHtml(n)}</li>`).join('')}</ul>`
      : '',
    { boxed: false },
  );

  const signaturesHtml = `<section class="signatures">
    <h2 class="section-title">${isRtl ? 'חתימות' : 'Signatures'}</h2>
    <div class="signatures-grid">
      ${(doc.signatures || [])
        .map(
          (sig) => `<div>
            <div class="sig-line"></div>
            <p class="sig-role">${escapeHtml(sig.role)}</p>
            ${sig.name ? `<p class="sig-name">${escapeHtml(sig.name)}</p>` : ''}
          </div>`,
        )
        .join('')}
    </div>
  </section>`;

  const heebbFontFace = hasHeebo
    ? `@font-face {
        font-family: 'Heebo';
        src: url('${opts.heeboFontDataUris.regular}') format('truetype');
        font-weight: 400;
      }
      @font-face {
        font-family: 'Heebo';
        src: url('${opts.heeboFontDataUris.bold}') format('truetype');
        font-weight: 700 900;
      }`
    : '';

  return `<!doctype html>
<html lang="${lang}" dir="${isRtl ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8" />
<title>${escapeHtml(doc.title)}</title>
<style>
  ${heebbFontFace}
  ${documentCss({ isRtl, hasHeebo })}
</style>
</head>
<body>
  <div class="doc-frame">
    <h1 class="doc-title">${escapeHtml(doc.title)}</h1>
    <p class="preamble">${escapeHtml(doc.preamble)}</p>
    ${partiesHtml}
    ${definitionsHtml}
    ${clausesHtml}
    ${attachmentsHtml}
    ${checklistHtml}
    ${legalNotesHtml}
    ${signaturesHtml}
  </div>
</body>
</html>`;
}

module.exports = { renderDocumentHtml, escapeHtml, FOOTER_STAMP };
