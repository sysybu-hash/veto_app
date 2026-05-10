/**
 * Client-side End-to-End Encryption key derivation.
 *
 * Both peers derive the same `aes-256-gcm2` key + salt from the eventId and
 * the per-event `e2ee_secret` issued by the server (delivered in `session_ready`
 * and GET /api/calls/:id for authorized participants). This is independent of
 * JWT lifetime so encryption stays stable for the whole call.
 *
 * The derived key never leaves the client — the server only stores the random
 * secret and sees encrypted media on the wire, per Agora E2EE design.
 */

const ENCODER = new TextEncoder();

async function sha256(input: string): Promise<Uint8Array> {
  const buf = await crypto.subtle.digest("SHA-256", ENCODER.encode(input));
  return new Uint8Array(buf);
}

export type E2EEMaterial = {
  /** 32-byte key for aes-256-gcm2. */
  key: Uint8Array;
  /** 16-byte salt; Agora requires exactly 16 bytes. */
  salt: Uint8Array;
};

/**
 * Derive a stable key+salt pair from the eventId + server-issued `e2eeSecret`
 * (64-char hex from `crypto.randomBytes(32)` on the backend).
 */
export async function deriveE2EEMaterial(
  eventId: string,
  e2eeSecret: string,
): Promise<E2EEMaterial> {
  if (!eventId) throw new Error("E2EE: eventId required");
  if (!e2eeSecret || !e2eeSecret.trim()) {
    throw new Error("E2EE: e2eeSecret required");
  }

  const secret = e2eeSecret.trim();
  const key = await sha256(`veto-e2ee-key:${eventId}:${secret}`);
  const saltFull = await sha256(`veto-e2ee-salt:${eventId}:${secret}`);
  const salt = saltFull.slice(0, 16);

  return { key, salt };
}

/** Truthy when the platform supports Insertable Streams (required for E2EE). */
export function isE2EESupported(): boolean {
  if (typeof window === "undefined") return false;
  // RTCRtpScriptTransform (newer) OR RTCRtpSender.createEncodedStreams (older Chromium).
  const w = window as unknown as {
    RTCRtpScriptTransform?: unknown;
    RTCRtpSender?: { prototype?: { createEncodedStreams?: unknown } };
  };
  return Boolean(
    w.RTCRtpScriptTransform || w.RTCRtpSender?.prototype?.createEncodedStreams,
  );
}
