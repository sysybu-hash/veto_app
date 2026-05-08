import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 120;

const apiKey = process.env.GEMINI_API_KEY || "";
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

type GeneratedDocument = {
  title: string;
  preamble: string;
  clauses: string[];
  signatures: { role: string; name: string }[];
};

function fallbackDocument(docTypeLabel: string, prompt: string): GeneratedDocument {
  const title = docTypeLabel || "מסמך משפטי";
  return {
    title,
    preamble:
      "מסמך זה הוא טיוטה ראשונית שנערכה לפי הפרטים שנמסרו. יש להשלים פרטים חסרים, לבדוק התאמה לנסיבות המקרה, ולקבל ייעוץ משפטי לפני שימוש רשמי.",
    clauses: [
      `רקע: ${prompt || "הצדדים מבקשים להסדיר את יחסיהם במסמך משפטי ברור ומחייב."}`,
      "הצהרות הצדדים: כל צד מצהיר כי מסר פרטים נכונים וכי הוא מוסמך להתקשר במסמך זה.",
      "התחייבויות: הצדדים יפעלו בתום לב, בשיתוף פעולה, ובהתאם לכל דין החל בישראל.",
      "שמירת זכויות: אין במסמך זה כדי לגרוע מכל זכות, טענה או סעד העומדים למי מהצדדים לפי דין.",
      "סמכות ושינויים: כל שינוי במסמך ייעשה בכתב ובחתימת הצדדים.",
    ],
    signatures: [
      { role: "צד א׳", name: "" },
      { role: "צד ב׳", name: "" },
    ],
  };
}

function normalizeDocument(value: unknown, docTypeLabel: string, prompt: string): GeneratedDocument {
  if (!value || typeof value !== "object") {
    return fallbackDocument(docTypeLabel, prompt);
  }
  const raw = value as Partial<GeneratedDocument>;
  const clauses = Array.isArray(raw.clauses)
    ? raw.clauses.map((x) => String(x).trim()).filter(Boolean)
    : [];
  const signatures = Array.isArray(raw.signatures)
    ? raw.signatures
        .map((s) => ({
          role: typeof s?.role === "string" ? s.role.trim() : "",
          name: typeof s?.name === "string" ? s.name.trim() : "",
        }))
        .filter((s) => s.role)
    : [];

  return {
    title: typeof raw.title === "string" && raw.title.trim() ? raw.title.trim() : docTypeLabel || "מסמך משפטי",
    preamble:
      typeof raw.preamble === "string" && raw.preamble.trim()
        ? raw.preamble.trim()
        : fallbackDocument(docTypeLabel, prompt).preamble,
    clauses: clauses.length > 0 ? clauses : fallbackDocument(docTypeLabel, prompt).clauses,
    signatures: signatures.length > 0 ? signatures : fallbackDocument(docTypeLabel, prompt).signatures,
  };
}

export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as {
      prompt?: unknown;
      documentType?: unknown;
      docTypeLabel?: unknown;
    };
    const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
    const documentType = typeof body.documentType === "string" ? body.documentType : "custom";
    const docTypeLabel =
      typeof body.docTypeLabel === "string" && body.docTypeLabel.trim()
        ? body.docTypeLabel.trim()
        : "מסמך משפטי מותאם";

    if (documentType === "custom" && prompt.length < 12) {
      return NextResponse.json(
        { error: "כדי ליצור מסמך מותאם, כתבו לפחות משפט אחד עם פרטי המקרה." },
        { status: 400 },
      );
    }

    if (!genAI) {
      return NextResponse.json(fallbackDocument(docTypeLabel, prompt));
    }

    const model = genAI.getGenerativeModel({
      model: process.env.GEMINI_DOCUMENT_MODEL || "gemini-1.5-flash",
      generationConfig: {
        temperature: 0.25,
        responseMimeType: "application/json",
        responseSchema: {
          type: SchemaType.OBJECT,
          properties: {
            title: { type: SchemaType.STRING },
            preamble: { type: SchemaType.STRING },
            clauses: {
              type: SchemaType.ARRAY,
              items: { type: SchemaType.STRING },
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

    const instruction = [
      "אתה עורך דין ישראלי בכיר ומנסח מסמכים משפטיים בעברית.",
      "החזר JSON בלבד לפי הסכמה: title, preamble, clauses, signatures.",
      "כתוב בעברית ברורה, רשמית, ולפי דין ישראלי.",
      "אל תמציא עובדות שלא נמסרו. במקומות חסרים השתמש בקווים להשלמה.",
      "הוסף סעיפי זהירות, סמכות, תום לב, שמירת זכויות וחתימות כאשר מתאים.",
      "אין להחזיר Markdown ואין להוסיף הסברים מחוץ ל־JSON.",
    ].join("\n");

    const result = await model.generateContent([
      { text: instruction },
      {
        text: [
          `סוג מסמך: ${docTypeLabel}`,
          `מזהה תבנית: ${documentType}`,
          `פרטי המשתמש: ${prompt || "לא נמסרו פרטים. צור טיוטה כללית עם שדות להשלמה."}`,
        ].join("\n"),
      },
    ]);

    const text = result.response.text();
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      parsed = jsonMatch ? JSON.parse(jsonMatch[0]) : null;
    }

    return NextResponse.json(normalizeDocument(parsed, docTypeLabel, prompt));
  } catch (error) {
    console.error("Document Generation Error:", error);
    return NextResponse.json(
      { error: "לא ניתן היה ליצור את המסמך כרגע. נסו שוב עם פרטים קצרים וברורים יותר." },
      { status: 500 },
    );
  }
}
