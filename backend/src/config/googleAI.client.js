// ============================================================
//  googleAI.client.js — shared @google/genai client, Vertex-AI-aware.
//
//  The public Gemini Developer API (generativelanguage.googleapis.com)
//  blocks requests from some hosting regions ("User location is not
//  supported for the API use") — this hit us running on Render/Frankfurt.
//  Vertex AI (the same models, served via Google Cloud) is not subject to
//  that consumer-API geo-block, so we switch to it whenever a GCP project
//  is configured and fall back to the plain API key otherwise (e.g. local
//  dev from a supported location).
//
//  Vertex mode env vars:
//    GOOGLE_CLOUD_PROJECT              — GCP project id
//    GOOGLE_CLOUD_LOCATION             — Vertex region, e.g. "us-central1"
//    GOOGLE_APPLICATION_CREDENTIALS_JSON — service-account key, as JSON text
//        (bootstrapGoogleCredentials() below writes it to a temp file and
//        points GOOGLE_APPLICATION_CREDENTIALS at it, which is what
//        google-auth-library reads for Application Default Credentials)
// ============================================================

const fs = require('fs');
const os = require('os');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');

function isVertexConfigured() {
  return Boolean((process.env.GOOGLE_CLOUD_PROJECT || '').trim());
}

function isGoogleAIConfigured() {
  return isVertexConfigured() || Boolean((process.env.GEMINI_API_KEY || '').trim());
}

/**
 * Materializes GOOGLE_APPLICATION_CREDENTIALS_JSON (a service-account key,
 * pasted as one env var) into a real file and points
 * GOOGLE_APPLICATION_CREDENTIALS at it, so google-auth-library's normal
 * ADC lookup finds it. No-op if already set some other way. Call once at
 * boot, before anything touches Gemini.
 */
function bootstrapGoogleCredentials() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) return;
  const json = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (!json) return;
  try {
    const filePath = path.join(os.tmpdir(), 'veto-gcp-sa-key.json');
    fs.writeFileSync(filePath, json, { mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = filePath;
  } catch (err) {
    console.error('[googleAI] failed to write GOOGLE_APPLICATION_CREDENTIALS_JSON to disk:', err);
  }
}

let _client;
function getGoogleAIClient() {
  if (_client) return _client;
  if (isVertexConfigured()) {
    _client = new GoogleGenAI({
      vertexai: true,
      project: process.env.GOOGLE_CLOUD_PROJECT,
      location: (process.env.GOOGLE_CLOUD_LOCATION || 'us-central1').trim(),
    });
  } else {
    _client = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _client;
}

module.exports = {
  getGoogleAIClient,
  isGoogleAIConfigured,
  isVertexConfigured,
  bootstrapGoogleCredentials,
};
