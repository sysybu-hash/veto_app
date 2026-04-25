// ============================================================
//  geminiLive.controller.js — Ephemeral token for Gemini Multimodal Live
//  Browser must never receive GEMINI_API_KEY. Token is v1alpha-only.
// ============================================================

const { GoogleGenAI } = require('@google/genai');
const { getGeminiLiveModelId } = require('../config/gemini.config');
const { SYSTEM_INSTRUCTIONS } = require('../services/gemini.service');

let _v1ai;
function getV1alphaGenai() {
  if (!_v1ai) {
    if (!process.env.GEMINI_API_KEY) {
      return null;
    }
    _v1ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
      httpOptions: { apiVersion: 'v1alpha' },
    });
  }
  return _v1ai;
}

/**
 * POST /api/ai/live-token
 * Body: { lang?: 'he'|'en'|'ru'|'ar' }
 * Returns: { model, name, newSessionExpireTime, expireTime }
 * Client passes `name` to GoogleGenAI as apiKey for live.connect.
 */
exports.createLiveToken = async (req, res) => {
  if (!process.env.GEMINI_API_KEY) {
    return res.status(503).json({ error: 'AI service not configured' });
  }
  const ai = getV1alphaGenai();
  if (!ai) {
    return res.status(503).json({ error: 'AI service not configured' });
  }
  const rawLang = req.body?.lang;
  const safeLang = ['he', 'ar', 'en', 'ru'].includes(rawLang) ? rawLang : 'he';
  const systemText = SYSTEM_INSTRUCTIONS[safeLang] || SYSTEM_INSTRUCTIONS.he;
  const model = getGeminiLiveModelId();

  const speechLang =
    safeLang === 'he'
      ? 'he-IL'
      : safeLang === 'ru'
        ? 'ru-RU'
        : safeLang === 'ar'
          ? 'ar-SA'
          : 'en-US';

  const newSessionExpireTime = new Date(Date.now() + 3 * 60 * 1000).toISOString();
  const expireTime = new Date(Date.now() + 25 * 60 * 1000).toISOString();

  try {
    const token = await ai.authTokens.create({
      config: {
        httpOptions: { apiVersion: 'v1alpha' },
        uses: 1,
        newSessionExpireTime,
        expireTime,
        liveConnectConstraints: {
          model,
          config: {
            // Native Live voice — browser plays PCM; Flutter shows `outputAudioTranscription` text.
            responseModalities: ['AUDIO'],
            systemInstruction: { role: 'user', parts: [{ text: systemText }] },
            inputAudioTranscription: {},
            outputAudioTranscription: {},
            speechConfig: {
              languageCode: speechLang,
              voiceConfig: {
                prebuiltVoiceConfig: { voiceName: 'Kore' },
              },
            },
          },
        },
      },
    });
    if (!token?.name) {
      return res.status(500).json({ error: 'Failed to create live token' });
    }
    return res.json({
      model,
      name: token.name,
      newSessionExpireTime,
      expireTime,
      lang: safeLang,
    });
  } catch (err) {
    console.error('[VETO] authTokens.create (live) failed:', err?.message || err);
    return res.status(500).json({
      error: 'Failed to create live session token',
      detail: process.env.NODE_ENV !== 'production' ? String(err?.message || err) : undefined,
    });
  }
};
