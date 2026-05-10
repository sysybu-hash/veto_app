// ============================================================
//  ai.controller.js - AI Legal Chat Endpoint
// ============================================================

const {
  geminiChat,
  geminiTranslateSegments,
  hasGeminiApiKey,
  isTransientGeminiFailure,
  isApiErrorPayloadText,
} = require('../services/gemini.service');
const Lawyer = require('../models/Lawyer');
const AITransparencyLog = require('../models/AITransparencyLog');
const { getMatchTerms } = require('../config/specializations');

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

const PUBLIC_AI_GUEST_REPLIES = {
  he:
    'אפשר להשתמש בבועת ה-AI גם ללא רישום. במצב אורח אני יכול להסביר איך VETO עובד, לעזור להבין איזה סוג מסמך או תחום משפטי עשוי להתאים, ולהציע צעדים כלליים. כדי לפתוח SOS לעורך דין, לשמור בכספת, לנתח מסמכים אישיים או ליצור מסמך מלא מתוך נתונים שמורים - יש להתחבר או להירשם. המידע כאן כללי בלבד ואינו מחליף ייעוץ משפטי.',
  en:
    'You can use the AI bubble without signing in. In guest mode I can explain how VETO works, help identify a general legal area or document type, and suggest general next steps. To start SOS lawyer matching, save to the vault, analyze personal documents, or generate full documents from saved account data, please sign in. This is general information only and not legal advice.',
  ru:
    'Вы можете пользоваться AI-виджетом без регистрации. В гостевом режиме я могу объяснить, как работает VETO, помочь определить общий тип вопроса или документа и предложить общие шаги. Для SOS-соединения с юристом, сохранения в сейф, анализа личных документов и полного генератора документов нужно войти в систему. Это общая информация, не юридическая консультация.',
  ar:
    'يمكن استخدام فقاعة الذكاء الاصطناعي بدون تسجيل. في وضع الضيف يمكنني شرح طريقة عمل VETO، ومساعدتك في تحديد المجال القانوني أو نوع المستند بشكل عام، واقتراح خطوات عامة. لطلب محام عبر SOS أو الحفظ في الخزنة أو تحليل مستندات شخصية أو إنشاء مستند كامل من بيانات محفوظة، يجب تسجيل الدخول. هذه معلومات عامة وليست استشارة قانونية.',
};

function guestFallbackReply(lang) {
  return PUBLIC_AI_GUEST_REPLIES[lang] || PUBLIC_AI_GUEST_REPLIES.he;
}

async function recordAiLog(req, fields) {
  try {
    await AITransparencyLog.create({
      user_id: req.user?.userId || null,
      role: req.user?.role || 'anonymous',
      action: fields.action,
      source: fields.source || 'chat',
      model: fields.model || null,
      produced_output: !!fields.produced_output,
      used_fallback: !!fields.used_fallback,
      requires_lawyer_review: true,
      metadata: fields.metadata || null,
    });
  } catch {
    /* transparency logging must never break user flow */
  }
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
      await recordAiLog(req, {
        action: 'AI legal chat fallback',
        source: 'chat',
        produced_output: true,
        used_fallback: true,
      });
      return res.json({
        classified: false,
        configured: false,
        reply: fallbackReply(lang),
      });
    }

    const rawReply = await geminiChat(history || [], message.trim(), lang);

    if (isApiErrorPayloadText(rawReply)) {
      await recordAiLog(req, {
        action: 'AI legal chat fallback',
        source: 'chat',
        produced_output: true,
        used_fallback: true,
      });
      return res.json({ classified: false, reply: fallbackReply(lang) });
    }

    const parsed = parseGeminiJson(rawReply);
    if (!parsed || !parsed.classified) {
      await recordAiLog(req, {
        action: 'AI legal chat',
        source: 'chat',
        model: process.env.GEMINI_MODEL || null,
        produced_output: true,
        used_fallback: false,
      });
      return res.json({
        classified: false,
        reply: parsed?.reply || String(rawReply || '').trim() || fallbackReply(lang),
      });
    }

    const specialization = String(parsed.specialization || '').trim();
    const terms = getMatchTerms(specialization) || [specialization].filter(Boolean);
    const regexTerms = terms.filter(Boolean).map((t) => new RegExp(`^${t}$`, 'i'));

    const lawyer = await Lawyer.findOne({
      is_online: true,
      is_available: true,
      is_active: true,
      specializations: { $in: regexTerms },
    }).select('_id full_name phone');

    await recordAiLog(req, {
      action: 'AI legal chat classification',
      source: 'chat',
      model: process.env.GEMINI_MODEL || null,
      produced_output: true,
      used_fallback: false,
      metadata: { specialization },
    });

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
      await recordAiLog(req, {
        action: 'AI legal chat fallback',
        source: 'chat',
        produced_output: true,
        used_fallback: true,
      });
      return res.json({ classified: false, reply: fallbackReply(lang) });
    }
    return res.status(500).json({ error: 'AI service unavailable' });
  }
};

/**
 * POST /api/ai/public-chat
 * Guest-safe homepage AI. No lawyer matching, no personal vault actions.
 */
exports.publicAiChat = async (req, res) => {
  const lang = safeLang(req.body?.lang);

  try {
    const { message, history } = req.body;
    const cleanMessage = typeof message === 'string' ? message.trim() : '';

    if (!cleanMessage) {
      return res.status(400).json({ error: 'message is required' });
    }

    if (!hasGeminiApiKey()) {
      await recordAiLog(req, {
        action: 'Public AI homepage chat fallback',
        source: 'chat',
        produced_output: true,
        used_fallback: true,
        metadata: { guest: true },
      });
      return res.json({
        classified: false,
        guest: true,
        configured: false,
        reply: guestFallbackReply(lang),
      });
    }

    const guestInstruction = [
      'You are the public homepage AI assistant for VETO, a legal operating system.',
      'The visitor is not authenticated. Do not claim access to their account, vault, subscription, SOS dispatch, saved files, or personal legal history.',
      'Give helpful general information only. Do not provide binding legal advice and do not ask for sensitive identifiers unless absolutely necessary.',
      'Adapt the answer to the visitor: explain relevant VETO features, suggest a general legal area or document type, and invite sign-in only when account-only actions are needed.',
      'Never perform lawyer matching in guest mode. If urgent lawyer help is needed, explain that they must sign in/register to start SOS.',
      `User message: ${cleanMessage}`,
    ].join('\n');

    const rawReply = await geminiChat(history || [], guestInstruction, lang);
    const parsed = parseGeminiJson(rawReply);
    const reply = parsed?.reply || String(rawReply || '').trim() || guestFallbackReply(lang);

    await recordAiLog(req, {
      action: 'Public AI homepage chat',
      source: 'chat',
      model: process.env.GEMINI_MODEL || null,
      produced_output: true,
      used_fallback: false,
      metadata: { guest: true },
    });

    return res.json({
      classified: false,
      guest: true,
      reply,
    });
  } catch (err) {
    console.error('Public AI chat error:', err.message);
    if (isTransientGeminiFailure(err)) {
      await recordAiLog(req, {
        action: 'Public AI homepage chat fallback',
        source: 'chat',
        produced_output: true,
        used_fallback: true,
        metadata: { guest: true },
      });
      return res.json({ classified: false, guest: true, reply: guestFallbackReply(lang) });
    }
    return res.status(500).json({ error: 'AI service unavailable' });
  }
};

exports.createTransparencyLog = async (req, res, next) => {
  try {
    const allowedSources = new Set(['chat', 'vault', 'document', 'call', 'system', 'other']);
    const source = allowedSources.has(req.body?.source) ? req.body.source : 'other';
    const action = String(req.body?.action || '').trim();
    if (!action) return res.status(400).json({ error: 'action is required.' });

    const log = await AITransparencyLog.create({
      user_id: req.user?.userId || null,
      role: req.user?.role || 'anonymous',
      action,
      source,
      model: req.body?.model ? String(req.body.model).slice(0, 120) : null,
      input_ref: req.body?.inputRef ? String(req.body.inputRef).slice(0, 200) : null,
      output_ref: req.body?.outputRef ? String(req.body.outputRef).slice(0, 200) : null,
      produced_output: !!req.body?.producedOutput,
      used_fallback: !!req.body?.usedFallback,
      requires_lawyer_review: req.body?.requiresLawyerReview !== false,
      metadata: req.body?.metadata && typeof req.body.metadata === 'object' ? req.body.metadata : null,
    });
    res.status(201).json({ log });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/ai/translate-segments
 * Live captions translation for the v2 call surface.
 * Body: { segments: string[], targetLang: 'he'|'en'|'ru'|'ar' }
 * Returns: { translations: (string|null)[], configured: boolean }
 */
exports.translateCaptionSegments = async (req, res) => {
  const targetLang = safeLang(req.body?.targetLang);
  const raw = req.body?.segments;
  const segments = Array.isArray(raw)
    ? raw
        .filter((s) => typeof s === 'string' && s.trim().length > 0)
        .slice(0, 50)
        .map((s) => String(s).slice(0, 800))
    : [];

  if (segments.length === 0) {
    return res.json({ translations: [], configured: hasGeminiApiKey() });
  }
  if (!hasGeminiApiKey()) {
    return res.json({
      translations: segments.map(() => null),
      configured: false,
    });
  }

  try {
    const translations = await geminiTranslateSegments(segments, targetLang);
    await recordAiLog(req, {
      action: 'AI captions translation',
      source: 'call',
      model: process.env.GEMINI_MODEL || null,
      produced_output: true,
      used_fallback: false,
      metadata: { count: segments.length, lang: targetLang },
    });
    return res.json({ translations, configured: true });
  } catch (err) {
    console.error('AI translate-segments error:', err.message);
    if (isTransientGeminiFailure(err)) {
      return res.json({
        translations: segments.map(() => null),
        configured: true,
        transient: true,
      });
    }
    return res.status(500).json({ error: 'Translation service unavailable' });
  }
};

exports.listTransparencyLogs = async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 100, 300);
    const query = req.user.role === 'admin' ? {} : { user_id: req.user.userId };
    const logs = await AITransparencyLog.find(query)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    res.json({ logs });
  } catch (err) {
    next(err);
  }
};
