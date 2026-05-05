// ============================================================
//  Legal notebook — Gemini Q&A over local markdown + sources
//  Architecture: VETO local notebook (not consumer NotebookLM API).
// ============================================================

const { GoogleGenAI } = require('@google/genai');
const { getGeminiModelId } = require('../config/gemini.config');
const { isTransientGeminiFailure, isApiErrorPayloadText } = require('./gemini.service');

const MAX_CONTEXT_CHARS = 100_000;

const SYSTEM = `You are a research assistant for the VETO legal notebook. Answer using the notebook CONTEXT below (user notes and sources). If the answer is not supported by the context, say briefly that it is not in the materials. You do not provide binding legal advice. Be concise; match the user's language when possible (Hebrew/Russian/English).`;

let _ai;
function getAI() {
  if (!_ai) {
    if (!process.env.GEMINI_API_KEY) return null;
    _ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _ai;
}

/**
 * @param {string} context
 * @param {{ role: string, text: string }[]} history last N turns
 * @param {string} userMessage
 * @returns {Promise<{ text: string, error?: string }>}
 */
async function generateNotebookReply(context, history, userMessage) {
  const ai = getAI();
  if (!ai) {
    return { text: '', error: 'GEMINI_API_KEY is not set.' };
  }
  const ctx = String(context || '').slice(0, MAX_CONTEXT_CHARS);
  const model = getGeminiModelId();

  const contents = [
    ...(history || []).slice(-20).map((h) => ({
      role: h.role === 'model' ? 'model' : 'user',
      parts: [{ text: String(h.text || '').slice(0, 8000) }],
    })),
    { role: 'user', parts: [{ text: String(userMessage || '').slice(0, 8000) }] },
  ];

  const MAX_ATT = 4;
  for (let attempt = 0; attempt < MAX_ATT; attempt++) {
    try {
      const response = await ai.models.generateContent({
        model,
        contents,
        config: {
          systemInstruction: `${SYSTEM}\n\n--- CONTEXT ---\n${ctx}`,
        },
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
      return { text: text.trim() || '(empty model response)' };
    } catch (err) {
      if (attempt < MAX_ATT - 1 && isTransientGeminiFailure(err)) {
        await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
        continue;
      }
      return { text: '', error: err.message || 'Gemini request failed' };
    }
  }
  return { text: '', error: 'Gemini request failed' };
}

module.exports = { generateNotebookReply, MAX_CONTEXT_CHARS };
