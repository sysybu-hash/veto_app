// ============================================================
//  legalDocumentEngine.service.js — Hebrew-aware PDF + DOCX export
//
//  - PDF: PDFKit + Heebo Hebrew TTF (registered at startup, falls
//    back to Helvetica if the font file is missing).
//  - DOCX: docx with bidirectional + rightToLeft + Heebo font on
//    every paragraph + footer for proper Hebrew rendering.
//  - Mandatory footer stamp on every export.
// ============================================================

const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  AlignmentType,
  Footer,
  PageBreak,
} = require('docx');

const FOOTER_STAMP = 'מסמך זה נוצר על ידי VETO LEGAL בפענוח AI';
const HEBREW_FONT_NAME = 'Heebo';
const FONT_PATH = path.join(__dirname, '..', 'assets', 'fonts', 'Heebo-Variable.ttf');
const HAS_HEBREW_FONT = fs.existsSync(FONT_PATH);

// ────────────────────────────────────────────────────────────
//  Templates: per intent + domain.
//  Returns Hebrew skeleton bodies the user can edit before export.
// ────────────────────────────────────────────────────────────
const TEMPLATES = {
  contract_review: {
    title: 'סקירת חוזה — חוות דעת ראשונית',
    sections: [
      { h: 'רקע', body: 'תיאור הצדדים, מועד החתימה ונסיבות העסקה.' },
      { h: 'תניות מהותיות', body: '1. _____\n2. _____\n3. _____' },
      {
        h: 'סעיפי סיכון',
        body:
          'יש לבחון: סעיף שיפוט וסמכות, פיצוי מוסכם, הגבלת אחריות, יציאה / סיום, הצמדה ומדדים.',
      },
      { h: 'המלצה', body: 'המלצה משפטית כללית בכפוף לבדיקה פרטנית של הסעיפים.' },
    ],
  },
  demand_letter: {
    title: 'מכתב התראה לפני נקיטת הליכים משפטיים',
    sections: [
      { h: 'אל', body: '__________' },
      { h: 'הנדון', body: 'דרישה לתשלום / תיקון הפרת חוזה' },
      {
        h: 'גוף המכתב',
        body:
          'בהתאם להסכם מיום ____, ובהתבסס על הפרת התחייבויותיך, הריני לדרוש בזאת [פירוט הדרישה] בתוך [מספר ימים] ימים מיום קבלת מכתב זה. ככל שלא ייענה — תינקטנה כל הפעולות המשפטיות לרשותי לרבות הגשת תביעה.',
      },
      { h: 'בכבוד רב', body: '__________' },
    ],
  },
  civil_claim: {
    title: 'כתב תביעה — תיק אזרחי',
    sections: [
      { h: 'התובע', body: '__________ ת.ז. __________' },
      { h: 'הנתבע', body: '__________ ת.ז. __________' },
      { h: 'מהות התביעה', body: '__________' },
      { h: 'העובדות', body: '1. _____\n2. _____\n3. _____' },
      {
        h: 'הסעדים המבוקשים',
        body:
          '1. לחייב את הנתבע לשלם לתובע סך של ____ ש"ח.\n2. לחייב את הנתבע בהוצאות משפט ושכר טרחת עו"ד.',
      },
    ],
  },
  labor_doc: {
    title: 'דיני עבודה — מסמך תביעה / טיוטה',
    sections: [
      { h: 'פרטי העובד', body: '__________' },
      { h: 'פרטי המעסיק', body: '__________' },
      { h: 'תקופת ההעסקה', body: 'מ-____ עד ____' },
      {
        h: 'עילות',
        body:
          '1. אי תשלום שכר.\n2. אי הפרשות פנסיה.\n3. הלנת שכר.\n4. פיטורים שלא כדין.',
      },
      {
        h: 'הסעדים',
        body:
          'תשלום הפרשי שכר, פיצויי פיטורים, פיצויי הלנה, הפרשות פנסיוניות וכל סעד נוסף שיתבקש.',
      },
    ],
  },
  family_doc: {
    title: 'דיני משפחה — מסמך משפטי',
    sections: [
      { h: 'הצדדים', body: '__________' },
      { h: 'מהות', body: 'הסכם / תביעה למזונות / משמורת / חלוקת רכוש' },
      { h: 'תיאור', body: '__________' },
      { h: 'הסעדים', body: '__________' },
    ],
  },
};

function buildTitleFromTemplate(templateKey, title, lang) {
  if (title && title.trim()) return title.trim();
  const tpl = TEMPLATES[templateKey];
  if (tpl) return tpl.title;
  if (lang === 'en') return 'VETO Legal Draft';
  if (lang === 'ru') return 'VETO Юридический документ';
  return 'טיוטה משפטית — VETO';
}

function buildTemplatedBody({ intent, facts, body }) {
  if (body && body.trim().length) return body.trim();
  const tpl = TEMPLATES[intent];
  const factsList = (Array.isArray(facts) ? facts : [])
    .filter(Boolean)
    .map((f, i) => `${i + 1}. ${String(f).trim()}`)
    .join('\n');
  if (tpl) {
    const parts = tpl.sections
      .map((s) => `### ${s.h}\n${s.body}`)
      .join('\n\n');
    if (factsList) {
      return `${parts}\n\n### עובדות\n${factsList}`;
    }
    return parts;
  }
  if (factsList) return factsList;
  return 'פרטי המקרה יושלמו על ידי המשתמש לפני הגשה רשמית.';
}

function createDraft(payload = {}, user = {}) {
  const domain = String(payload.domain || 'כללי');
  const intent = String(payload.intent || 'מסמך משפטי');
  const lang = ['he', 'en', 'ru'].includes(payload.lang) ? payload.lang : 'he';
  const title = buildTitleFromTemplate(intent, payload.title, lang);
  const body = buildTemplatedBody({
    intent,
    facts: payload.facts,
    body: payload.body,
  });
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

// ────────────────────────────────────────────────────────────
//  DOCX builder — explicit Hebrew font + RTL on every paragraph.
// ────────────────────────────────────────────────────────────
async function toDocxBuffer(draft) {
  const isRtl = draft.lang === 'he';
  const headingPara = (text, h) =>
    new Paragraph({
      heading: h,
      bidirectional: isRtl,
      alignment: isRtl ? AlignmentType.RIGHT : AlignmentType.LEFT,
      children: [
        new TextRun({
          text,
          bold: true,
          rightToLeft: isRtl,
          font: HEBREW_FONT_NAME,
        }),
      ],
    });
  const textPara = (text) =>
    new Paragraph({
      bidirectional: isRtl,
      alignment: isRtl ? AlignmentType.RIGHT : AlignmentType.LEFT,
      children: [
        new TextRun({
          text: text || ' ',
          rightToLeft: isRtl,
          font: HEBREW_FONT_NAME,
        }),
      ],
    });

  const bodyChildren = [];
  bodyChildren.push(headingPara(draft.title, HeadingLevel.HEADING_1));
  bodyChildren.push(textPara(''));

  for (const block of draft.body.split('\n\n')) {
    const trimmed = block.trim();
    if (!trimmed) {
      bodyChildren.push(textPara(''));
      continue;
    }
    if (trimmed.startsWith('### ')) {
      bodyChildren.push(headingPara(trimmed.slice(4), HeadingLevel.HEADING_2));
    } else {
      for (const line of trimmed.split('\n')) {
        bodyChildren.push(textPara(line));
      }
    }
    bodyChildren.push(textPara(''));
  }

  const doc = new Document({
    styles: {
      default: {
        document: {
          run: { font: HEBREW_FONT_NAME, size: 22 },
        },
      },
    },
    sections: [
      {
        properties: {},
        footers: {
          default: new Footer({
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                bidirectional: isRtl,
                children: [
                  new TextRun({
                    text: FOOTER_STAMP,
                    rightToLeft: isRtl,
                    font: HEBREW_FONT_NAME,
                    size: 18,
                    color: '6B7280',
                  }),
                ],
              }),
            ],
          }),
        },
        children: bodyChildren,
      },
    ],
  });
  return Packer.toBuffer(doc);
}

// ────────────────────────────────────────────────────────────
//  PDF builder — Hebrew font + reverse-shaping for RTL.
//  PDFKit does not implement bidi; we reverse Hebrew lines so
//  the rendered output reads correctly from right to left.
// ────────────────────────────────────────────────────────────
function reverseHebrewLine(line) {
  if (!line) return '';
  // Reverse runs but keep numbers/Latin token order inside the run.
  const tokens = line.match(/[A-Za-z0-9_./@:?\-]+|[\u0590-\u05FF]+|[\s.,;:!?'"()\[\]{}]+|.{1}/g);
  if (!tokens) return line.split('').reverse().join('');
  return tokens.reverse().join('');
}

function shapeForPdf(line, lang) {
  if (lang !== 'he') return line;
  return reverseHebrewLine(line);
}

async function toPdfBuffer(draft) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 56, size: 'A4', bufferPages: true });
      const chunks = [];
      doc.on('data', (c) => chunks.push(c));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      if (HAS_HEBREW_FONT) {
        doc.registerFont(HEBREW_FONT_NAME, FONT_PATH);
        doc.font(HEBREW_FONT_NAME);
      }

      const align = draft.lang === 'he' ? 'right' : 'left';

      doc
        .fontSize(20)
        .text(shapeForPdf(draft.title, draft.lang), { align });
      doc.moveDown(1);
      doc.fontSize(12);

      for (const block of draft.body.split('\n\n')) {
        const trimmed = block.trim();
        if (!trimmed) {
          doc.moveDown(0.5);
          continue;
        }
        if (trimmed.startsWith('### ')) {
          doc.moveDown(0.5);
          doc
            .fontSize(14)
            .text(shapeForPdf(trimmed.slice(4), draft.lang), { align });
          doc.fontSize(12);
          doc.moveDown(0.3);
          continue;
        }
        for (const line of trimmed.split('\n')) {
          doc.text(shapeForPdf(line || ' ', draft.lang), { align });
        }
        doc.moveDown(0.5);
      }

      // Footer stamp on every page.
      const range = doc.bufferedPageRange();
      for (let i = range.start; i < range.start + range.count; i++) {
        doc.switchToPage(i);
        const stamp = shapeForPdf(FOOTER_STAMP, draft.lang);
        doc
          .fontSize(9)
          .fillColor('#6B7280')
          .text(stamp, 0, doc.page.height - 40, {
            width: doc.page.width,
            align: 'center',
          });
      }

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

module.exports = {
  FOOTER_STAMP,
  HEBREW_FONT_NAME,
  HAS_HEBREW_FONT,
  TEMPLATES,
  createDraft,
  toDocxBuffer,
  toPdfBuffer,
};
