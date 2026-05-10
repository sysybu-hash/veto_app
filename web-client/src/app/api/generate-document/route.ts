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
  source?: "ai" | "fallback";
  warning?: string;
};

const LEGAL_AREAS = [
  "חוזים והסכמים",
  "מכתבי התראה ודרישה",
  "דיני עבודה",
  "שכירות ומקרקעין",
  "משפחה וירושה",
  "נזיקין וביטוח",
  "צרכנות",
  "פרטיות והגנת מידע",
  "מסחרי וחברות",
  "ייפוי כוח ותצהירים",
  "בקשות ומכתבים לרשויות",
  "הליכים אזרחיים",
].join(", ");

function missingFieldsClause(): string {
  return "פרטים חסרים להשלמה לפני שימוש: שמות מלאים ומספרי זיהוי של הצדדים, כתובות, תאריכים רלוונטיים, סכומים, מועדים לביצוע, אסמכתאות וכל פרט עובדתי שלא נמסר במפורש.";
}

function fallbackClauses(docTypeLabel: string, prompt: string): string[] {
  const facts = prompt || "הצדדים מבקשים להסדיר עניין משפטי על פי הפרטים שיימסרו בהמשך.";
  const lower = `${docTypeLabel} ${prompt}`.toLowerCase();
  const isWarning = /התראה|דרישה|הפרה|חדול|נקיטת/.test(lower);
  const isContract = /חוזה|הסכם|שכירות|עבודה|הלוואה|סודיות|nda/.test(lower);
  const isAuthority = /בקשה|רשות|עירייה|משרד|מוסד|ערעור/.test(lower);

  if (isWarning) {
    return [
      `רקע עובדתי: ${facts}`,
      "הנמען נדרש לתקן את ההפרה או למסור מענה ענייני ומנומק בתוך המועד שייקבע במסמך.",
      "ככל שלא יתקבל מענה או תיקון מלא במועד, השולח שומר על כל זכויותיו, טענותיו וסעדיו, לרבות פנייה לערכאות או לרשות מוסמכת.",
      "אין באמור במסמך זה משום ויתור, הודאה או מיצוי טענות, וכל הזכויות שמורות במלואן.",
      missingFieldsClause(),
    ];
  }

  if (isAuthority) {
    return [
      `נושא הפנייה: ${facts}`,
      "הפונה מבקש כי הבקשה תיבחן לגופה, על בסיס המסמכים והנסיבות שיפורטו ויצורפו.",
      "ככל שנדרש מסמך נוסף או השלמת פרטים, מתבקש הגורם המטפל להודיע על כך בכתב ובמועד סביר.",
      "הפונה שומר על זכותו להגיש השגה, ערר, בקשה חוזרת או כל הליך אחר לפי דין.",
      missingFieldsClause(),
    ];
  }

  if (isContract) {
    return [
      `רקע והתקשרות: ${facts}`,
      "הצדדים מצהירים כי הם מוסמכים להתקשר במסמך וכי מסרו זה לזה מידע מהותי הדרוש להתקשרות.",
      "כל צד יפעל בתום לב, בשיתוף פעולה סביר ובהתאם לכל דין החל בישראל.",
      "התחייבויות הצדדים, התמורה, המועדים, אופן הביצוע והמסמכים המצורפים יפורטו במסמך או בנספחיו.",
      "כל שינוי, הארכה, ויתור או הודעה מכוח מסמך זה ייעשו בכתב, אלא אם הצדדים הסכימו אחרת במפורש.",
      "סמכות שיפוט וברירת דין: הדין הישראלי יחול, וסמכות השיפוט תיקבע לפי הוראות הדין והנסיבות.",
      missingFieldsClause(),
    ];
  }

  return [
    `רקע: ${facts}`,
    "מטרת המסמך היא לתעד את עמדת הפונה, להסדיר את הזכויות והחובות הרלוונטיות, וליצור בסיס פעולה ברור.",
    "המסמך נערך לפי הדין הישראלי ובהתאם לפרטים שנמסרו בלבד, ללא המצאת עובדות שלא נמסרו.",
    "כל צד שומר על מלוא זכויותיו, טענותיו וסעדיו על פי כל דין.",
    "יש לצרף אסמכתאות, מסמכים ותיעוד רלוונטי, ולהשלים פרטים חסרים לפני שימוש רשמי.",
    missingFieldsClause(),
  ];
}

function fallbackDocument(docTypeLabel: string, prompt: string, warning?: string): GeneratedDocument {
  return {
    title: docTypeLabel || "מסמך משפטי מותאם",
    preamble:
      "טיוטה ראשונית זו נערכה לפי הפרטים שנמסרו. יש להשלים פרטים חסרים, לוודא התאמה לנסיבות המקרה, ולקבל ייעוץ משפטי לפני שימוש רשמי או הגשה.",
    clauses: fallbackClauses(docTypeLabel, prompt),
    signatures: [
      { role: "חתימת הפונה / צד א׳", name: "" },
      { role: "חתימת הצד השני / צד ב׳", name: "" },
    ],
    source: "fallback",
    warning,
  };
}

function normalizeDocument(value: unknown, docTypeLabel: string, prompt: string): GeneratedDocument {
  if (!value || typeof value !== "object") {
    return fallbackDocument(docTypeLabel, prompt, "נוצרה טיוטה בסיסית משום שתשובת ה-AI לא הייתה במבנה תקין.");
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
  const fallback = fallbackDocument(docTypeLabel, prompt);

  return {
    title: typeof raw.title === "string" && raw.title.trim() ? raw.title.trim() : fallback.title,
    preamble: typeof raw.preamble === "string" && raw.preamble.trim() ? raw.preamble.trim() : fallback.preamble,
    clauses: clauses.length > 0 ? clauses : fallback.clauses,
    signatures: signatures.length > 0 ? signatures : fallback.signatures,
    source: "ai",
  };
}

function parseJsonLoose(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) return null;
    return JSON.parse(jsonMatch[0]);
  }
}

export async function POST(req: Request) {
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

  if (!genAI) {
    return NextResponse.json(
      fallbackDocument(docTypeLabel, prompt, "נוצרה טיוטה בסיסית משום שמפתח Gemini אינו מוגדר בסביבה הזו."),
    );
  }

  try {
    const model = genAI.getGenerativeModel({
      model: process.env.GEMINI_DOCUMENT_MODEL || "gemini-1.5-flash",
      generationConfig: {
        temperature: 0.22,
        responseMimeType: "application/json",
        responseSchema: {
          type: SchemaType.OBJECT,
          properties: {
            title: { type: SchemaType.STRING },
            preamble: { type: SchemaType.STRING },
            clauses: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
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
      `עליך להתמודד עם כל תחום משפטי רלוונטי, כולל: ${LEGAL_AREAS}.`,
      "החזר JSON בלבד לפי הסכמה: title, preamble, clauses, signatures.",
      "כתוב בעברית ברורה, רשמית, זהירה, ולפי דין ישראלי.",
      "אל תמציא עובדות שלא נמסרו. כאשר חסר מידע, הוסף סעיף שמסמן בדיוק אילו פרטים יש להשלים.",
      "המסמך צריך להיות שימושי כטיוטה ראשונה: פתיח, רקע, סעיפים אופרטיביים, שמירת זכויות, סמכות/דין וחתימות כאשר מתאים.",
      "אין להחזיר Markdown ואין להוסיף הסברים מחוץ ל-JSON.",
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

    return NextResponse.json(normalizeDocument(parseJsonLoose(result.response.text()), docTypeLabel, prompt));
  } catch (error) {
    console.error("Document Generation Error:", error);
    return NextResponse.json(
      fallbackDocument(docTypeLabel, prompt, "נוצרה טיוטה בסיסית משום ששירות ה-AI לא הצליח להשלים את הבקשה כרגע."),
    );
  }
}
