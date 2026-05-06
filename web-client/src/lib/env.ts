/**
 * API + Socket origin (no /api suffix). E.g. http://localhost:5001 or https://xxx.loca.lt
 */
export function getPublicApiOrigin(): string {
  const raw = process.env.NEXT_PUBLIC_API_ORIGIN?.trim();
  if (!raw) {
    return "http://localhost:5001";
  }
  return raw.replace(/\/$/, "");
}

export function getPublicAgoraAppId(): string {
  return process.env.NEXT_PUBLIC_AGORA_APP_ID?.trim() ?? "";
}

/** True when the configured API host is a localtunnel subdomain. */
export function isLocaLtOrigin(): boolean {
  try {
    const u = new URL(getPublicApiOrigin());
    return u.hostname.endsWith("loca.lt");
  } catch {
    return false;
  }
}

/**
 * Headers required for HTTP requests through localtunnel (browser fetch).
 * WebSocket cannot set arbitrary headers; socket.io polling may send these on XHR.
 */
export function tunnelBypassHeaders(): Record<string, string> {
  if (!isLocaLtOrigin()) return {};
  return { "bypass-tunnel-reminder": "true" };
}

export function apiUrl(path: string): string {
  const base = getPublicApiOrigin();
  const p = path.startsWith("/") ? path : `/${path}`;
  return `${base}${p}`;
}
