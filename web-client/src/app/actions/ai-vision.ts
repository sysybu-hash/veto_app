"use server";

import { GoogleGenerativeAI } from "@google/generative-ai";

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

/**
 * Analyze a camera frame (base64 data URL or raw base64) with Gemini.
 * Requires GEMINI_API_KEY on the server (Vercel / local .env).
 */
export async function analyzeLegalDocument(
  base64Image: string,
): Promise<VisionAnalyzeResult> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("GEMINI_API_KEY is not configured");
    return { success: false, error: "שירות הראייה אינו מוגדר בשרת" };
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const imageData = stripDataUrl(base64Image);
    const mimeType = mimeFromPayload(base64Image);

    const prompt = `
      אתה סייען משפטי של מערכת VETO.
      נתח את המסמך המצורף בעברית.
      חלץ: סוג המסמך, תאריכים קריטיים, וסיכום משפטי בשלושה בולטים.
      השב בפורמט קצר וסמכותי.
    `.trim();

    const result = await model.generateContent([
      prompt,
      { inlineData: { data: imageData, mimeType } },
    ]);

    const text = result.response.text();
    return { success: true, analysis: text.trim() || "(אין תוצאת טקסט)" };
  } catch (error) {
    console.error("Vision Error:", error);
    return { success: false, error: "לא הצלחתי לנתח את המסמך" };
  }
}
