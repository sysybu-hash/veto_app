// ============================================================
//  gemini.config.js — single source of truth for model IDs
//  Docs: https://ai.google.dev/gemini-api/docs/models
// ============================================================

/**
 * Default: Gemini 2.5 Flash — lower latency and higher availability than Pro preview.
 * Override with env `GEMINI_MODEL` (e.g. `gemini-3.1-pro-preview` for max quality when load allows).
 */
const DEFAULT_GEMINI_MODEL = 'gemini-2.5-flash';

/** Multimodal Live — native voice (AUDIO out). Override with `GEMINI_LIVE_MODEL`. */
const DEFAULT_GEMINI_LIVE_MODEL = 'gemini-live-2.5-flash-native-audio';

function getGeminiModelId() {
  const fromEnv = (process.env.GEMINI_MODEL || '').trim();
  return fromEnv.length > 0 ? fromEnv : DEFAULT_GEMINI_MODEL;
}

function getGeminiLiveModelId() {
  const fromEnv = (process.env.GEMINI_LIVE_MODEL || '').trim();
  return fromEnv.length > 0 ? fromEnv : DEFAULT_GEMINI_LIVE_MODEL;
}

module.exports = {
  getGeminiModelId,
  getGeminiLiveModelId,
  DEFAULT_GEMINI_MODEL,
  DEFAULT_GEMINI_LIVE_MODEL,
};
