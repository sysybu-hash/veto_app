import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Heebo } from "next/font/google";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import "./globals.css";

const heebo = Heebo({
  subsets: ["latin", "hebrew"],
  variable: "--font-heebo",
  display: "swap",
});

export const metadata: Metadata = {
  title: "VETO Web",
  description: "VETO legal — citizen, lawyer, and emergency call (web)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="he" dir="rtl" className={`${heebo.variable} h-full`}>
      <body className="font-sans min-h-screen antialiased text-slate-900 relative">
        {/* Courthouse background + blur */}
        <div
          className="fixed inset-0 -z-20 bg-cover bg-center"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1505664177922-99079a4db52a?q=80&w=2000')",
            filter: "blur(4px)",
          }}
          aria-hidden
        />
        <div className="fixed inset-0 -z-10 bg-white/75" aria-hidden />

        {/* Glow orbs */}
        <div
          className="fixed top-[-10%] left-[-10%] h-[50vw] w-[50vw] -z-10 animate-pulse rounded-full bg-blue-400/20 blur-[100px]"
          aria-hidden
        />
        <div
          className="fixed bottom-[-15%] right-[-10%] h-[45vw] w-[45vw] -z-10 animate-pulse rounded-full bg-indigo-400/15 blur-[120px] [animation-delay:1s]"
          aria-hidden
        />

        {children}
        <GlobalAiOverlay />
      </body>
    </html>
  );
}
