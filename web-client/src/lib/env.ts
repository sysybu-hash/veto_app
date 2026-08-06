const DEFAULT_DEV_API_ORIGIN = "http://localhost:5001";
const DEV_PROXY_PREFIX = "/__api";

function normalizeApiOrigin(raw: string): string {
  return raw.replace(/\/$/, "").replace(/\/api$/i, "");
}

// NOT a React hook — must not be named `use*`, or eslint's rules-of-hooks
// treats every plain caller of getPublicApiOrigin() as an illegal hook call.
function shouldUseDevApiProxy(): boolean {
  if (process.env.NODE_ENV === "production") return false;
  // Opt out: NEXT_PUBLIC_API_USE_LOCAL_PROXY=0
  const flag = process.env.NEXT_PUBLIC_API_USE_LOCAL_PROXY?.trim();
  if (flag === "0" || flag === "false") return false;
  return true;
}

/**
 * API + Socket origin (no /api suffix). E.g. http://localhost:5001 or https://xxx.loca.lt
 *
 * - **Production build:** uses `NEXT_PUBLIC_API_ORIGIN` (must be your deployed API, e.g.
 *   https://your-service.onrender.com). Never leave localhost there for Vercel.
 * - **Development (`next dev`):** by default uses same-origin `/__api` (Next rewrite →
 *   `NEXT_PUBLIC_API_ORIGIN_DEV` / `NEXT_PUBLIC_API_ORIGIN`) so the browser avoids
 *   cross-origin failures when local API is down.
 */
export function getPublicApiOrigin(): string {
  const isDev = process.env.NODE_ENV !== "production";
  if (isDev && shouldUseDevApiProxy()) {
    if (typeof window !== "undefined") {
      return `${window.location.origin}${DEV_PROXY_PREFIX}`;
    }
    // SSR / route handlers in next dev — hit the rewrite host
    return `http://localhost:3000${DEV_PROXY_PREFIX}`;
  }

  let raw = "";
  if (isDev) {
    raw =
      process.env.NEXT_PUBLIC_API_ORIGIN_DEV?.trim() ||
      process.env.NEXT_PUBLIC_API_ORIGIN?.trim() ||
      "";
  } else {
    raw = process.env.NEXT_PUBLIC_API_ORIGIN?.trim() || "";
  }
  if (raw) {
    return normalizeApiOrigin(raw);
  }
  if (!isDev) {
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
  // Same-origin proxy is never loca.lt
  if (o.includes(DEV_PROXY_PREFIX)) return false;
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

export function getSiteUrl(): string {
  return process.env.NEXT_PUBLIC_SITE_URL?.trim().replace(/\/$/, "") ?? "";
}

export function getSupportEmail(): string {
  return process.env.NEXT_PUBLIC_SUPPORT_EMAIL?.trim() ?? "";
}

export function getSupportWhatsapp(): string {
  return process.env.NEXT_PUBLIC_SUPPORT_WHATSAPP?.trim().replace(/\D/g, "") ?? "";
}

export function getPostHogKey(): string {
  return process.env.NEXT_PUBLIC_POSTHOG_KEY?.trim() ?? "";
}

export function getPostHogHost(): string {
  return (
    process.env.NEXT_PUBLIC_POSTHOG_HOST?.trim().replace(/\/$/, "") ||
    "https://us.i.posthog.com"
  );
}

/** Server-side checklist of marketing / vault env (does not throw). */
export function listWebEnvGaps(): string[] {
  const gaps: string[] = [];
  const isProd = process.env.NODE_ENV === "production";
  if (isProd && !getPublicApiOrigin()) gaps.push("NEXT_PUBLIC_API_ORIGIN");
  if (isProd && !getSiteUrl()) gaps.push("NEXT_PUBLIC_SITE_URL");
  if (!process.env.DATABASE_URL?.trim()) gaps.push("DATABASE_URL");
  if (!process.env.ABLY_API_KEY?.trim()) gaps.push("ABLY_API_KEY");
  if (!getSupportEmail()) gaps.push("NEXT_PUBLIC_SUPPORT_EMAIL");
  if (!getPostHogKey()) gaps.push("NEXT_PUBLIC_POSTHOG_KEY (analytics deferred until set)");
  if (!process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID?.trim()) {
    gaps.push("NEXT_PUBLIC_PAYPAL_CLIENT_ID");
  }
  if (!process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY?.trim()) {
    gaps.push("NEXT_PUBLIC_VAPID_PUBLIC_KEY");
  }
  if (process.env.NEXT_PUBLIC_CALL_V2 === "0") {
    gaps.push("NEXT_PUBLIC_CALL_V2=0 (video calls disabled)");
  }
  if (!process.env.CRON_SECRET?.trim()) {
    gaps.push("CRON_SECRET (PENDING_DELIVERY retry unprotected)");
  }
  return gaps;
}
