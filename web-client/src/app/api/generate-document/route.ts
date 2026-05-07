import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 120;

const apiKey = process.env.GEMINI_API_KEY || "";
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

export async function POST(req: Request) {
  try {
    if (!genAI) {
      return NextResponse.json(
        { error: "מפתח API של Gemini חסר במערכת" },
        { status: 500 },
      );
    }

    const body = await req.json();
    const { prompt, docTypeLabel } = body;

    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-pro",
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: SchemaType.OBJECT,
          properties: {
            title: { type: SchemaType.STRING },
            preamble: {
              type: SchemaType.STRING,
              description: "פסקאות 'הואיל ו...'",
            },
            clauses: {
              type: SchemaType.ARRAY,
              items: { type: SchemaType.STRING },
              description: "סעיפי החוזה ממוספרים, מנוסחים משפטית",
            },
            signatures: {
              type: SchemaType.ARRAY,
              items: {
                type: SchemaType.OBJECT,
                properties: {
                  role: { type: SchemaType.STRING },
                  name: { type: SchemaType.STRING },
                },
              },
            },
          },
          required: ["title", "preamble", "clauses", "signatures"],
        },
      },
    });

    const systemInstruction = `אתה עורך דין ישראלי בכיר. תפקידך לנסח מסמכים משפטיים מקצועיים, מדויקים ורשמיים בעברית (דין ישראלי). עליך להחזיר רק את תוכן המסמך המחולק לכותרת, מבוא (הואיל ו...), סעיפי ליבה וחתימות. אל תוסיף הקדמות או סיכומי טקסט.`;

    const userPrompt = `סוג המסמך המבוקש: ${docTypeLabel}. 
הנחיות ופרטים מהלקוח: ${prompt || "נסח מסמך סטנדרטי ומקיף לסוג זה, השאר קווים תחתונים במקומות הדורשים השלמת פרטים."}`;

    const result = await model.generateContent([
      { text: systemInstruction },
      { text: userPrompt },
    ]);

    const responseText = result.response.text();
    return NextResponse.json(JSON.parse(responseText));
  } catch (error) {
    console.error("Document Generation Error:", error);
    return NextResponse.json(
      { error: "שגיאה ביצירת המסמך המשפטי" },
      { status: 500 },
    );
  }
}
