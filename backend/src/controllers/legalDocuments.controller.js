// ============================================================
//  legalDocuments.controller.js — generate / export legal docs
//  - generate: returns templated draft + optional AI-augmented body
//  - export:   returns PDF or DOCX with Hebrew RTL + footer stamp
// ============================================================

const {
  createDraft,
  toDocxBuffer,
  toPdfBuffer,
  TEMPLATES,
} = require('../services/legalDocumentEngine.service');
const { geminiChat, isTransientGeminiFailure, hasGeminiApiKey } = require('../services/gemini.service');
const logger = require('../lib/logger');

async function maybeAugmentWithAi(payload) {
  // Only enrich body if Gemini is configured (API key or Vertex AI) AND user provided no body.
  if (!hasGeminiApiKey()) return null;
  if (payload.body && payload.body.trim().length) return null;
  if (!payload.intent && !payload.domain) return null;

  const lang = ['he', 'en', 'ru'].includes(payload.lang) ? payload.lang : 'he';
  const factsText = Array.isArray(payload.facts)
    ? payload.facts.filter(Boolean).join('\n- ')
    : '';
  const tplKey = String(payload.intent || '').trim();
  const tpl = TEMPLATES[tplKey];
  const tplHint = tpl
    ? `מבנה התבנית כולל: ${tpl.sections.map((s) => s.h).join(' / ')}.`
    : '';
  const ask =
    `נסח/י טיוטה משפטית בעברית מקצועית עבור ${payload.intent || 'מסמך'} בתחום ${payload.domain || 'כללי'}.\n` +
    (tplHint ? `${tplHint}\n` : '') +
    (factsText ? `עובדות: \n- ${factsText}\n` : '') +
    'הקפד/י על מבנה ברור, סעיפי משנה, ודיוק משפטי. החזר רק את גוף המסמך, ללא קוד וללא JSON.';
  try {
    const reply = await geminiChat([], ask, lang);
    if (typeof reply === 'string' && reply.trim().length > 0) {
      return reply.trim();
    }
  } catch (err) {
    if (isTransientGeminiFailure(err)) return null;
    logger.error({ err }, 'Gemini augment failed');
  }
  return null;
}

exports.generateDraft = async (req, res) => {
  try {
    const aiBody = await maybeAugmentWithAi(req.body || {});
    const payload = aiBody ? { ...(req.body || {}), body: aiBody } : (req.body || {});
    const draft = createDraft(payload, req.user || {});
    return res.json({ ok: true, draft, aiAugmented: !!aiBody });
  } catch (err) {
    logger.error({ err }, 'generateDraft error');
    return res.status(500).json({ error: 'Failed to generate draft' });
  }
};

exports.exportDraft = async (req, res) => {
  try {
    const format = String(req.body?.format || 'pdf').toLowerCase();
    const aiBody = await maybeAugmentWithAi(req.body || {});
    const payload = aiBody ? { ...(req.body || {}), body: aiBody } : (req.body || {});
    const draft = createDraft(payload, req.user || {});
    const safeName = `${(draft.title || 'veto-legal-document')
      .replace(/[^\w\-א-ת]+/g, '_')
      .slice(0, 80)}`;

    if (format === 'docx') {
      const docx = await toDocxBuffer(draft);
      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="${safeName}.docx"`,
      );
      return res.send(docx);
    }

    const pdf = await toPdfBuffer(draft);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${safeName}.pdf"`,
    );
    return res.send(pdf);
  } catch (err) {
    logger.error({ err }, 'exportDraft error');
    return res.status(500).json({ error: 'Failed to export document' });
  }
};

exports.listTemplates = (_req, res) => {
  res.json({
    ok: true,
    templates: Object.entries(TEMPLATES).map(([id, tpl]) => ({
      id,
      title: tpl.title,
      sections: tpl.sections.map((s) => s.h),
    })),
  });
};
