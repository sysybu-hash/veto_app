// ============================================================
//  gemini.service.js - Google Gemini AI Integration
// ============================================================

const { GoogleGenAI } = require('@google/genai');
const { getGeminiModelId } = require('../config/gemini.config');

const SYSTEM_INSTRUCTIONS = {
  he: `אתה עוזר משפטי חכם של VETO. עזור למשתמשים במידע משפטי כללי, זכויות, פרשנות והכוונה ראשונית. אינך מחליף עורך דין ואינך נותן ייעוץ משפטי מחייב.

שאל שאלות קצרות בעברית כדי להבין את הצורך. אם מדובר במצב חירום שמצריך עורך דין עכשיו, סווג לתחום מתאים.

כאשר נדרש עורך דין דחוף עכשיו, השב JSON בלבד:
{"classified":true,"specialization":"[תחום]","reply":"[הודעה קצרה בעברית]"}

כאשר מדובר בשאלה משפטית כללית, השב JSON בלבד:
{"classified":false,"reply":"[תשובה מקצועית, עניינית וקצרה בעברית]"}

כאשר לא ברור, השב JSON בלבד:
{"classified":false,"reply":"[שאלת הבהרה קצרה בעברית]"}

תחומים לשיגור: פלילי | משפחה | נדל״ן | עבודה | מסחרי | תעבורה`,

  en: `You are VETO's legal assistant. Provide general legal information, first orientation, rights, interpretation, and practical next steps. You do not replace a lawyer and do not provide binding legal advice.

Ask short questions to understand the need. If the user needs an urgent lawyer now, classify the request.

For urgent dispatch, reply with JSON only:
{"classified":true,"specialization":"[domain]","reply":"[short English message]"}

For a general legal question, reply with JSON only:
{"classified":false,"reply":"[professional, concise English answer]"}

If unclear, reply with JSON only:
{"classified":false,"reply":"[short clarifying question in English]"}

Dispatch domains: criminal | family | real estate | labor | commercial | traffic`,

  ru: `Вы юридический помощник VETO. Давайте общую юридическую информацию, первичную ориентацию, права и практические следующие шаги. Вы не заменяете адвоката и не даете обязательную юридическую консультацию.

Задавайте короткие вопросы, чтобы понять ситуацию. Если срочно нужен адвокат сейчас, классифицируйте запрос.

Для срочного вызова отвечайте только JSON:
{"classified":true,"specialization":"[область]","reply":"[короткое сообщение по-русски]"}

Для общего юридического вопроса отвечайте только JSON:
{"classified":false,"reply":"[профессиональный краткий ответ по-русски]"}

Если неясно, отвечайте только JSON:
{"classified":false,"reply":"[короткий уточняющий вопрос по-русски]"}

Области: criminal | family | real estate | labor | commercial | traffic`,

  ar: `أنت مساعد قانوني ذكي في VETO. قدم معلومات قانونية عامة وتوجيها أوليا وخطوات عملية. أنت لا تستبدل المحامي ولا تقدم استشارة قانونية ملزمة.

اسأل أسئلة قصيرة لفهم الحاجة. إذا كان المستخدم يحتاج إلى محام بشكل عاجل الآن، صنف الطلب.

عند الحاجة إلى محام عاجل، أجب بصيغة JSON فقط:
{"classified":true,"specialization":"[المجال]","reply":"[رسالة عربية قصيرة]"}

في السؤال القانوني العام، أجب بصيغة JSON فقط:
{"classified":false,"reply":"[إجابة عربية مهنية ومختصرة]"}

إذا كان الأمر غير واضح، أجب بصيغة JSON فقط:
{"classified":false,"reply":"[سؤال توضيحي قصير بالعربية]"}

المجالات: criminal | family | real estate | labor | commercial | traffic`,
};

let _genAI;
function getGenAI() {
  if (!_genAI) {
    _genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }
  return _genAI;
}

function hasGeminiApiKey() {
  return Boolean((process.env.GEMINI_API_KEY || '').trim());
}

/** True when Google may succeed on retry: rate limit, capacity, model overload. */
function isTransientGeminiFailure(err) {
  const m = String(err?.message ?? err ?? '');
  if (/\b429\b/.test(m)) return true;
  if (/\b503\b/.test(m)) return true;
  if (/UNAVAILABLE|RESOURCE_EXHAUSTED|high demand|overloaded/i.test(m)) return true;
  try {
    const j = JSON.parse(m);
    const inner = j?.error;
    if (!inner || typeof inner !== 'object') return false;
    if (inner.code === 503 || inner.code === 429) return true;
    if (inner.status === 'UNAVAILABLE' || inner.status === 'RESOURCE_EXHAUSTED') return true;
    return /high demand|overloaded/i.test(String(inner.message || ''));
  } catch (_) {
    return false;
  }
}

function isApiErrorPayloadText(text) {
  if (typeof text !== 'string' || !text.trim().startsWith('{')) return false;
  try {
    const j = JSON.parse(text);
    const e = j?.error;
    if (!e || typeof e !== 'object') return false;
    if (e.code === 503 || e.code === 429) return true;
    if (e.status === 'UNAVAILABLE' || e.status === 'RESOURCE_EXHAUSTED') return true;
    return /high demand|overloaded/i.test(String(e.message || ''));
  } catch (_) {
    return false;
  }
}

const MAX_GEMINI_ATTEMPTS = 4;

async function geminiChat(history, userMessage, lang = 'he') {
  if (!hasGeminiApiKey()) {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  const ai = getGenAI();
  const contents = [
    ...(Array.isArray(history) ? history : []).map((h) => ({
      role: h.role === 'model' ? 'model' : 'user',
      parts: Array.isArray(h.parts) ? h.parts : [],
    })),
    { role: 'user', parts: [{ text: userMessage }] },
  ];

  for (let attempt = 0; attempt < MAX_GEMINI_ATTEMPTS; attempt += 1) {
    try {
      const response = await ai.models.generateContent({
        model: getGeminiModelId(),
        contents,
        config: {
          systemInstruction: SYSTEM_INSTRUCTIONS[lang] || SYSTEM_INSTRUCTIONS.he,
        },
      });
      const text =
        typeof response.text === 'string'
          ? response.text
          : response.text != null
            ? String(response.text)
            : '';
      if (isApiErrorPayloadText(text)) throw new Error(text);
      return text;
    } catch (err) {
      if (isTransientGeminiFailure(err) && attempt < MAX_GEMINI_ATTEMPTS - 1) {
        const delayMs = Math.min(1200 * (attempt + 1), 4000);
        await new Promise((resolve) => setTimeout(resolve, delayMs));
        continue;
      }
      throw err;
    }
  }

  throw new Error('Gemini request failed');
}

module.exports = {
  geminiChat,
  hasGeminiApiKey,
  isTransientGeminiFailure,
  isApiErrorPayloadText,
  SYSTEM_INSTRUCTIONS,
};
