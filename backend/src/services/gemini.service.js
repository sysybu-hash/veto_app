// ============================================================
//  gemini.service.js — Google Gemini AI Integration
//  VETO Legal Emergency App
// ============================================================

const { GoogleGenAI } = require('@google/genai');

const SYSTEM_INSTRUCTIONS = {
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

/**
 * Send a message to Gemini with conversation history.
 * @param {Array}  history     - [{role, parts:[{text}]}]
 * @param {string} userMessage
 * @param {string} lang        - 'he' | 'ru' | 'en'
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
        model: 'gemini-2.5-flash',
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
