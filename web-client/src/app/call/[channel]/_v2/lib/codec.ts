/**
 * Codec selection for the Phase 3 call rewrite.
 *
 * Agora supports vp8 (universal), vp9 (better at the same bitrate), and av1
 * (best at the same bitrate, but heavier on the encoder and unsupported on
 * older Safari + low-end mobile). Pick the strongest codec the current
 * browser can publish reliably; fall back fast.
 */
export type AgoraCodec = "vp8" | "vp9" | "av1" | "h264";

export function pickPreferredCodec(): AgoraCodec {
  if (typeof window === "undefined") return "vp8";

  // Web Codecs API gives us a reliable signal for browser support.
  // Hard-rule: Safari iOS still struggles with VP9/AV1 publish, so detect.
  const ua = navigator.userAgent || "";
  const isSafari = /Safari/.test(ua) && !/Chrome|Chromium|Edg/.test(ua);
  const isMobile = /Mobi|Android|iPhone|iPad/.test(ua);

  if (isSafari) return isMobile ? "h264" : "vp8";

  // Chrome 116+ ships AV1 software encoder; Firefox 130+ does too.
  // We don't probe with VideoEncoder.isConfigSupported here because Agora
  // does its own negotiation — the codec passed at createClient is just a hint.
  const chromeMatch = ua.match(/Chrom(e|ium)\/(\d+)/);
  const chromeVersion = chromeMatch ? Number(chromeMatch[2]) : 0;
  if (chromeVersion >= 116) return "av1";

  const firefoxMatch = ua.match(/Firefox\/(\d+)/);
  const firefoxVersion = firefoxMatch ? Number(firefoxMatch[1]) : 0;
  if (firefoxVersion >= 130) return "vp9";

  return "vp8";
}

/**
 * Bitrate ladder for SOS legal calls — we optimise for clarity of speech +
 * face/document recognisability, not 4K.
 */
export const VIDEO_ENCODER_PROFILE = {
  width: 720,
  height: 540,
  frameRate: 24,
  bitrateMin: 400,
  bitrateMax: 1200,
} as const;
