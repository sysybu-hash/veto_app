import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const maxDuration = 120;

const apiKey = process.env.GEMINI_API_KEY || "";
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

type GeneratedDocument = {
  title: string;
  preamble: string;
  parties?: string[];
  definitions?: string[];
  clauses: string[];
  attachments?: string[];
  completionChecklist?: string[];
  legalNotes?: string[];
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

const DOCUMENT_TYPE_GUIDES: Record<string, string> = {
  warning_letter:
    "מכתב התראה צריך לכלול נמען, שולח, רקע עובדתי, ההפרה הנטענת, דרישה אופרטיבית, מועד לתיקון, אסמכתאות, שמירת זכויות והתרעה לפני הליכים.",
  cease_and_desist:
    "מכתב חדילה צריך לכלול תיאור ההפרה, זיהוי הזכויות שנפגעו, דרישה להפסקה מיידית, הסרת פרסומים/שימושים, התחייבות עתידית, פיצוי ככל שרלוונטי ושמירת זכויות.",
  lease_agreement:
    "חוזה שכירות צריך לכלול זהות משכיר ושוכר, נכס, תקופה, דמי שכירות, בטוחות, תשלומים נלווים, תחזוקה, שימוש מותר, הפרות, פינוי, ביטוח, הודעות וחתימות.",
  nda:
    "הסכם סודיות צריך לכלול צדדים, מידע סודי, מטרת הגילוי, התחייבויות שמירה, חריגים, תקופת סודיות, החזרת מידע, סעד בגין הפרה, דין וסמכות.",
  employment:
    "מסמך עבודה צריך לכלול תפקיד, היקף משרה, שכר, תנאים סוציאליים, סודיות, קניין רוחני, תקופת הודעה מוקדמת, משמעת, פרטיות וסיום העסקה.",
  loan_agreement:
    "הסכם הלוואה צריך לכלול לווה, מלווה, סכום, מועד העברה, ריבית אם יש, לוח סילוקין, בטוחות, פירעון מוקדם, הפרה, הוצאות גבייה וחתימות.",
  power_of_attorney:
    "ייפוי כוח צריך לכלול מייפה כוח, מיופה כוח, סמכויות מדויקות, מגבלות, תוקף, אפשרות ביטול, הצהרות זהות, אימות חתימה ונספחים.",
  family_estate:
    "מסמך משפחה/ירושה צריך לכלול זהות הצדדים, קשר משפחתי, נכסים או זכויות, רצון הצדדים, מנגנון ביצוע, הסתייגויות, מסמכי תמיכה והמלצה לאימות משפטי.",
  tort_insurance:
    "מסמך נזיקין/ביטוח צריך לכלול אירוע, תאריך, מקום, נזק, אחריות נטענת, פוליסה/מבטח, מסמכים רפואיים או שמאיים, דרישה כספית ושמירת זכויות.",
  consumer_privacy:
    "מסמך צרכנות/פרטיות צריך לכלול עסקה או שירות, פגם או הפרה, פניות קודמות, דרישה לתיקון/ביטול/השבה, מידע אישי שנאסף, מועדים ונספחים.",
  commercial:
    "מסמך מסחרי צריך לכלול צדדים, רקע עסקי, תמורה, מועדים, מצגים, סודיות, קניין רוחני, אחריות, סיום, הפרות, פתרון מחלוקות ודין חל.",
  authority_request:
    "בקשה לרשות צריכה לכלול פרטי פונה, רשות מטפלת, נושא הבקשה, רקע עובדתי, בסיס נורמטיבי, מסמכים מצורפים, סעד מבוקש ומועד למענה.",
  custom:
    "מסמך מותאם צריך לכלול את מטרת המסמך, הצדדים, העובדות, הפעולה המבוקשת, מועדים, אסמכתאות, סעדים, שמירת זכויות ופרטים חסרים להשלמה.",
};

const COMMON_COMPLETION_CHECKLIST = [
  "להשלים שמות מלאים, מספרי זיהוי, כתובות ופרטי קשר של כל הצדדים.",
  "לוודא שכל התאריכים, הסכומים, המועדים והחשבונות נכונים ומגובים באסמכתאות.",
  "לצרף מסמכים תומכים: חוזים, הודעות, חשבוניות, תיעוד שיחה, תמונות, הקלטות או אישורים.",
  "להגדיר מועד ברור לביצוע או למענה כאשר המסמך כולל דרישה אופרטיבית.",
  "לקבל בדיקה משפטית לפני שליחה רשמית, חתימה, הגשה לרשות או נקיטת הליכים.",
];

function guideFor(documentType: string): string {
  return DOCUMENT_TYPE_GUIDES[documentType] || DOCUMENT_TYPE_GUIDES.custom;
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.map((x) => String(x).trim()).filter(Boolean)
    : [];
}

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
    parties: [
      "צד א': יש להשלים שם מלא, מספר זיהוי, כתובת ופרטי קשר.",
      "צד ב' / נמען / רשות: יש להשלים שם מלא, מספר זיהוי או ח.פ., כתובת ופרטי קשר.",
    ],
    definitions: [
      "המסמך: טיוטה זו וכל נספח שיצורף אליה.",
      "האירוע / ההתקשרות: מכלול העובדות, ההסכמות, ההודעות והמסמכים שתוארו בפרטי המשתמש.",
      "אסמכתאות: כל מסמך, הודעה, צילום, הקלטה, חשבונית, אישור או ראיה אחרת התומכים בטענות.",
    ],
    clauses: fallbackClauses(docTypeLabel, prompt),
    attachments: [
      "צילום תעודת זהות / פרטי חברה לפי העניין.",
      "הסכמים, הודעות, חשבוניות, קבלות ותכתובות רלוונטיות.",
      "תיעוד ראייתי: תמונות, הקלטות, תמלולים, אישורים או מסמכי רשות.",
    ],
    completionChecklist: COMMON_COMPLETION_CHECKLIST,
    legalNotes: [
      "המסמך הוא טיוטה ראשונית ואינו מחליף ייעוץ משפטי פרטני.",
      "אין להשתמש במסמך להגשה או לחתימה לפני אימות עובדות, סמכויות חתימה ודרישות צורניות.",
      "כאשר המסמך מיועד לרשות, לבית משפט או לצד שלישי, יש לבדוק מועדים, אגרות, נספחים ודרך המצאה.",
    ],
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
  const clauses = stringArray(raw.clauses);
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
    parties: stringArray(raw.parties).length > 0 ? stringArray(raw.parties) : fallback.parties,
    definitions: stringArray(raw.definitions).length > 0 ? stringArray(raw.definitions) : fallback.definitions,
    clauses: clauses.length > 0 ? clauses : fallback.clauses,
    attachments: stringArray(raw.attachments).length > 0 ? stringArray(raw.attachments) : fallback.attachments,
    completionChecklist:
      stringArray(raw.completionChecklist).length > 0 ? stringArray(raw.completionChecklist) : fallback.completionChecklist,
    legalNotes: stringArray(raw.legalNotes).length > 0 ? stringArray(raw.legalNotes) : fallback.legalNotes,
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
            parties: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
            definitions: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
            clauses: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
            attachments: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
            completionChecklist: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
            legalNotes: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
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
          required: [
            "title",
            "preamble",
            "parties",
            "definitions",
            "clauses",
            "attachments",
            "completionChecklist",
            "legalNotes",
            "signatures",
          ],
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

    const qualityInstruction = [
      "החזר JSON בלבד לפי הסכמה המלאה: title, preamble, parties, definitions, clauses, attachments, completionChecklist, legalNotes, signatures.",
      "המסמך חייב להיות מפורט ומעשי: 10-18 סעיפים לפחות, עם רקע, הצדדים, הגדרות, התחייבויות/דרישות אופרטיביות, מועדים, ראיות, נספחים, הפרות, סעדים, דין וסמכות, שמירת זכויות וחתימות.",
      "כל סעיף צריך להיות משפטי וברור, לא כותרת קצרה. כאשר חסר מידע, כתוב שדה השלמה מדויק בתוך הסעיף או בצ'קליסט.",
      "הוסף completionChecklist עם פעולות לפני שימוש במסמך, attachments עם נספחים מומלצים, ו-legalNotes עם הערות זהירות.",
    ].join("\n");
    const guidedQualityInstruction = `${qualityInstruction}\nהנחיית עומק למסמך: ${guideFor(documentType)}`;

    const result = await model.generateContent([
      { text: instruction },
      { text: guidedQualityInstruction },
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
