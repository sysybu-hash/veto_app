const {
  createDraft,
  toDocxBuffer,
  toPdfBuffer,
} = require('../services/legalDocumentEngine.service');

exports.generateDraft = async (req, res) => {
  try {
    const draft = createDraft(req.body || {}, req.user || {});
    return res.json({
      ok: true,
      draft,
    });
  } catch (err) {
    console.error('generateDraft error:', err);
    return res.status(500).json({ error: 'Failed to generate draft' });
  }
};

exports.exportDraft = async (req, res) => {
  try {
    const format = String(req.body?.format || 'pdf').toLowerCase();
    const draft = createDraft(req.body || {}, req.user || {});
    const safeName = `${(draft.title || 'veto-legal-document')
      .replace(/[^\w\-א-ת]+/g, '_')
      .slice(0, 80)}`;

    if (format === 'docx') {
      const docx = await toDocxBuffer(draft);
      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      res.setHeader('Content-Disposition', `attachment; filename="${safeName}.docx"`);
      return res.send(docx);
    }

    const pdf = await toPdfBuffer(draft);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${safeName}.pdf"`);
    return res.send(pdf);
  } catch (err) {
    console.error('exportDraft error:', err);
    return res.status(500).json({ error: 'Failed to export document' });
  }
};

