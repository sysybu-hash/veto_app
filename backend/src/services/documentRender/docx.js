// ============================================================
//  documentRender/docx.js — structured legal-document draft -> DOCX
//
//  Generalizes the RTL/Hebrew-font handling proven out in
//  legalDocumentEngine.service.js (bidirectional, rightToLeft, Heebo
//  font on every run, footer stamp) to the structured document shape
//  used by the web-client generator, and adds what that legacy path
//  was missing: a header, PAGE/NUMPAGES fields, a real bordered table
//  for parties, and a signature block built from bottom-bordered
//  cells instead of underscore characters.
// ============================================================

const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  AlignmentType,
  Header,
  Footer,
  Table,
  TableRow,
  TableCell,
  WidthType,
  BorderStyle,
  PageNumber,
} = require('docx');

const { FOOTER_STAMP, HEBREW_FONT_NAME } = require('./constants');

function run(text, opts = {}) {
  return new TextRun({ text: text || '', font: HEBREW_FONT_NAME, ...opts });
}

function para(text, { isRtl, heading, bold, size, alignment, spacing, color } = {}) {
  return new Paragraph({
    heading,
    bidirectional: isRtl,
    alignment: alignment ?? (isRtl ? AlignmentType.RIGHT : AlignmentType.LEFT),
    spacing: spacing ?? { after: 160 },
    children: [run(text, { rightToLeft: isRtl, bold, size, color })],
  });
}

function numberedParas(items, isRtl, opts = {}) {
  return (items || []).map((item, i) => para(`${i + 1}. ${item}`, { isRtl, ...opts }));
}

const thinBorder = { style: BorderStyle.SINGLE, size: 4, color: '94A3B8' };
const cellBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };

function partiesTable(parties, isRtl) {
  if (!parties || !parties.length) return [];
  const rows = parties.map(
    (p, i) =>
      new TableRow({
        children: [
          new TableCell({
            borders: cellBorders,
            width: { size: 8, type: WidthType.PERCENTAGE },
            children: [para(String(i + 1), { isRtl, bold: true, alignment: AlignmentType.CENTER })],
          }),
          new TableCell({
            borders: cellBorders,
            width: { size: 92, type: WidthType.PERCENTAGE },
            children: [para(p, { isRtl })],
          }),
        ],
      }),
  );
  return [
    para('הצדדים', { isRtl, heading: HeadingLevel.HEADING_2 }),
    new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows }),
    para('', { isRtl }),
  ];
}

function signaturesSection(signatures, isRtl) {
  if (!signatures || !signatures.length) return [];
  const cells = signatures.map(
    (sig) =>
      new TableCell({
        margins: { top: 200, bottom: 200, left: 200, right: 200 },
        borders: { top: {}, left: {}, right: {}, bottom: thinBorder },
        children: [
          para(' ', { isRtl, spacing: { after: 400 } }),
          para(sig.role, { isRtl, bold: true, alignment: AlignmentType.CENTER, spacing: { after: 40 } }),
          para(sig.name || '', { isRtl, size: 18, color: '475569', alignment: AlignmentType.CENTER }),
        ],
      }),
  );
  const rows = [];
  for (let i = 0; i < cells.length; i += 2) {
    rows.push(new TableRow({ children: cells.slice(i, i + 2) }));
  }
  return [
    para('חתימות', { isRtl, heading: HeadingLevel.HEADING_2, spacing: { before: 400, after: 200 } }),
    new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, borders: { insideHorizontal: {}, insideVertical: {} }, rows }),
  ];
}

/** @param {import('./template').SerializedLegalDocument} doc */
async function toDocxBuffer(doc, opts = {}) {
  const lang = ['he', 'en', 'ru'].includes(opts.lang) ? opts.lang : 'he';
  const isRtl = lang === 'he';

  const children = [];
  children.push(para(doc.title, { isRtl, heading: HeadingLevel.HEADING_1, alignment: AlignmentType.CENTER, spacing: { after: 300 } }));
  children.push(para(doc.preamble, { isRtl, spacing: { after: 300 } }));
  children.push(...partiesTable(doc.parties, isRtl));

  if (doc.definitions?.length) {
    children.push(para('הגדרות', { isRtl, heading: HeadingLevel.HEADING_2 }));
    children.push(...numberedParas(doc.definitions, isRtl));
  }

  children.push(para('סעיפים', { isRtl, heading: HeadingLevel.HEADING_2 }));
  children.push(...numberedParas(doc.clauses, isRtl));

  if (doc.attachments?.length) {
    children.push(para('נספחים מומלצים', { isRtl, heading: HeadingLevel.HEADING_2 }));
    children.push(...(doc.attachments || []).map((a) => para(`•  ${a}`, { isRtl })));
  }

  if (doc.completionChecklist?.length) {
    children.push(para("צ'קליסט לפני שימוש", { isRtl, heading: HeadingLevel.HEADING_2 }));
    children.push(...numberedParas(doc.completionChecklist, isRtl));
  }

  if (doc.legalNotes?.length) {
    children.push(para('הערות משפטיות', { isRtl, heading: HeadingLevel.HEADING_2 }));
    children.push(...(doc.legalNotes || []).map((n) => para(`•  ${n}`, { isRtl, size: 18, color: '475569' })));
  }

  children.push(...signaturesSection(doc.signatures, isRtl));

  const docx = new Document({
    styles: { default: { document: { run: { font: HEBREW_FONT_NAME, size: 22 } } } },
    sections: [
      {
        properties: {},
        headers: {
          default: new Header({
            children: [
              new Paragraph({
                bidirectional: isRtl,
                alignment: isRtl ? AlignmentType.RIGHT : AlignmentType.LEFT,
                children: [run(doc.title, { rightToLeft: isRtl, size: 16, color: '94A3B8' })],
              }),
            ],
          }),
        },
        footers: {
          default: new Footer({
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                bidirectional: isRtl,
                children: [run(FOOTER_STAMP, { rightToLeft: isRtl, size: 16, color: '6B7280' })],
              }),
              new Paragraph({
                alignment: AlignmentType.CENTER,
                bidirectional: isRtl,
                children: [
                  run(isRtl ? 'עמוד ' : 'Page ', { rightToLeft: isRtl, size: 16, color: '6B7280' }),
                  new TextRun({ children: [PageNumber.CURRENT], font: HEBREW_FONT_NAME, size: 16, color: '6B7280' }),
                  run(isRtl ? ' מתוך ' : ' of ', { rightToLeft: isRtl, size: 16, color: '6B7280' }),
                  new TextRun({ children: [PageNumber.TOTAL_PAGES], font: HEBREW_FONT_NAME, size: 16, color: '6B7280' }),
                ],
              }),
            ],
          }),
        },
        children,
      },
    ],
  });

  return Packer.toBuffer(docx);
}

module.exports = { toDocxBuffer, HEBREW_FONT_NAME, FOOTER_STAMP };
