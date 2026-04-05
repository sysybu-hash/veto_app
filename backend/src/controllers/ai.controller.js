// ============================================================
//  ai.controller.js — AI Legal Chat Endpoint
//  VETO Legal Emergency App
// ============================================================

const { geminiChat } = require('../services/gemini.service');
const Lawyer = require('../models/Lawyer');

// Hebrew specialization → English DB values mapping
const SPEC_MAP = {
  'פלילי':   ['criminal', 'Criminal', 'פלילי'],
  'משפחה':   ['family', 'Family', 'משפחה'],
  'נדל"ן':   ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל"ן', 'נדלן'],
  'עבודה':   ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
  'מסחרי':   ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
  'תעבורה':  ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
};

/**
 * POST /api/ai/chat
 * Body: { message: string, history: [{role, parts: [{text}]}] }
 */
exports.aiChat = async (req, res) => {
  try {
    const { message, history } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ error: 'message is required' });
    }

    if (!process.env.GEMINI_API_KEY) {
      return res.status(503).json({ error: 'AI service not configured' });
    }

    const rawReply = await geminiChat(history || [], message.trim());

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
    console.error('AI chat error:', err);
    return res.status(500).json({ error: 'AI service unavailable' });
  }
};
