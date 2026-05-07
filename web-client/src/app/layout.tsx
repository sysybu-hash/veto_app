import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Frank_Ruhl_Libre, Heebo } from "next/font/google";
import { LanguageSwitcher } from "@/components/i18n/LanguageSwitcher";
import { JwtCookieSync } from "@/components/providers/JwtCookieSync";
import { LocaleProvider } from "@/lib/i18n/LocaleProvider";
import { AiOverlayErrorBoundary } from "@/components/ui/AiOverlayErrorBoundary";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import { ToastHost } from "@/components/ui/ToastHost";
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
  title: "VETO Signature 2027",
  description:
    "מערכת ההפעלה המשפטית הראשונה בישראל — הגנה מיידית, ניהול ראיות וחיבור למומחים.",
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
          <LanguageSwitcher />
          <JwtCookieSync />
          <ToastHost />
        <div className="fixed inset-0 -z-50 overflow-hidden" aria-hidden>
          <div
            className="absolute inset-0 scale-105 bg-cover bg-center bg-no-repeat"
            style={{ backgroundImage: "url('/courtroom.jpg')" }}
          />
          <div className="absolute inset-0 bg-linear-to-b from-black/70 via-white/40 to-white/95" />
        </div>

        <div className="relative z-10 min-h-screen">
          {children}
        </div>
        <AiOverlayErrorBoundary>
          <GlobalAiOverlay />
        </AiOverlayErrorBoundary>
        </LocaleProvider>
      </body>
    </html>
  );
}
