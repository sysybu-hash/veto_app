// ============================================================
//  ai.controller.js — AI Legal Chat Endpoint
//  VETO Legal Emergency App
// ============================================================

const { geminiChat, isTransientGeminiFailure } = require('../services/gemini.service');
const Lawyer = require('../models/Lawyer');

// Hebrew / Arabic / English specialization → DB terms mapping
const SPEC_MAP = {
  // Hebrew
  'פלילי':   ['criminal', 'Criminal', 'פלילי', 'جنائي'],
  'משפחה':   ['family', 'Family', 'משפחה', 'عائلة'],
  'נדל"ן':   ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל"ן', 'נדלן', 'عقارات'],
  'עבודה':   ['labor', 'Labor', 'employment', 'Employment', 'עבודה', 'عمل'],
  'מסחרי':   ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי', 'تجاري'],
  'תעבורה':  ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה', 'مرور'],
  // Arabic (Gemini may return these)
  'جنائي':   ['criminal', 'Criminal', 'פלילי', 'جنائي'],
  'عائلة':   ['family', 'Family', 'משפחה', 'عائلة'],
  'عقارات':  ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל"ן', 'נדלן', 'عقارات'],
  'عمل':     ['labor', 'Labor', 'employment', 'Employment', 'עבודה', 'عمل'],
  'تجاري':   ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי', 'تجاري'],
  'مرور':    ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה', 'مرور'],
  // English
  'criminal':    ['criminal', 'Criminal', 'פלילי'],
  'family':      ['family', 'Family', 'משפחה'],
  'real estate': ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל"ן'],
  'labor':       ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
  'commercial':  ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
  'traffic':     ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
};

const AI_FALLBACK_REPLIES = {
  he: 'תאר לי את הבעיה המשפטית שלך — במה אני יכול לעזור?',
  ar: 'صف لي مشكلتك القانونية — كيف يمكنني مساعدتك؟',
  en: 'Describe your legal issue — how can I help you?',
  ru: 'Опишите вашу юридическую проблему — чем я могу помочь?',
};

/**
 * POST /api/ai/chat
 * Body: { message: string, history: [{role, parts: [{text}]}] }
 */
exports.aiChat = async (req, res) => {
  try {
    const { message, history, lang } = req.body;
    // Must match AppLanguage (he / en / ru) + optional Arabic UI.
    const safeLang = ['he', 'ar', 'en', 'ru'].includes(lang) ? lang : 'he';

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ error: 'message is required' });
    }

    if (!process.env.GEMINI_API_KEY) {
      return res.status(503).json({ error: 'AI service not configured' });
    }

    const rawReply = await geminiChat(history || [], message.trim(), safeLang);

    // Parse JSON from Gemini response
    let parsed;
    try {
      const jsonMatch = rawReply.match(/\{[\s\S]*?\}/);
      parsed = JSON.parse(jsonMatch ? jsonMatch[0] : rawReply);
    } catch {
      // Non-JSON reply — return as unclassified
      return res.json({ classified: false, reply: rawReply });
    }

    if (!parsed.classified) {
      return res.json({ classified: false, reply: parsed.reply || rawReply });
    }

    // Classified — find matching available lawyer
    const specHe = parsed.specialization;
    const terms  = SPEC_MAP[specHe] || [specHe];
    const regexTerms = terms.map((t) => new RegExp(`^${t}$`, 'i'));

    const lawyer = await Lawyer.findOne({
      is_online:    true,
      is_available: true,
      is_active:    true,
      specializations: { $in: regexTerms },
    }).select('_id full_name phone');

    return res.json({
      classified:    true,
      specialization: specHe,
      reply:         parsed.reply,
      lawyer: lawyer
        ? { id: lawyer._id, name: lawyer.full_name, phone: lawyer.phone }
        : null,
    });
  } catch (err) {
    console.error('AI chat error:', err.message);
    const lang =
      req.body?.lang && ['he', 'ar', 'en', 'ru'].includes(req.body.lang)
        ? req.body.lang
        : 'he';
    // Rate limits, 503 UNAVAILABLE, model overload — graceful reply (never leak raw API JSON).
    if (isTransientGeminiFailure(err)) {
      return res.json({
        classified: false,
        reply: AI_FALLBACK_REPLIES[lang] || AI_FALLBACK_REPLIES.he,
      });
    }
    return res.status(500).json({ error: 'AI service unavailable' });
  }
};
