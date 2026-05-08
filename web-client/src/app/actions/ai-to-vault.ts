"use server";

import { createHash } from "node:crypto";

import { saveEvidence } from "@/app/actions/vault";
import { generateDigitalSeal } from "@/lib/crypto-vault";

export type SaveAiAnalysisResult =
  | { success: true; id: string }
  | { success: false; error: string };

/**
 * Persist Gemini / Vision analysis as Markdown-shaped evidence (category `AI_ANALYSIS`)
 * with SHA-512 VETO digital seal when `VETO_PRIVATE_KEY` is set.
 */
export async function saveAiAnalysisAsFile(
  analysisText: string,
): Promise<SaveAiAnalysisResult> {
  const text = analysisText.trim();
  if (!text) {
    return { success: false, error: "אין טקסט ניתוח לשמירה" };
  }

  const iso = new Date().toISOString();
  const markdown = [
    "# VETO LEGAL ANALYSIS",
    "",
    "**Status:** Verified by VETO",
    "",
    `**Generated (ISO):** ${iso}`,
    "",
    "---",
    "",
    text,
    "",
  ].join("\n");

  let digitalSeal: string;
  try {
    digitalSeal = generateDigitalSeal(markdown, iso);
  } catch (e) {
    console.error("[ai-to-vault] seal failed:", e);
    return {
      success: false,
      error:
        "חותמת דיגיטלית לא זמינה — הגדר את VETO_PRIVATE_KEY בשרת (Vercel env).",
    };
  }

  const buf = Buffer.from(markdown, "utf8");
  const hash = createHash("sha256").update(buf).digest("hex");
  const b64 = buf.toString("base64");
  const url = `data:text/markdown;charset=utf-8;base64,${b64}`;

  const title = `AI Analysis — ${new Date().toLocaleString("he-IL", { hour12: false })}`;

  return saveEvidence({
    title,
    url,
    hash,
    category: "AI_ANALYSIS",
    isVerified: true,
    digitalSeal,
  });
}
