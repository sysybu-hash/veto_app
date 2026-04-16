// ============================================================
//  gemini.config.js — single source of truth for model IDs
//  Docs: https://ai.google.dev/gemini-api/docs/models
// ============================================================

/**
 * Default: Gemini 3.1 Pro (preview) — highest quality model for the
 * Developer API. Override with env `GEMINI_MODEL` (e.g. `gemini-2.5-flash`
 * for stable GA only, or `gemini-3-flash-preview` for lower latency/cost).
 */
const DEFAULT_GEMINI_MODEL = 'gemini-3.1-pro-preview';

function getGeminiModelId() {
  const fromEnv = (process.env.GEMINI_MODEL || '').trim();
  return fromEnv.length > 0 ? fromEnv : DEFAULT_GEMINI_MODEL;
}

module.exports = {
  getGeminiModelId,
  DEFAULT_GEMINI_MODEL,
};
