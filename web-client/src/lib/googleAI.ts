// ============================================================
//  googleAI.ts — shared @google/genai client for Next.js API routes,
//  Vertex-AI-aware (mirrors backend/src/config/googleAI.client.js).
//
//  The public Gemini Developer API (generativelanguage.googleapis.com)
//  is a separate credential surface from Vertex AI and can fail
//  independently (invalid/rotated key, regional block, etc). Vertex AI
//  (the same models, served via Google Cloud) uses a service account
//  instead, so we switch to it whenever a GCP project is configured and
//  fall back to the plain API key otherwise (e.g. local dev).
//
//  Vertex mode env vars (set in Vercel Project Settings):
//    GOOGLE_CLOUD_PROJECT                — GCP project id
//    GOOGLE_CLOUD_LOCATION                — Vertex region, e.g. "us-central1"
//    GOOGLE_APPLICATION_CREDENTIALS_JSON  — service-account key, as JSON text
// ============================================================

import fs from "fs";
import os from "os";
import path from "path";
import { GoogleGenAI } from "@google/genai";

export function isVertexConfigured(): boolean {
  return Boolean((process.env.GOOGLE_CLOUD_PROJECT || "").trim());
}

export function isGoogleAIConfigured(): boolean {
  return isVertexConfigured() || Boolean((process.env.GEMINI_API_KEY || "").trim());
}

/**
 * Materializes GOOGLE_APPLICATION_CREDENTIALS_JSON into a real file and
 * points GOOGLE_APPLICATION_CREDENTIALS at it, so google-auth-library's
 * normal ADC lookup finds it. No-op if already set some other way.
 */
function bootstrapGoogleCredentials(): void {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) return;
  const json = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
  if (!json) return;
  try {
    const filePath = path.join(os.tmpdir(), "veto-gcp-sa-key.json");
    fs.writeFileSync(filePath, json, { mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = filePath;
  } catch (err) {
    console.error("[googleAI] failed to write GOOGLE_APPLICATION_CREDENTIALS_JSON to disk:", err);
  }
}

let _client: GoogleGenAI | null = null;
export function getGoogleAIClient(): GoogleGenAI {
  if (_client) return _client;
  if (isVertexConfigured()) {
    bootstrapGoogleCredentials();
    _client = new GoogleGenAI({
      vertexai: true,
      project: process.env.GOOGLE_CLOUD_PROJECT,
      location: (process.env.GOOGLE_CLOUD_LOCATION || "us-central1").trim(),
    });
  } else {
    _client = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _client;
}
