import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { Frank_Ruhl_Libre, Heebo } from "next/font/google";
import { JwtCookieSync } from "@/components/providers/JwtCookieSync";
import { PwaRegistrar } from "@/components/providers/PwaRegistrar";
import { LocaleProvider } from "@/lib/i18n/LocaleProvider";
import { AiOverlayErrorBoundary } from "@/components/ui/AiOverlayErrorBoundary";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import { ToastHost } from "@/components/ui/ToastHost";
import { UniversalNav } from "@/components/navigation/UniversalNav";
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

export const metadata: Metadata = {
  applicationName: "VETO Legal",
  manifest: "/manifest.webmanifest",
  title: "VETO Signature 2027",
  description:
    "מערכת ההפעלה המשפטית הראשונה בישראל — הגנה מיידית, ניהול ראיות וחיבור למומחים.",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "VETO",
  },
  formatDetection: {
    telephone: true,
    email: false,
    address: false,
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#0f172a",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html
      lang="he"
      dir="rtl"
      suppressHydrationWarning
      className={`${heebo.variable} ${frank.variable} h-full`}
    >
      <body className="relative min-h-screen bg-transparent font-heebo text-slate-900 antialiased">
        <LocaleProvider>
          <PwaRegistrar />
          <JwtCookieSync />
          <ToastHost />
        <div className="fixed inset-0 -z-50 overflow-hidden" aria-hidden>
          <div className="absolute inset-0 bg-linear-to-b from-slate-100 via-white to-white" />
        </div>

        <div className="relative z-10 flex min-h-screen flex-col">
          <UniversalNav />
          <div className="flex min-h-0 flex-1 flex-col">
            {children}
          </div>
        </div>
        <AiOverlayErrorBoundary>
          <GlobalAiOverlay />
        </AiOverlayErrorBoundary>
        </LocaleProvider>
      </body>
    </html>
  );
}
