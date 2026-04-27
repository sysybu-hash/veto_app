// ============================================================
//  geminiLegal.service.js — vault document legal analysis (Gemini)
//  Env: GEMINI_API_KEY, optional VAULT_ANALYSIS_MAX_BYTES (default 20MB)
// ============================================================

const axios = require('axios');
const { GoogleGenAI } = require('@google/genai');
const { getGeminiModelId } = require('../config/gemini.config');
const { isTransientGeminiFailure, isApiErrorPayloadText } = require('./gemini.service');

const MAX_DEFAULT = 20 * 1024 * 1024;

const LEGAL_SYSTEM = `You are a legal document analyst for the VETO app. The user is in Israel or general international context. You do NOT provide binding legal advice; you summarize and flag issues for a human lawyer.
Respond with valid JSON only, no markdown fences, in this exact shape:
{
  "summary": "string (2-5 sentences, Hebrew if the document is Hebrew, else match document language)",
  "keyPoints": ["string"],
  "parties": ["string"],
  "jurisdictionNotes": "string",
  "riskFlags": ["string"]
}`;

let _ai;
function getAI() {
  if (!_ai) {
    if (!process.env.GEMINI_API_KEY) return null;
    _ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _ai;
}

function maxBytes() {
  const n = parseInt(String(process.env.VAULT_ANALYSIS_MAX_BYTES || ''), 10);
  return Number.isFinite(n) && n > 0 ? n : MAX_DEFAULT;
}

const TEXT_MIMES = new Set([
  'text/plain',
  'text/csv',
  'text/html',
  'text/markdown',
  'application/json',
]);

const INLINE_MIMES = new Set([
  'application/pdf',
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/msword',
]);

/**
 * @param {{ name: string, mimeType: string, url: string }} file
 * @returns {Promise<{ summary: string, legalAnalysis: object|null, error?: string }>}
 */
async function analyzeVaultFile(file) {
  if (!getAI()) {
    return { summary: '', legalAnalysis: null, error: 'GEMINI_API_KEY is not set.' };
  }

  const cap = maxBytes();
  const res = await axios.get(file.url, {
    responseType: 'arraybuffer',
    maxContentLength: cap,
    maxBodyLength: cap,
    timeout: 120000,
    validateStatus: (s) => s === 200,
  });
  const buf = Buffer.from(res.data);
  if (buf.length > cap) {
    return { summary: '', legalAnalysis: null, error: `File exceeds analysis size limit (${cap} bytes).` };
  }

  const mt = (file.mimeType || 'application/octet-stream').split(';')[0].trim().toLowerCase();
  const ai = getAI();
  const model = getGeminiModelId();
  const parts = [];

  if (TEXT_MIMES.has(mt) || mt.startsWith('text/')) {
    const text = buf.toString('utf8');
    if (text.length > 200000) {
      parts.push({ text: text.slice(0, 200000) + '\n\n[...truncated for analysis...]' });
    } else {
      parts.push({ text });
    }
  } else if (INLINE_MIMES.has(mt) || mt.startsWith('image/')) {
    const b64 = buf.toString('base64');
    parts.push({
      inlineData: { mimeType: mt || 'application/octet-stream', data: b64 },
    });
  } else {
    return {
      summary: '',
      legalAnalysis: null,
      error: `Analysis for MIME type "${mt}" is not supported. Try PDF, image, or plain text.`,
    };
  }

  const userHint = `File name: ${file.name || 'document'}\nMime: ${mt}\nAnalyze the following document content.`;
  const contents = [
    {
      role: 'user',
      parts: [{ text: userHint }, ...parts],
    },
  ];

  const MAX_ATT = 4;
  for (let attempt = 0; attempt < MAX_ATT; attempt++) {
    try {
      const response = await ai.models.generateContent({
        model,
        contents,
        config: { systemInstruction: LEGAL_SYSTEM },
      });
      const text =
        typeof response.text === 'string'
          ? response.text
          : response.text != null
            ? String(response.text)
            : '';
      if (isApiErrorPayloadText(text)) {
        throw new Error(text);
      }
      let legalAnalysis;
      try {
        legalAnalysis = JSON.parse(text);
      } catch {
        legalAnalysis = { raw: text, parseError: true };
      }
      const summary = typeof legalAnalysis?.summary === 'string' ? legalAnalysis.summary : text.slice(0, 2000);
      return { summary, legalAnalysis };
    } catch (err) {
      if (isTransientGeminiFailure(err) && attempt < MAX_ATT - 1) {
        await new Promise((r) => setTimeout(r, 1500 * (attempt + 1)));
        continue;
      }
      return {
        summary: '',
        legalAnalysis: null,
        error: err?.message || String(err),
      };
    }
  }
  return { summary: '', legalAnalysis: null, error: 'Analysis failed after retries.' };
}

module.exports = { analyzeVaultFile, LEGAL_SYSTEM };
