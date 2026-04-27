// ============================================================
//  notebooklm.service.js — NotebookLM Enterprise (Discovery) prep
//  No consumer NotebookLM “site” API — Enterprise uses Google Cloud
//  IAM + optional Discovery/Agentspace. Code paths are env-guarded.
//
//  Env (when available):
//    GOOGLE_NOTEBOOKLM_SA_JSON — service account JSON string (same as FIREBASE pattern)
//    GCP_PROJECT_ID or GOOGLE_CLOUD_PROJECT
//    NOTEBOOKLM_LOCATION — e.g. us, eu, global
// ============================================================

const { GoogleAuth } = require('google-auth-library');

function isEnterpriseConfigured() {
  const p = (process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || '').trim();
  const raw = (process.env.GOOGLE_NOTEBOOKLM_SA_JSON || process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON || '').trim();
  return p.length > 0 && raw.startsWith('{');
}

let _auth;
function getClientAuth() {
  if (_auth) return _auth;
  const raw = process.env.GOOGLE_NOTEBOOKLM_SA_JSON || process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (!raw || !String(raw).trim().startsWith('{')) return null;
  const projectId = process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
  _auth = new GoogleAuth({
    credentials: JSON.parse(String(raw)),
    projectId: projectId || undefined,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  return _auth;
}

/**
 * Reserved for Discovery Engine / NotebookLM Enterprise REST.
 * The exact resource path depends on the licensed product (Agentspace, etc.).
 * Returns metadata when fully configured, otherwise a clear error object.
 */
async function probeEnterpriseApi() {
  if (!isEnterpriseConfigured()) {
    return { ok: false, reason: 'Set GCP_PROJECT_ID and GOOGLE_NOTEBOOKLM_SA_JSON in environment.' };
  }
  const auth = getClientAuth();
  if (!auth) return { ok: false, reason: 'Service account not parseable' };
  try {
    const client = await auth.getClient();
    const t = await client.getAccessToken();
    if (!t || !t.token) return { ok: false, reason: 'No access token' };
    return { ok: true, tokenLength: t.token.length };
  } catch (e) {
    return { ok: false, reason: e.message || String(e) };
  }
}

/**
 * Build a “open in Google” link — replace with your team’s real deep link if documented.
 * @param {string} externalId — optional id returned by API
 */
function openNotebookUrl({ externalId } = {}) {
  const base = (process.env.NOTEBOOKLM_ENT_URL || 'https://notebooklm.cloud.google.com').replace(/\/$/, '');
  if (externalId) {
    return `${base}/?notebook=${encodeURIComponent(externalId)}`;
  }
  return base;
}

/**
 * Placeholder for "sync vault files as sources" — would call the Enterprise ingestion API
 * for your licensed NotebookLM project once the exact method name is set.
 */
async function syncVaultToNotebook() {
  const probe = await probeEnterpriseApi();
  if (!probe.ok) {
    return { ok: false, error: probe.reason, hint: 'Configure Google Cloud + NotebookLM Enterprise; then wire REST in this function.' };
  }
  return {
    ok: true,
    message: 'API reachability OK. Implement document ingestion in a follow-up (your GCP resource ids).',
  };
}

module.exports = {
  isEnterpriseConfigured,
  getClientAuth,
  probeEnterpriseApi,
  openNotebookUrl,
  syncVaultToNotebook,
};
