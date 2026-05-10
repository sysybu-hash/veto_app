"use client";

import { useEffect, useRef, useState } from "react";
import { apiUrl, authFetch } from "@/api/apiClient";
import type { TranscriptSegment } from "./useRealtimeTranscription";

type Locale = "he" | "en" | "ru" | "ar";

const LANG_FAMILY: Record<string, Locale> = {
  he: "he",
  iw: "he",
  "he-il": "he",
  en: "en",
  "en-us": "en",
  "en-gb": "en",
  ru: "ru",
  "ru-ru": "ru",
  ar: "ar",
};

function detectFamily(lang: string | null): Locale | null {
  if (!lang) return null;
  const norm = lang.trim().toLowerCase();
  if (LANG_FAMILY[norm]) return LANG_FAMILY[norm];
  const short = norm.split(/[-_]/)[0];
  return LANG_FAMILY[short] ?? null;
}

/**
 * For each *final* transcript segment whose detected language differs from
 * the viewer's preferred locale, request a translation from `/api/ai/translate-segments`.
 *
 * Translations are cached by segmentId so we never re-call Gemini for the
 * same line. Interim segments aren't translated — we only translate finals
 * to keep cost bounded.
 *
 * Returns a map of segmentId → translated text. The caller is expected to
 * render `segment.text` (original) plus, when available, the translation.
 */
export function useCaptionsTranslation({
  segments,
  enabled,
  targetLang,
}: {
  segments: TranscriptSegment[];
  enabled: boolean;
  targetLang: Locale;
}) {
  const [translations, setTranslations] = useState<Record<string, string>>({});
  const inflightRef = useRef<Set<string>>(new Set());
  const failedRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    if (!enabled) return;
    const pending = segments.filter((seg) => {
      if (!seg.isFinal) return false;
      if (translations[seg.segmentId]) return false;
      if (inflightRef.current.has(seg.segmentId)) return false;
      if (failedRef.current.has(seg.segmentId)) return false;
      const fam = detectFamily(seg.lang);
      // If we can't detect, still translate as a safety net so the lawyer
      // never reads gibberish in the wrong script.
      if (fam && fam === targetLang) return false;
      return seg.text.trim().length > 0;
    });
    if (pending.length === 0) return;

    // Dedupe: take a small batch (Agora pushes ~1 final per ~3-5 sec).
    const batch = pending.slice(0, 25);
    batch.forEach((s) => inflightRef.current.add(s.segmentId));

    let cancelled = false;
    void (async () => {
      try {
        const res = await authFetch(apiUrl("/api/ai/translate-segments"), {
          method: "POST",
          body: JSON.stringify({
            segments: batch.map((s) => s.text),
            targetLang,
          }),
        });
        if (!res.ok) {
          batch.forEach((s) => failedRef.current.add(s.segmentId));
          return;
        }
        const data = (await res.json()) as { translations?: (string | null)[] };
        if (cancelled) return;
        const next: Record<string, string> = {};
        batch.forEach((seg, i) => {
          const t = data.translations?.[i];
          if (typeof t === "string" && t.trim().length > 0) {
            next[seg.segmentId] = t.trim();
          } else {
            failedRef.current.add(seg.segmentId);
          }
        });
        setTranslations((prev) =>
          Object.keys(next).length === 0 ? prev : { ...prev, ...next },
        );
      } catch {
        batch.forEach((s) => failedRef.current.add(s.segmentId));
      } finally {
        batch.forEach((s) => inflightRef.current.delete(s.segmentId));
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [segments, enabled, targetLang, translations]);

  return translations;
}
