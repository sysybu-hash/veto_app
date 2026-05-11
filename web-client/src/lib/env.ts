const DEFAULT_DEV_API_ORIGIN = "http://localhost:5001";

/**
 * API + Socket origin (no /api suffix). E.g. http://localhost:5001 or https://xxx.loca.lt
 *
 * In production (Vercel / `next start`), there is no localhost default — the browser would
 * call the *user's* machine (ERR_CONNECTION_REFUSED). Set NEXT_PUBLIC_API_ORIGIN to your
 * deployed API (e.g. https://your-service.onrender.com) and redeploy.
 */
export function getPublicApiOrigin(): string {
  const raw = process.env.NEXT_PUBLIC_API_ORIGIN?.trim();
  if (raw) {
    // Common misconfiguration: `https://host.onrender.com/api` breaks paths like `/api/calls/...`
    return raw.replace(/\/$/, "").replace(/\/api$/i, "");
  }
  if (process.env.NODE_ENV === "production") {
    return "";
  }
  return DEFAULT_DEV_API_ORIGIN;
}

/** False when production build omitted NEXT_PUBLIC_API_ORIGIN (misconfigured deploy). */
export function isApiOriginConfigured(): boolean {
  return getPublicApiOrigin().length > 0;
}

export function getPublicAgoraAppId(): string {
  return process.env.NEXT_PUBLIC_AGORA_APP_ID?.trim() ?? "";
}

/** True when the configured API host is a localtunnel subdomain. */
export function isLocaLtOrigin(): boolean {
  const o = getPublicApiOrigin();
  if (!o) return false;
  try {
    const u = new URL(o);
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
  if (!base) {
    throw new Error(
      "NEXT_PUBLIC_API_ORIGIN is not set. In Vercel → Environment Variables, set it to your backend origin (HTTPS, no /api suffix), then redeploy.",
    );
  }
  const p = path.startsWith("/") ? path : `/${path}`;
  return `${base}${p}`;
}
