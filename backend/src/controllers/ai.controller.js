// ============================================================
//  ai.controller.js - AI Legal Chat Endpoint
// ============================================================

const {
  geminiChat,
  hasGeminiApiKey,
  isTransientGeminiFailure,
  isApiErrorPayloadText,
} = require('../services/gemini.service');
const Lawyer = require('../models/Lawyer');

const SPEC_MAP = {
  פלילי: ['criminal', 'Criminal', 'פלילי'],
  משפחה: ['family', 'Family', 'משפחה'],
  'נדל״ן': ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל״ן', 'נדלן'],
  עבודה: ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
  מסחרי: ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
  תעבורה: ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
  criminal: ['criminal', 'Criminal', 'פלילי'],
  family: ['family', 'Family', 'משפחה'],
  'real estate': ['real estate', 'Real Estate', 'realestate', 'RealEstate', 'נדל״ן', 'נדלן'],
  labor: ['labor', 'Labor', 'employment', 'Employment', 'עבודה'],
  commercial: ['commercial', 'Commercial', 'civil', 'Civil', 'מסחרי'],
  traffic: ['traffic', 'Traffic', 'transportation', 'Transportation', 'תעבורה'],
};

const AI_FALLBACK_REPLIES = {
  he:
    'שירות ה-AI עדיין לא מחובר למפתח Gemini בסביבה הזו, אבל החלון עובד. אפשר להמשיך להשתמש בצ׳אט, לשמור הערות לכספת, לפתוח מחולל מסמכים או לנסח ידנית. בפרודקשן יש להגדיר GEMINI_API_KEY.',
  en:
    'The AI service is not connected to a Gemini key in this environment yet, but the chat window is working. You can still save notes to the vault and use site actions. Configure GEMINI_API_KEY for production AI replies.',
  ru:
    'Сервис AI пока не подключен к ключу Gemini в этой среде, но окно чата работает. Можно сохранять заметки в сейф и выполнять действия на сайте. Для production настройте GEMINI_API_KEY.',
  ar:
    'خدمة الذكاء الاصطناعي غير متصلة بمفتاح Gemini في هذه البيئة بعد، لكن نافذة الدردشة تعمل. يمكن حفظ الملاحظات في الخزنة واستخدام إجراءات الموقع. للإنتاج يجب ضبط GEMINI_API_KEY.',
};

function safeLang(lang) {
  return ['he', 'ar', 'en', 'ru'].includes(lang) ? lang : 'he';
}

function fallbackReply(lang) {
  return AI_FALLBACK_REPLIES[lang] || AI_FALLBACK_REPLIES.he;
}

function parseGeminiJson(rawReply) {
  try {
    return JSON.parse(rawReply);
  } catch (_) {
    const match = String(rawReply).match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

/**
 * POST /api/ai/chat
 * Body: { message: string, history: [{ role, parts: [{ text }] }], lang: 'he'|'en'|'ru'|'ar' }
 */
exports.aiChat = async (req, res) => {
  const lang = safeLang(req.body?.lang);

  try {
    const { message, history } = req.body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ error: 'message is required' });
    }

    if (!hasGeminiApiKey()) {
      return res.json({
        classified: false,
        configured: false,
        reply: fallbackReply(lang),
      });
    }

    const rawReply = await geminiChat(history || [], message.trim(), lang);

    if (isApiErrorPayloadText(rawReply)) {
      return res.json({ classified: false, reply: fallbackReply(lang) });
    }

    const parsed = parseGeminiJson(rawReply);
    if (!parsed || !parsed.classified) {
      return res.json({
        classified: false,
        reply: parsed?.reply || String(rawReply || '').trim() || fallbackReply(lang),
      });
    }

    const specialization = String(parsed.specialization || '').trim();
    const terms = SPEC_MAP[specialization] || [specialization];
    const regexTerms = terms.filter(Boolean).map((t) => new RegExp(`^${t}$`, 'i'));

    const lawyer = await Lawyer.findOne({
      is_online: true,
      is_available: true,
      is_active: true,
      specializations: { $in: regexTerms },
    }).select('_id full_name phone');

    return res.json({
      classified: true,
      specialization,
      reply: parsed.reply,
      lawyer: lawyer
        ? { id: lawyer._id, name: lawyer.full_name, phone: lawyer.phone }
        : null,
    });
  } catch (err) {
    console.error('AI chat error:', err.message);
    if (isTransientGeminiFailure(err)) {
      return res.json({ classified: false, reply: fallbackReply(lang) });
    }
    return res.status(500).json({ error: 'AI service unavailable' });
  }
};
