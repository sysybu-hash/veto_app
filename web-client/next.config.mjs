import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import withBundleAnalyzerFactory from "@next/bundle-analyzer";
import withPWAInit from "@ducanh2912/next-pwa";
import { withSentryConfig } from "@sentry/nextjs";

/** שורש `web-client` — מונע בחירת שורש שגוי כשיש כמה lockfiles (ראה Turbopack). */
const webClientRoot = dirname(fileURLToPath(import.meta.url));

// ⚠️ @ducanh2912/next-pwa hooks into webpack's config function only — it is a
// silent no-op under Turbopack (which Next.js 16 uses by default for `next build`).
// Without the service worker, `worker/index.ts`'s `push`/`notificationclick` handlers
// (SOS alert push notifications to lawyers) are never deployed. `package.json`'s
// `build` script MUST pass `--webpack` to `next build`, or the PWA layer silently
// stops shipping with every build — verify `public/sw.js` exists after `npm run build`.
const withPWA = withPWAInit({
  dest: "public",
  /** מיזוג לוגיקת Web Push לתוך ה-SW שנוצר ב-`/sw.js` */
  customWorkerSrc: "worker",
  disable: process.env.NODE_ENV === "development",
  // כבוי בכוונה (2026-07): cacheOnFrontEndNav/aggressiveFrontEndNavCaching שמרו גם את
  // ה-HTML/RSC של הניווט בצד-לקוח בקאש, לא רק נכסים סטטיים. תוצאה בפועל: טאב שנשאר
  // פתוח מעבר ל-deploy חדש קיבל HTML ישן (מפנה לנכס שכבר לא קיים) יחד עם JS חדש —
  // חוסר-התאמת hydration (React #418) + 404 על נכסים. skipWaiting/clientsClaim
  // (ברירת מחדל של הספרייה) מטפלים ב-JS/נכסים content-hashed; ניווטים עצמם עכשיו
  // תמיד פונים לרשת, כך שאין סיכון ל"HTML ישן + JS חדש" גם בטאב שנשאר פתוח זמן רב.
  cacheOnFrontEndNav: false,
  aggressiveFrontEndNavCaching: false,
  reloadOnOnline: true,
  /** דף App Router — `src/app/~offline/page.tsx` */
  fallbacks: {
    document: "/~offline",
  },
  workboxOptions: {
    disableDevLogs: true,
    // Full copy of @ducanh2912/next-pwa's default runtimeCaching (v10, see its
    // dist/index.js) with ONE change: the three routes that can carry a
    // *streamed* App Router response — the RSC payload (prefetch + normal)
    // and the HTML document itself — use NetworkOnly instead of NetworkFirst.
    // Root cause: NetworkFirst/Workbox must buffer the entire response body
    // to store a copy in cache, which consumes the stream before the browser
    // can progressively parse it. That silently breaks React's selective
    // hydration for whatever below-the-fold Suspense boundary hadn't
    // flushed yet — intermittently, depending on response timing — which is
    // exactly what was observed on /pricing: the PayPal checkout button
    // (mounted well below the fold) would randomly fail to hydrate on a
    // hard page load, roughly 50% of the time, with no console error at
    // all. Every other entry below (fonts, images, JS/CSS, non-streamed
    // JSON) is untouched and still safe to cache normally.
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/fonts\.(?:gstatic)\.com\/.*/i,
        handler: "CacheFirst",
        options: {
          cacheName: "google-fonts-webfonts",
          expiration: { maxEntries: 4, maxAgeSeconds: 31536000 },
        },
      },
      {
        urlPattern: /^https:\/\/fonts\.(?:googleapis)\.com\/.*/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "google-fonts-stylesheets",
          expiration: { maxEntries: 4, maxAgeSeconds: 604800 },
        },
      },
      {
        urlPattern: /\.(?:eot|otf|ttc|ttf|woff|woff2|font.css)$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "static-font-assets",
          expiration: { maxEntries: 4, maxAgeSeconds: 604800 },
        },
      },
      {
        urlPattern: /\.(?:jpg|jpeg|gif|png|svg|ico|webp)$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "static-image-assets",
          expiration: { maxEntries: 64, maxAgeSeconds: 2592000 },
        },
      },
      {
        urlPattern: /\/_next\/static.+\.js$/i,
        handler: "CacheFirst",
        options: {
          cacheName: "next-static-js-assets",
          expiration: { maxEntries: 64, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\/_next\/image\?url=.+$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "next-image",
          expiration: { maxEntries: 64, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\.(?:mp3|wav|ogg)$/i,
        handler: "CacheFirst",
        options: {
          rangeRequests: true,
          cacheName: "static-audio-assets",
          expiration: { maxEntries: 32, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\.(?:mp4|webm)$/i,
        handler: "CacheFirst",
        options: {
          rangeRequests: true,
          cacheName: "static-video-assets",
          expiration: { maxEntries: 32, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\.(?:js)$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "static-js-assets",
          expiration: { maxEntries: 48, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\.(?:css|less)$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "static-style-assets",
          expiration: { maxEntries: 32, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\/_next\/data\/.+\/.+\.json$/i,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "next-data",
          expiration: { maxEntries: 32, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: /\.(?:json|xml|csv)$/i,
        handler: "NetworkFirst",
        options: {
          cacheName: "static-data-assets",
          expiration: { maxEntries: 32, maxAgeSeconds: 86400 },
        },
      },
      {
        urlPattern: ({ sameOrigin, url: { pathname } }) =>
          !(!sameOrigin || pathname.startsWith("/api/auth/callback")) &&
          !!pathname.startsWith("/api/"),
        handler: "NetworkFirst",
        method: "GET",
        options: {
          cacheName: "apis",
          expiration: { maxEntries: 16, maxAgeSeconds: 86400 },
          networkTimeoutSeconds: 10,
        },
      },
      // --- streamed App Router responses: NetworkOnly, never buffered/cached ---
      {
        urlPattern: ({ request, url: { pathname }, sameOrigin }) =>
          request.headers.get("RSC") === "1" &&
          request.headers.get("Next-Router-Prefetch") === "1" &&
          sameOrigin &&
          !pathname.startsWith("/api/"),
        handler: "NetworkOnly",
      },
      {
        urlPattern: ({ request, url: { pathname }, sameOrigin }) =>
          request.headers.get("RSC") === "1" &&
          sameOrigin &&
          !pathname.startsWith("/api/"),
        handler: "NetworkOnly",
      },
      {
        urlPattern: ({ url: { pathname }, sameOrigin }) =>
          sameOrigin && !pathname.startsWith("/api/"),
        handler: "NetworkOnly",
      },
      // --- end streamed-response section ---
      {
        urlPattern: ({ sameOrigin }) => !sameOrigin,
        handler: "NetworkFirst",
        options: {
          cacheName: "cross-origin",
          expiration: { maxEntries: 32, maxAgeSeconds: 3600 },
          networkTimeoutSeconds: 10,
        },
      },
    ],
  },
});

/**
 * Bundle analyzer wrapper — `npm run analyze` sets `ANALYZE=true` and the
 * resulting client/server reports land in `.next/analyze/`. Useful for
 * Phase 4 verification that `agora-rtc-sdk-ng` and the AI Denoiser /
 * Virtual Background extensions live in the `/call/*` chunk only.
 */
const withBundleAnalyzer = withBundleAnalyzerFactory({
  enabled: process.env.ANALYZE === "true",
  openAnalyzer: false,
});

// path: web-client/next.config.mjs
/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    root: webClientRoot,
  },
  reactStrictMode: true,
  poweredByHeader: false,
  allowedDevOrigins: ["127.0.0.1", "localhost"],
  images: {
    formats: ["image/avif", "image/webp"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "res.cloudinary.com",
      },
      {
        protocol: "https",
        hostname: "lh3.googleusercontent.com",
      },
    ],
  },
  // ESLint בזמן build הוסר ב-Next 16 — הרץ `npm run lint` לפני build (ראה script `build` ב-package.json)
  typescript: {
    ignoreBuildErrors: false,
  },
  experimental: {
    optimizeCss: true,
  },
  async headers() {
    return [
      {
        source: "/sw.js",
        headers: [
          { key: "Content-Type", value: "application/javascript; charset=utf-8" },
          { key: "Cache-Control", value: "no-cache, no-store, must-revalidate" },
          { key: "Service-Worker-Allowed", value: "/" },
        ],
      },
      {
        source: "/manifest.webmanifest",
        headers: [
          { key: "Content-Type", value: "application/manifest+json; charset=utf-8" },
          { key: "Cache-Control", value: "public, max-age=3600" },
        ],
      },
      {
        source: "/icons/:path*",
        headers: [
          { key: "Cache-Control", value: "public, max-age=31536000, immutable" },
        ],
      },
    ];
  },
};

/** Sentry: קובצי sentry.*.config.ts בשורש web-client; DSN מ־SENTRY_DSN / NEXT_PUBLIC_SENTRY_DSN */
export default withSentryConfig(withBundleAnalyzer(withPWA(nextConfig)), {
  silent: true,
  widenClientFileUpload: true,
  hideSourceMaps: true,
});
