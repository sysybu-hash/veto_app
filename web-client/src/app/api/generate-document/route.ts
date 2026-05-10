import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 120;

const apiKey = process.env.GEMINI_API_KEY || "";
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

type LegalDocument = {
  title: string;
  preamble: string;
  clauses: string[];
  signatures: { role: string; name: string }[];
  fallback?: boolean;
  fallbackReason?: string;
};

function buildFallbackDocument(
  docTypeLabel: string | undefined,
  prompt: string | undefined,
  reason: string,
): LegalDocument {
  const safeLabel = (docTypeLabel || "מסמך משפטי").trim();
  const userDetails =
    prompt && prompt.trim().length > 0
      ? prompt.trim()
      : "לא נמסרו פרטים נוספים מהלקוח. יש להשלים את הפרטים בהתאם לנסיבות הספציפיות.";
  return {
    title: `טיוטה: ${safeLabel}`,
    preamble: [
      "הואיל ומבקש המסמך פנה למערכת VETO Legal לצורך הפקת טיוטה ראשונית של מסמך זה;",
      "והואיל ויש להתאים את הסעיפים לפרטים הקונקרטיים של הצדדים, המועדים והסכומים;",
      `והואיל וזוהי טיוטה אוטומטית בלבד שאינה מהווה ייעוץ משפטי — ${userDetails}`,
    ].join("\n\n"),
    clauses: [
      "רקע והתקשרות: שלום אני רוצה שתכין את " +
        safeLabel +
        ". יש לפרט את הצדדים, כתובותיהם, ת.ז./ח.פ. ותפקיד כל צד.",
      "הצדדים מצהירים כי הם מוסמכים להתקשר בהסכם זה, פועלים בתום לב, ובידיהם מלוא המידע הרלוונטי.",
      "כל צד יפעל בתום לב, בשיתוף פעולה סביר ומתוך כיבוד מלא של ההתחייבויות הנובעות ממסמך זה.",
      "התחייבויות הצדדים, התמורה, המועדים וכלל התנאים המסחריים יפורטו בנספח א׳ אשר מהווה חלק בלתי נפרד מההסכם.",
      "כל שינוי, הארכה, ויתור או הודעה מכוח הסכם זה ייעשו בכתב ובחתימת שני הצדדים במפורש.",
      "סמכות שיפוט וברירת דין: הדין הישראלי יחול על הסכם זה, וסמכות השיפוט הייחודית מסורה לבתי המשפט המוסמכים בישראל.",
      "פרטים חסרים להשלמה לפני שימוש: שמות הצדדים, מספרי זיהוי, כתובות, מועדי תוקף, סכומים ותנאי תשלום.",
    ],
    signatures: [
      { role: "צד א׳", name: "" },
      { role: "צד ב׳", name: "" },
    ],
    fallback: true,
    fallbackReason: reason,
  };
}

export async function POST(req: Request) {
  let parsedBody: { prompt?: string; docTypeLabel?: string } = {};
  try {
    parsedBody = await req.json();
  } catch {
    parsedBody = {};
  }
  const { prompt, docTypeLabel } = parsedBody;

  try {
    if (!genAI) {
      return NextResponse.json(
        buildFallbackDocument(
          docTypeLabel,
          prompt,
          "שירות ה-AI אינו זמין כרגע (GEMINI_API_KEY חסר). נוצרה טיוטה בסיסית שניתן לערוך.",
        ),
      );
    }

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
    const reason =
      error instanceof Error ? error.message : "שגיאה לא ידועה משירות ה-AI";
    return NextResponse.json(
      buildFallbackDocument(
        docTypeLabel,
        prompt,
        `נוצרה טיוטה בסיסית משום ששירות ה-AI לא הצליח להשלים את הבקשה כרגע (${reason}).`,
      ),
    );
  }
}
