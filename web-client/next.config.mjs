import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

/** שורש `web-client` — מונע בחירת שורש שגוי כשיש כמה lockfiles (ראה Turbopack). */
const webClientRoot = dirname(fileURLToPath(import.meta.url));

// path: web-client/next.config.mjs
/** @type {import('next').NextConfig} */
const nextConfig = {
  turbopack: {
    root: webClientRoot,
  },
  reactStrictMode: true,
  poweredByHeader: false,
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
        source: "/custom-sw.js",
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
export default nextConfig;
