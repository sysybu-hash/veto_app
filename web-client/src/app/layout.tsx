import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Frank_Ruhl_Libre, Heebo } from "next/font/google";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import "./globals.css";

const heebo = Heebo({
  subsets: ["latin", "hebrew"],
  variable: "--font-heebo",
  display: "swap",
});

const frankRuhlLibre = Frank_Ruhl_Libre({
  subsets: ["latin", "hebrew"],
  variable: "--font-frank-ruhl",
  weight: ["400", "500", "600", "700"],
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
      className={`${heebo.variable} ${frankRuhlLibre.variable} h-full`}
    >
      <body className="font-sans min-h-screen antialiased text-slate-900 relative">
        <div
          className="fixed inset-0 -z-20 bg-cover bg-center bg-fixed"
          style={{ backgroundImage: "url('/courtroom.jpg')" }}
          aria-hidden
        />
        <div
          className="fixed inset-0 -z-10 bg-linear-to-b from-black/40 via-white/80 to-white pointer-events-none"
          aria-hidden
        />

        {children}
        <GlobalAiOverlay />
      </body>
    </html>
  );
}
