// ============================================================
//  gemini.service.js — Google Gemini AI Integration
//  VETO Legal Emergency App
// ============================================================

const { GoogleGenerativeAI } = require('@google/generative-ai');

const SYSTEM_INSTRUCTION = `אתה עוזר משפטי של VETO. תפקידך הוא לעזור למשתמש לזהות את תחום המשפט הרלוונטי לבעייתו.

שאל שאלות קצרות בעברית כדי להבין את המצב. לאחר שאלה-שתיים, קבע את תחום המשפט.

כאשר אתה בטוח לגבי התחום, ענה עם JSON בדיוק כך (ללא שום טקסט נוסף):
{"classified":true,"specialization":"[תחום]","reply":"[הודעה קצרה בעברית למשתמש]"}

תחומים אפשריים בלבד: פלילי | משפחה | נדל"ן | עבודה | מסחרי | תעבורה

כל עוד לא ברור התחום, ענה עם JSON בדיוק כך:
{"classified":false,"reply":"[שאלת הבהרה קצרה בעברית]"}

חוקים:
- ענה תמיד בעברית
- החזר תמיד JSON בלבד, ללא כל טקסט לפני או אחרי
- שאלות קצרות ותמציתיות
- אל תשאל יותר מ-3 שאלות לפני שאתה מסווג`;

let _genAI;
function getGenAI() {
  if (!_genAI) {
    _genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  }
  return _genAI;
}

/**
 * Send a message to Gemini with conversation history.
 * @param {Array} history  - Array of { role: 'user'|'model', parts: [{text}] }
 * @param {string} userMessage - The current user message
 * @returns {Promise<string>} - Raw text response from Gemini
 */
async function geminiChat(history, userMessage) {
  const model = getGenAI().getGenerativeModel({
    model: 'gemini-1.5-flash',
    systemInstruction: SYSTEM_INSTRUCTION,
  });

  const chat = model.startChat({ history: history || [] });
  const result = await chat.sendMessage(userMessage);
  return result.response.text();
}

module.exports = { geminiChat };
