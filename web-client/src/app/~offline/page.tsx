"use client";

import { WifiOff } from "lucide-react";
import { btnPrimaryGold } from "@/lib/vetoGlass";

export default function OfflinePage() {
  return (
    <div
      className="flex min-h-screen flex-col items-center justify-center bg-veto-ink p-6 text-center text-white"
      dir="rtl"
    >
      <WifiOff size={64} className="mb-6 text-veto-gold opacity-80" aria-hidden />
      <h1 className="mb-4 text-3xl font-bold">אין חיבור לאינטרנט</h1>
      <p className="mb-8 max-w-md text-slate-400">
        המכשיר שלך כרגע לא מחובר לרשת. אנא ודא שהאינטרנט הסלולרי או ה-Wi-Fi
        פועלים כדי שנוכל לחבר אותך לעורך דין בזמן אמת.
      </p>
      <button
        type="button"
        onClick={() => window.location.reload()}
        className={`min-h-[48px] px-10 py-3 text-base ${btnPrimaryGold}`}
      >
        נסה שוב
      </button>
    </div>
  );
}
