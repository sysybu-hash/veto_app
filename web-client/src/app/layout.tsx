import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { cookies } from "next/headers";
import { Frank_Ruhl_Libre, Heebo } from "next/font/google";
import { JwtCookieSync } from "@/components/providers/JwtCookieSync";
import {
  THEME_COOKIE,
  ThemeProvider,
  themeBootstrapScript,
} from "@/components/providers/ThemeProvider";
import { LocaleProvider } from "@/lib/i18n/LocaleProvider";
import { AiOverlayErrorBoundary } from "@/components/ui/AiOverlayErrorBoundary";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import { MotionPreferences } from "@/components/ui/MotionPreferences";
import { ToastHost } from "@/components/ui/ToastHost";
import { UniversalNav } from "@/components/navigation/UniversalNav";
import { CookieConsent } from "@/components/privacy/CookieConsent";
import { PostHogAnalytics } from "@/components/privacy/PostHogAnalytics";
import { getPostHogHost, getPostHogKey } from "@/lib/env";
import "./globals.css";

const heebo = Heebo({
  subsets: ["latin", "hebrew"],
  variable: "--font-heebo",
  display: "swap",
});

const frank = Frank_Ruhl_Libre({
  subsets: ["latin", "hebrew"],
  weight: ["700", "900"],
  variable: "--font-frank",
  display: "swap",
});

const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL || "https://veto.legal").replace(/\/$/, "");

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  applicationName: "VETO Legal",
  manifest: "/manifest.webmanifest",
  title: {
    default: "VETO Legal OS",
    template: "%s | VETO",
  },
  description:
    "מערכת הפעלה משפטית: SOS לעורך דין, כספת ראיות, מחולל מסמכים ומנויים למשפחות ואזרחים.",
  alternates: {
    canonical: siteUrl,
  },
  verification: {
    google: process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION,
  },
  openGraph: {
    type: "website",
    url: siteUrl,
    siteName: "VETO Legal",
    title: "VETO Legal OS",
    description: "SOS לעורך דין, כספת ראיות, מחולל מסמכים ומנויים במקום אחד.",
    images: [{ url: "/courtroom.jpg", width: 1200, height: 630, alt: "VETO Legal OS" }],
    locale: "he_IL",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "VETO Legal",
  },
  formatDetection: {
    telephone: true,
    email: false,
    address: false,
  },
  icons: {
    icon: [
      { url: "/veto-brand.png?v=20260511", type: "image/png", sizes: "985x1024" },
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#0a0a0f",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  const cookieStore = await cookies();
  const themePref = cookieStore.get(THEME_COOKIE)?.value;
  const themeClass =
    themePref === "dark" ? "veto-dark" : "veto-light";

  const orgJsonLd = {
    "@context": "https://schema.org",
    "@type": "LegalService",
    name: "VETO Legal",
    url: siteUrl,
    areaServed: "IL",
    serviceType: "Legal technology and lawyer dispatch",
  };

  return (
    <html
      lang="he"
      dir="rtl"
      suppressHydrationWarning
      className={`${heebo.variable} ${frank.variable} h-full ${themeClass}`}
    >
      <head>
        {/*
          Run before paint to apply the persisted (or system) theme
          via .veto-light / .veto-dark. Avoids flash of wrong theme.
        */}
        <script
          suppressHydrationWarning
          dangerouslySetInnerHTML={{ __html: themeBootstrapScript }}
        />
      </head>
      <body
        suppressHydrationWarning
        className={`${themeClass} relative min-h-screen bg-[#eef1f5] font-heebo text-primary antialiased dark:bg-[#0f172a] dark:text-slate-100`}
      >
        <ThemeProvider>
          <MotionPreferences>
          <LocaleProvider>
            <JwtCookieSync />
            <ToastHost />
            <script
              type="application/ld+json"
              suppressHydrationWarning
              dangerouslySetInnerHTML={{ __html: JSON.stringify(orgJsonLd) }}
            />
            <div className="fixed inset-0 -z-50 overflow-hidden" aria-hidden>
              <div className="veto-page-underlay absolute inset-0 bg-surface-canvas" />
              <div className="veto-bg-glow absolute inset-0" />
              <div className="veto-bg-grid absolute inset-0" />
            </div>

            <div className="relative z-10 flex min-h-screen flex-col">
              <UniversalNav />
              <div className="flex min-h-0 flex-1 flex-col">{children}</div>
              {/* Rendered inside this stacking context (not as a body-level
                  sibling) so its z-[70] is compared against in-page dialogs'
                  actual z-index (80/95/etc.) instead of this wrapper's z-10 —
                  otherwise the banner visually/interactively sits above every
                  modal regardless of the modal's own stacking value. */}
              <CookieConsent />
              <PostHogAnalytics
                apiKey={getPostHogKey()}
                apiHost={getPostHogHost()}
              />
            </div>
            <AiOverlayErrorBoundary>
              <GlobalAiOverlay />
            </AiOverlayErrorBoundary>
          </LocaleProvider>
          </MotionPreferences>
        </ThemeProvider>
      </body>
    </html>
  );
}
