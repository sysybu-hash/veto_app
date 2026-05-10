// ============================================================
//  document.controller.js — Gemini JSON docs + signatures (M10–11)
// ============================================================

const crypto = require('crypto');
const mongoose = require('mongoose');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Document = require('../models/Document');

const DOCUMENT_MODEL =
  process.env.GEMINI_DOCUMENT_MODEL?.trim() || 'gemini-1.5-pro';

function jwtUserId(req) {
  const id = req.user?.userId ?? req.user?.id;
  return id != null ? String(id).trim() : '';
}

function signatureRoleFromJwt(role) {
  if (role === 'lawyer') return 'lawyer';
  return 'citizen';
}

function stripJsonFences(text) {
  return String(text || '')
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```\s*$/i, '')
    .trim();
}

function parseModelJson(text) {
  const cleaned = stripJsonFences(text);
  const data = JSON.parse(cleaned);
  if (!data || typeof data.title !== 'string') {
    throw new Error('Invalid document JSON: missing title');
  }
  if (!Array.isArray(data.sections)) {
    throw new Error('Invalid document JSON: sections must be an array');
  }
  data.sections = data.sections.map((s) => ({
    heading: typeof s?.heading === 'string' ? s.heading : '',
    content: typeof s?.content === 'string' ? s.content : '',
  }));
  data.footer = typeof data.footer === 'string' ? data.footer : '';
  return data;
}

exports.generateDocument = async (req, res) => {
  try {
    const apiKey = (process.env.GEMINI_API_KEY || '').trim();
    if (!apiKey) {
      return res.status(503).json({ error: 'GEMINI_API_KEY is not configured.' });
    }

    const userId = jwtUserId(req);
    if (!userId || !mongoose.isValidObjectId(userId)) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    const { prompt, currentContent, editInstruction } = req.body || {};
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: DOCUMENT_MODEL });

    const systemPrompt = `You are a Senior Israeli Civil Attorney. Output ONLY a valid JSON object with: "title" (string), "sections" (array of objects with "heading" and "content" strings), and "footer" (string). Use formal Hebrew legal language. No markdown, no commentary — JSON only.`;

    const userPrompt = editInstruction
      ? `Current JSON: ${JSON.stringify(currentContent?.payload ?? currentContent ?? {})}. Instruction: ${editInstruction}. Return updated full JSON.`
      : `Draft a full legal document for: ${prompt || '(no topic)'}.`;

    const result = await model.generateContent(`${systemPrompt}\n\n${userPrompt}`);
    const text = result.response.text();
    const docData = parseModelJson(text);

    let savedDoc;
    const existingId = currentContent?._id || currentContent?.id;
    if (!existingId) {
      savedDoc = await Document.create({
        creator: userId,
        title: docData.title,
        sections: docData.sections,
        footer: docData.footer,
        status: 'draft',
      });
    } else {
      if (!mongoose.isValidObjectId(String(existingId))) {
        return res.status(400).json({ error: 'Invalid document id.' });
      }
      const existing = await Document.findById(existingId);
      if (!existing) return res.status(404).json({ error: 'Document not found.' });
      if (String(existing.creator) !== userId) {
        return res.status(403).json({ error: 'Forbidden.' });
      }
      savedDoc = await Document.findByIdAndUpdate(
        existingId,
        {
          title: docData.title,
          sections: docData.sections,
          footer: docData.footer,
        },
        { new: true, runValidators: true },
      );
    }

    return res.status(200).json(savedDoc);
  } catch (error) {
    console.error('Document Gen Error:', error);
    return res.status(500).json({ error: 'Failed to generate document' });
  }
};

exports.signDocument = async (req, res) => {
  try {
    const userId = jwtUserId(req);
    if (!userId || !mongoose.isValidObjectId(userId)) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    const { docId } = req.params;
    if (!mongoose.isValidObjectId(docId)) {
      return res.status(400).json({ error: 'Invalid document id.' });
    }

    const doc = await Document.findById(docId);
    if (!doc) return res.status(404).json({ error: 'Document not found.' });

    const jwtRole = req.user?.role;
    const sigRole = signatureRoleFromJwt(jwtRole);

    const already = (doc.signatures || []).some(
      (s) => String(s.userId) === userId,
    );
    if (already) {
      return res.status(409).json({ error: 'Already signed by this account.' });
    }

    const isCreator = String(doc.creator) === userId;
    if (sigRole === 'citizen' && !isCreator) {
      return res.status(403).json({ error: 'Only the document creator may sign as citizen.' });
    }
    if (sigRole === 'lawyer' && doc.status !== 'pending_lawyer') {
      return res.status(403).json({
        error: 'Lawyer signature is only allowed when status is pending_lawyer.',
      });
    }

    const payload = `${docId}-${userId}-${Date.now()}`;
    const signatureHash = crypto.createHash('sha256').update(payload).digest('hex');

    const signature = {
      userId,
      role: sigRole,
      signatureHash,
      signedAt: new Date(),
    };

    const nextStatus =
      sigRole === 'lawyer' && doc.status === 'pending_lawyer' ? 'signed' : doc.status;

    const updated = await Document.findByIdAndUpdate(
      docId,
      { $push: { signatures: signature }, $set: { status: nextStatus } },
      { new: true },
    );

    return res.status(200).json({ status: 'success', signature, document: updated });
  } catch (error) {
    console.error('signDocument:', error);
    return res.status(500).json({ error: 'Failed to sign document' });
  }
};

exports.requestLawyerSignature = async (req, res) => {
  try {
    const userId = jwtUserId(req);
    if (!userId || !mongoose.isValidObjectId(userId)) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    const { docId } = req.params;
    if (!mongoose.isValidObjectId(docId)) {
      return res.status(400).json({ error: 'Invalid document id.' });
    }

    const doc = await Document.findById(docId);
    if (!doc) return res.status(404).json({ error: 'Document not found.' });
    if (String(doc.creator) !== userId) {
      return res.status(403).json({ error: 'Forbidden.' });
    }

    await Document.findByIdAndUpdate(docId, { status: 'pending_lawyer' });

    // Mission 7+: pushService.notifyLawyers({ title: "בקשת חתימה", body: "..." });

    return res.status(200).json({
      status: 'success',
      message: 'Lawyer requested successfully',
    });
  } catch (error) {
    console.error('requestLawyerSignature:', error);
    return res.status(500).json({ error: 'Failed to request lawyer' });
  }
};
