const PDFDocument = require('pdfkit');
const { Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Footer } = require('docx');

const FOOTER_STAMP = 'מסמך זה נוצר על ידי VETO LEGAL בפענוח AI';

function buildTitle(domain, lang = 'he') {
  if (lang === 'en') return `VETO Legal Draft — ${domain}`;
  if (lang === 'ru') return `VETO Юридический документ — ${domain}`;
  return `טיוטה משפטית — ${domain}`;
}

function buildBody({ domain, intent, facts, lang = 'he' }) {
  const intro = lang === 'en'
    ? `Legal draft for ${domain} / ${intent}.`
    : lang === 'ru'
      ? `Юридический черновик по теме ${domain} / ${intent}.`
      : `טיוטה משפטית בנושא ${domain} / ${intent}.`;
  const bullets = (Array.isArray(facts) ? facts : [])
    .filter(Boolean)
    .map((f, i) => `${i + 1}. ${String(f).trim()}`)
    .join('\n');
  const fallback = lang === 'he'
    ? 'פרטי המקרה יושלמו על ידי המשתמש לפני הגשה רשמית.'
    : lang === 'ru'
      ? 'Детали дела будут уточнены пользователем перед официальной подачей.'
      : 'Case details must be completed by the user before official filing.';
  return `${intro}\n\n${bullets || fallback}\n`;
}

function createDraft(payload = {}, user = {}) {
  const domain = String(payload.domain || 'כללי');
  const intent = String(payload.intent || 'מסמך משפטי');
  const lang = ['he', 'en', 'ru'].includes(payload.lang) ? payload.lang : 'he';
  const title = String(payload.title || buildTitle(domain, lang));
  const body = String(payload.body || buildBody({ ...payload, domain, intent, lang }));
  return {
    title,
    body,
    lang,
    domain,
    intent,
    createdBy: {
      id: user.userId || user.id || user.sub || null,
      role: user.role || null,
      phone: user.phone || null,
    },
    footerStamp: FOOTER_STAMP,
    createdAt: new Date().toISOString(),
  };
}

async function toDocxBuffer(draft) {
  const doc = new Document({
    sections: [
      {
        properties: {},
        footers: {
          default: new Footer({
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [new TextRun({ text: FOOTER_STAMP, size: 18, color: '6B7280' })],
              }),
            ],
          }),
        },
        children: [
          new Paragraph({
            text: draft.title,
            heading: HeadingLevel.HEADING_1,
          }),
          new Paragraph({ text: '' }),
          ...draft.body.split('\n').map((line) => new Paragraph({ text: line || ' ' })),
        ],
      },
    ],
  });
  return Packer.toBuffer(doc);
}

async function toPdfBuffer(draft) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 56, size: 'A4' });
      const chunks = [];
      doc.on('data', (c) => chunks.push(c));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      doc.fontSize(18).text(draft.title, { align: 'right' });
      doc.moveDown(1);
      doc.fontSize(12);
      for (const line of draft.body.split('\n')) {
        doc.text(line || ' ', { align: 'right' });
      }
      doc.moveDown(2);
      doc.fontSize(9).fillColor('#6B7280').text(FOOTER_STAMP, {
        align: 'center',
      });
      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

module.exports = {
  FOOTER_STAMP,
  createDraft,
  toDocxBuffer,
  toPdfBuffer,
};

