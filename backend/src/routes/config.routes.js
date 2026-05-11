// ============================================================
//  config.routes.js — public app-config endpoints
//  VETO Legal Emergency App
//
//  These endpoints are intentionally PUBLIC (no JWT) — they ship
//  metadata the web/mobile clients need to render the SOS picker
//  before the user signs in (so we don't bake a stale list into
//  the bundle).
// ============================================================

const express = require('express');
const router = express.Router();
const { SPECIALIZATIONS } = require('../config/specializations');

// GET /api/config/specializations
//   → [{ id, label: { he, en, ru, ar } }, ...]
router.get('/specializations', (_req, res) => {
  // Don't ship matchTerms — those are server-side matching internals.
  const payload = SPECIALIZATIONS.map(({ id, label }) => ({ id, label }));
  res.set('Cache-Control', 'public, max-age=300, s-maxage=300');
  res.json({ ok: true, specializations: payload });
});

module.exports = router;
