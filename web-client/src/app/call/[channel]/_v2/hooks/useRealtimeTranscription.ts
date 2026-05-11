"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { IAgoraRTCClient } from "agora-rtc-sdk-ng";
import { apiUrl, authFetch } from "@/api/apiClient";

export type TranscriptSegment = {
  segmentId: string;
  speaker: string | null;
  speakerUid: number | null;
  text: string;
  lang: string | null;
  ts: number;
  isFinal: boolean;
};

type RttStatus = "idle" | "starting" | "running" | "stopping" | "stopped" | "error";

function pickString(
  obj: Record<string, unknown>,
  keys: string[],
): string | null {
  for (const k of keys) {
    const v = obj[k];
    if (typeof v === "string" && v.trim()) return v;
  }
  return null;
}

function pickBoolean(
  obj: Record<string, unknown>,
  keys: string[],
): boolean | undefined {
  for (const k of keys) {
    const v = obj[k];
    if (typeof v === "boolean") return v;
  }
  return undefined;
}

function pickNumber(
  obj: Record<string, unknown>,
  keys: string[],
): number | null {
  for (const k of keys) {
    const v = obj[k];
    if (typeof v === "number" && Number.isFinite(v)) return v;
  }
  return null;
}

/**
 * Normalize Agora RTSC / STT stream payloads (shape varies by API version).
 * Returns a TranscriptSegment or null if nothing usable was found.
 */
function segmentFromRttPayload(
  raw: Record<string, unknown>,
  streamSenderUid: string | number,
): TranscriptSegment | null {
  const unwrapKeys = ["data", "payload", "result", "transcription", "recognizeResult"];
  for (const k of unwrapKeys) {
    const inner = raw[k];
    if (inner && typeof inner === "object" && !Array.isArray(inner)) {
      const nested = segmentFromRttPayload(
        inner as Record<string, unknown>,
        streamSenderUid,
      );
      if (nested) return nested;
    }
  }

  const text = pickString(raw, [
    "text",
    "transcript",
    "content",
    "msg",
    "message",
    "caption",
  ]);
  if (!text?.trim()) return null;

  const segmentId =
    pickString(raw, [
      "segmentId",
      "segment_id",
      "id",
      "msgId",
      "messageId",
      "utteranceId",
    ]) ?? `rtt-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;

  const isFinal = pickBoolean(raw, ["isFinal", "is_final", "final", "definite"]) ?? false;

  const lang = pickString(raw, ["lang", "language", "locale", "detectedLanguage"]);

  const speaker = pickString(raw, ["speaker", "speakerLabel", "speaker_name"]);

  let speakerUid = pickNumber(raw, ["speakerUid", "speaker_uid", "uid", "userId"]);
  if (speakerUid == null) {
    const u = streamSenderUid;
    speakerUid = typeof u === "number" ? u : /^\d+$/.test(String(u)) ? Number(u) : null;
  }

  const ts =
    pickNumber(raw, ["ts", "timestamp", "time", "endTs", "end_time"]) ?? Date.now();

  return {
    segmentId,
    speaker,
    speakerUid,
    text: text.trim(),
    lang,
    ts,
    isFinal,
  };
}

function parseStreamPayload(
  decoded: string,
  streamSenderUid: string | number,
): TranscriptSegment | null {
  const trimmed = decoded.trim();
  if (!trimmed) return null;

  try {
    const parsed: unknown = JSON.parse(trimmed);
    if (Array.isArray(parsed)) {
      const last = parsed[parsed.length - 1];
      if (last && typeof last === "object") {
        return segmentFromRttPayload(last as Record<string, unknown>, streamSenderUid);
      }
      return null;
    }
    if (parsed && typeof parsed === "object") {
      return segmentFromRttPayload(parsed as Record<string, unknown>, streamSenderUid);
    }
  } catch {
    // Not JSON — treat whole string as a final caption line
    return {
      segmentId: `rtt-raw-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      speaker: null,
      speakerUid:
        typeof streamSenderUid === "number"
          ? streamSenderUid
          : /^\d+$/.test(String(streamSenderUid))
            ? Number(streamSenderUid)
            : null,
      text: trimmed,
      lang: null,
      ts: Date.now(),
      isFinal: true,
    };
  }
  return null;
}

function toUint8Array(data: unknown): Uint8Array | null {
  if (data instanceof Uint8Array) return data;
  if (data instanceof ArrayBuffer) return new Uint8Array(data);
  if (ArrayBuffer.isView(data)) {
    return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
  }
  return null;
}

/**
 * Drives Agora Real-Time Transcription for the call.
 *
 * Only one party should call `start()` — by convention the citizen does it
 * the first time (the toggle in ControlBar is hidden for the lawyer until
 * RTT is running locally / both receive `stream-message` from the channel).
 *
 * Live segments arrive on the Agora RTC client via `stream-message` (RTT bot
 * injects transcription into the channel data stream).
 */
export function useRealtimeTranscription(
  eventId: string | null,
  agoraClient: IAgoraRTCClient | null,
) {
  const [status, setStatus] = useState<RttStatus>("idle");
  const [segments, setSegments] = useState<TranscriptSegment[]>([]);
  const [error, setError] = useState<string | null>(null);
  const localTaskRef = useRef<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    queueMicrotask(() => {
      if (!cancelled) setSegments([]);
    });
    return () => {
      cancelled = true;
    };
  }, [eventId]);

  const start = useCallback(async () => {
    if (!eventId) return;
    setStatus("starting");
    setError(null);
    try {
      const res = await authFetch(
        apiUrl(`/api/calls/${eventId}/transcript-realtime/start`),
        { method: "POST" },
      );
      if (!res.ok) {
        setStatus("error");
        setError(`RTT start failed (${res.status})`);
        return;
      }
      const data = (await res.json()) as { taskId?: string };
      if (data.taskId) localTaskRef.current = data.taskId;
      setStatus("running");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    }
  }, [eventId]);

  const stop = useCallback(async () => {
    if (!eventId) return;
    setStatus("stopping");
    try {
      const res = await authFetch(
        apiUrl(`/api/calls/${eventId}/transcript-realtime/stop`),
        { method: "POST" },
      );
      setStatus(res.ok ? "stopped" : "error");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : String(err));
    }
  }, [eventId]);

  useEffect(() => {
    if (!agoraClient) return undefined;

    // Agora may emit `(uid, data)` or `(uid, streamId, data)` depending on SDK version.
    const handleStreamMessage = (uid: string | number, a?: unknown, b?: unknown) => {
      try {
        const payload = b !== undefined ? b : a;
        const bytes = toUint8Array(payload);
        if (!bytes || bytes.length === 0) return;

        const textDecoder = new TextDecoder("utf-8");
        const decodedText = textDecoder.decode(bytes);

        const seg = parseStreamPayload(decodedText, uid);
        if (!seg) return;

        setSegments((prev) => {
          const idx = prev.findIndex((s) => s.segmentId === seg.segmentId);
          if (idx === -1) return [...prev, seg];
          const next = prev.slice();
          next[idx] = seg;
          return next;
        });
      } catch (err) {
        console.error("[RTT] Error decoding Agora stream message:", err);
      }
    };

    agoraClient.on("stream-message", handleStreamMessage);

    return () => {
      agoraClient.off("stream-message", handleStreamMessage);
    };
  }, [agoraClient]);

  return { status, segments, error, start, stop };
}
