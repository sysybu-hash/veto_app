// ============================================================
//  documentRender.controller.js — POST /api/documents/render
//  Server-side PDF/DOCX export for the structured legal-document
//  generator (web-client/src/app/vault/generator). Replaces the
//  client-side html2canvas+jsPDF rasterization path.
// ============================================================

const { renderPdf, toDocxBuffer } = require('../services/documentRender');
const logger = require('../lib/logger');

const ALLOWED_STRING_FIELDS = ['title', 'preamble'];
const ALLOWED_ARRAY_FIELDS = ['parties', 'definitions', 'clauses', 'attachments', 'completionChecklist', 'legalNotes'];

function sanitizeDocument(body) {
  const doc = { title: '', preamble: '', signatures: [] };
  for (const key of ALLOWED_STRING_FIELDS) {
    doc[key] = typeof body?.[key] === 'string' ? body[key].slice(0, 20000) : '';
  }
  for (const key of ALLOWED_ARRAY_FIELDS) {
    doc[key] = Array.isArray(body?.[key])
      ? body[key].filter((x) => typeof x === 'string').slice(0, 200).map((x) => x.slice(0, 4000))
      : [];
  }
  doc.signatures = Array.isArray(body?.signatures)
    ? body.signatures
        .filter((s) => s && typeof s === 'object')
        .slice(0, 20)
        .map((s) => ({
          role: typeof s.role === 'string' ? s.role.slice(0, 200) : '',
          name: typeof s.name === 'string' ? s.name.slice(0, 200) : '',
        }))
    : [];
  return doc;
}

function safeFilename(title) {
  return (title || 'veto-legal-document').replace(/[^\w\-א-ת]+/g, '_').slice(0, 80) || 'veto-legal-document';
}

exports.renderDocument = async (req, res) => {
  try {
    const format = String(req.body?.format || 'pdf').toLowerCase();
    const lang = ['he', 'en', 'ru'].includes(req.body?.lang) ? req.body.lang : 'he';
    const doc = sanitizeDocument(req.body?.document || {});
    if (!doc.title && !doc.clauses.length) {
      return res.status(400).json({ error: 'Empty document' });
    }
    const safeName = safeFilename(doc.title);

    if (format === 'docx') {
      const buf = await toDocxBuffer(doc, { lang });
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      res.setHeader('Content-Disposition', `attachment; filename="${safeName}.docx"`);
      return res.send(buf);
    }

    const buf = await renderPdf(doc, { lang });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${safeName}.pdf"`);
    return res.send(buf);
  } catch (err) {
    logger.error({ err }, 'documentRender.renderDocument error');
    return res.status(500).json({ error: 'Failed to render document' });
  }
};
