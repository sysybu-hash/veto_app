import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { GlobalAiOverlay } from "@/components/ui/GlobalAiOverlay";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "VETO Web",
  description: "VETO legal — citizen, lawyer, and emergency call (web)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        {children}
        <GlobalAiOverlay />
      </body>
    </html>
  );
}
