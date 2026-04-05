// ============================================================
//  gemini.service.js — Google Gemini AI Integration
//  VETO Legal Emergency App
// ============================================================

const { GoogleGenAI } = require('@google/genai');

const SYSTEM_INSTRUCTIONS = {
  he: `אתה עוזר משפטי של VETO. תפקידך הוא לזהות את תחום המשפט הרלוונטי לבעיית המשתמש.
שאל שאלות קצרות בעברית. לאחר שאלה-שתיים, קבע את התחום.

כשאתה בטוח – ענה JSON בלבד:
{"classified":true,"specialization":"[תחום]","reply":"[הודעה קצרה בעברית]"}

כל עוד לא ברור – ענה JSON בלבד:
{"classified":false,"reply":"[שאלה קצרה בעברית]"}

תחומים אפשריים: פלילי | משפחה | נדל"ן | עבודה | מסחרי | תעבורה
ענה תמיד JSON בלבד, ללא שום טקסט לפני או אחרי.`,

  ar: `أنت مساعد قانوني لـ VETO. مهمتك تحديد المجال القانوني المناسب لمشكلة المستخدم.
اطرح أسئلة قصيرة بالعربية. بعد سؤال أو سؤالين، حدد المجال.

عند التأكد – أجب بـ JSON فقط:
{"classified":true,"specialization":"[المجال]","reply":"[رسالة قصيرة بالعربية]"}

إن لم يتضح – أجب بـ JSON فقط:
{"classified":false,"reply":"[سؤال توضيحي قصير بالعربية]"}

المجالات الممكنة: جنائي | عائلة | عقارات | عمل | تجاري | مرور
أجب بـ JSON فقط دائماً، بدون أي نص قبل أو بعد.`,

  en: `You are a legal assistant for VETO. Your job is to identify the relevant legal domain for the user's problem.
Ask short questions in English. After one or two questions, determine the domain.

When certain – reply with JSON only:
{"classified":true,"specialization":"[domain]","reply":"[short English message]"}

When unclear – reply with JSON only:
{"classified":false,"reply":"[short clarifying question in English]"}

Possible domains: criminal | family | real estate | labor | commercial | traffic
Always reply with JSON only, no text before or after.`,
};

let _genAI;
function getGenAI() {
  if (!_genAI) {
    _genAI = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
      httpOptions: { apiVersion: 'v1' },
    });
  }
  return _genAI;
}

/**
 * Send a message to Gemini with conversation history.
 * @param {Array}  history     - [{role, parts:[{text}]}]
 * @param {string} userMessage
 * @param {string} lang        - 'he' | 'ar' | 'en'
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

  // Retry up to 3 times on rate-limit (429) errors
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await ai.models.generateContent({
        model: 'gemini-1.5-flash-002',
        contents,
        config: {
          systemInstruction: SYSTEM_INSTRUCTIONS[lang] || SYSTEM_INSTRUCTIONS.he,
        },
      });
      return response.text;
    } catch (err) {
      const is429 = err.message && err.message.includes('429');
      if (is429 && attempt < 2) {
        await new Promise(r => setTimeout(r, (attempt + 1) * 2000));
        continue;
      }
      throw err;
    }
  }
}

module.exports = { geminiChat };
