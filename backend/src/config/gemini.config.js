// ============================================================
//  gemini.config.js — single source of truth for model IDs
//  Docs: https://ai.google.dev/gemini-api/docs/models
// ============================================================

/**
 * Default: Gemini 2.5 Flash — lower latency and higher availability than Pro preview.
 * Override with env `GEMINI_MODEL` (e.g. `gemini-3.1-pro-preview` for max quality when load allows).
 */
const DEFAULT_GEMINI_MODEL = 'gemini-2.5-flash';

function getGeminiModelId() {
  const fromEnv = (process.env.GEMINI_MODEL || '').trim();
  return fromEnv.length > 0 ? fromEnv : DEFAULT_GEMINI_MODEL;
}

module.exports = {
  getGeminiModelId,
  DEFAULT_GEMINI_MODEL,
};
