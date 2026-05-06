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
    <html lang="he" dir="rtl" className={`${heebo.variable} ${frank.variable} h-full`}>
      <body className="font-heebo min-h-screen overflow-x-hidden antialiased relative text-white">
        <div
          className="fixed inset-0 -z-20 bg-cover bg-center bg-no-repeat"
          style={{ backgroundImage: "url('/courtroom.jpg')" }}
          aria-hidden
        />
        <div
          className="fixed inset-0 -z-10 bg-linear-to-b from-black/60 via-black/20 to-black/80 pointer-events-none"
          aria-hidden
        />

        {children}
        <GlobalAiOverlay />
      </body>
    </html>
  );
}
