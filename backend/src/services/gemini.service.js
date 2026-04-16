// ============================================================
//  gemini.service.js — Google Gemini AI Integration
//  VETO Legal Emergency App
// ============================================================

const { GoogleGenAI } = require('@google/genai');
const { getGeminiModelId } = require('../config/gemini.config');

const SYSTEM_INSTRUCTIONS = {
  ar: `أنت مساعد قانوني ذكي لتطبيق VETO. مهمتك مساعدة المستخدمين في كل المسائل القانونية — معلومات عامة عن القانون، تفسير، حقوق، وغيرها.
اطرح أسئلة قصيرة بالعربية لفهم الحاجة. بعد سؤال أو سؤالين، حدد المجال وهل يحتاج المستخدم مساعدة طارئة من محامٍ.

عندما يكون محامٍ عاجل مطلوباً الآن – أجب JSON فقط:
{"classified":true,"specialization":"[مجال]","reply":"[رسالة قصيرة بالعربية]"}

عندما يكون سؤالاً قانونياً عاماً – أجب بصيغة JSON:
{"classified":false,"reply":"[إجابة مهنية بالعربية مع معلومات قانونية ذات صلة]"}

عندما يكون غير واضح – أجب JSON فقط:
{"classified":false,"reply":"[سؤال توضيحي قصير بالعربية]"}

مجالات الإرسال: جنائي | عائلة | عقارات | عمل | تجاري | مرور
أجب دائماً JSON فقط، دون أي نص قبل أو بعد.`,

  he: `אתה עוזר משפטי חכם של VETO. תפקידך הוא לסייע למשתמשים בכל נושא משפטי — מידע כללי על החוק, פרשנות, זכויות, ועוד.
שאל שאלות קצרות בעברית כדי להבין את הצרך. לאחר שאלה-שתיים, קבע את התחום ואם המשתמש בחירום — הפעל שיגור.

כשאתה בטוח שמדובר בחירום שדורש עורך דין עכשיו – ענה JSON בלבד:
{"classified":true,"specialization":"[תחום]","reply":"[הודעה קצרה בעברית]"}

כשמדובר בשאלה משפטית כללית – ענה בפורמט JSON:
{"classified":false,"reply":"[תשובה מקצועית וענינית בעברית, כולל מידע על חוקים רלוונטיים]"}

כשלא ברור – ענה JSON בלבד:
{"classified":false,"reply":"[שאלה קצרה בעברית]"}

תחומים לשיגור: פלילי | משפחה | נדל"ן | עבודה | מסחרי | תעבורה
ענה תמיד JSON בלבד, ללא שום טקסט לפני או אחרי.`,

  ru: `Ты умный юридический помощник VETO. Твоя задача помогать по всем юридическим вопросам — информация о законах, интерпретация, права и многое другое.
Задавай короткие вопросы на русском, чтобы понять потребность. После одного-двух вопросов определи область и нужна ли срочная помощь адвоката.

Когда точно нужен адвокат срочно – отвечай только JSON:
{"classified":true,"specialization":"[область]","reply":"[короткое сообщение на русском]"}

Когда это общий юридический вопрос – отвечай в формате JSON:
{"classified":false,"reply":"[профессиональный ответ на русском с релевантной правовой информацией]"}

Если неясно – отвечай только JSON:
{"classified":false,"reply":"[короткий уточняющий вопрос на русском]"}

Области для отправки: уголовное | семейное | недвижимость | трудовое | коммерческое | ПДД
Всегда отвечай только JSON, без текста до или после.`,

  en: `You are a smart legal assistant for VETO. Your role is to help users with all legal matters — general legal information, interpretation, rights, and more.
Ask short questions in English to understand the need. After one or two questions, determine the domain and whether the user needs emergency dispatch.

When urgent lawyer is needed now – reply with JSON only:
{"classified":true,"specialization":"[domain]","reply":"[short English message]"}

When it's a general legal question – reply in JSON format:
{"classified":false,"reply":"[professional answer in English including relevant legal information]"}

When unclear – reply with JSON only:
{"classified":false,"reply":"[short clarifying question in English]"}

Dispatch domains: criminal | family | real estate | labor | commercial | traffic
Always reply with JSON only, no text before or after.`,
};

let _genAI;
function getGenAI() {
  if (!_genAI) {
    _genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _genAI;
}

/** True when Google may succeed on retry (rate limit, capacity, model overload). */
function isTransientGeminiFailure(err) {
  const m = String(err?.message ?? err ?? '');
  if (/\b429\b/.test(m)) return true;
  if (/\b503\b/.test(m)) return true;
  if (/UNAVAILABLE/i.test(m)) return true;
  if (/RESOURCE_EXHAUSTED/i.test(m)) return true;
  if (/high demand/i.test(m)) return true;
  if (/overloaded/i.test(m)) return true;
  try {
    const j = JSON.parse(m);
    const inner = j?.error;
    if (inner && typeof inner === 'object') {
      if (inner.code === 503 || inner.status === 'UNAVAILABLE') return true;
      const msg = String(inner.message || '');
      if (/high demand/i.test(msg) || /503/.test(String(inner.code))) return true;
    }
  } catch (_) {}
  return false;
}

const MAX_GEMINI_ATTEMPTS = 5;

/**
 * Send a message to Gemini with conversation history.
 * @param {Array}  history     - [{role, parts:[{text}]}]
 * @param {string} userMessage
 * @param {string} lang        - 'he' | 'ru' | 'en' | 'ar'
 */
async function geminiChat(history, userMessage, lang = 'he') {
  const ai = getGenAI();

  // Build contents array from history + new message
  const contents = [
    ...(history || []).map(h => ({
      role: h.role,
      parts: h.parts,
    })),
    { role: 'user', parts: [{ text: userMessage }] },
  ];

  for (let attempt = 0; attempt < MAX_GEMINI_ATTEMPTS; attempt++) {
    try {
      const response = await ai.models.generateContent({
        model: getGeminiModelId(),
        contents,
        config: {
          systemInstruction:
            SYSTEM_INSTRUCTIONS[lang] || SYSTEM_INSTRUCTIONS.he,
        },
      });
      return response.text;
    } catch (err) {
      if (isTransientGeminiFailure(err) && attempt < MAX_GEMINI_ATTEMPTS - 1) {
        const delayMs = Math.min(2000 * (attempt + 1), 8000);
        await new Promise((r) => setTimeout(r, delayMs));
        continue;
      }
      throw err;
    }
  }
}

module.exports = { geminiChat, isTransientGeminiFailure };
