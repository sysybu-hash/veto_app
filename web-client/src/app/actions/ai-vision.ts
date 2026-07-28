"use server";

import { getGoogleAIClient, isGoogleAIConfigured } from "@/lib/googleAI";

function mimeFromPayload(base64Image: string): string {
  const m = /^data:([^;,]+)[;,]/i.exec(base64Image);
  if (m?.[1]) return m[1];
  return "image/jpeg";
}

function stripDataUrl(base64Image: string): string {
  const comma = base64Image.indexOf(",");
  if (comma >= 0) return base64Image.slice(comma + 1);
  return base64Image;
}

export type VisionAnalyzeResult =
  | { success: true; analysis: string }
  | { success: false; error: string };

export async function analyzeLegalDocument(
  base64Image: string,
): Promise<VisionAnalyzeResult> {
  if (!isGoogleAIConfigured()) {
    return {
      success: false,
      error:
        "שירות פענוח המסמכים לא מחובר עדיין בסביבה הזו. בפרודקשן יש להגדיר GEMINI_API_KEY או Vertex AI.",
    };
  }

  try {
    const ai = getGoogleAIClient();
    const imageData = stripDataUrl(base64Image);
    const mimeType = mimeFromPayload(base64Image);

    const prompt = [
      "אתה מסייע משפטי של מערכת VETO.",
      "נתח את המסמך המצולם בעברית, באנגלית או ברוסית.",
      "חלץ סוג מסמך, שמות צדדים אם קיימים, תאריכים קריטיים, סכומים, חובות, סיכונים ופעולות המשך.",
      "השב בקצרה, בעברית, עם כותרות ברורות. אל תמציא פרטים שלא מופיעים בתמונה.",
    ].join("\n");

    const response = await ai.models.generateContent({
      model: process.env.GEMINI_VISION_MODEL || "gemini-2.5-flash",
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }, { inlineData: { data: imageData, mimeType } }],
        },
      ],
    });

    const text = (typeof response.text === "string" ? response.text : String(response.text ?? "")).trim();
    return { success: true, analysis: text || "לא זוהה טקסט משפטי ברור בתמונה." };
  } catch (error) {
    console.error("Vision Error:", error);
    return {
      success: false,
      error: "לא הצלחתי לנתח את המסמך. בדקו שהתמונה חדה ונסו שוב.",
    };
  }
}
