"use client";

import { WifiOff } from "lucide-react";

export default function OfflinePage() {
  return (
    <div
      className="flex min-h-screen flex-col items-center justify-center bg-veto-ink p-6 text-center text-white"
      dir="rtl"
    >
      <WifiOff size={64} className="mb-6 text-veto-gold opacity-80" />
      <h1 className="mb-4 text-3xl font-bold">אין חיבור לאינטרנט</h1>
      <p className="mb-8 max-w-md text-gray-400">
        המכשיר שלך כרגע לא מחובר לרשת. אנא ודא שהאינטרנט הסלולרי או ה-Wi-Fi
        פועלים כדי שנוכל לחבר אותך לעורך דין בזמן אמת.
      </p>
      <button
        type="button"
        onClick={() => window.location.reload()}
        className="rounded-full bg-veto-gold px-8 py-3 font-bold text-veto-ink"
      >
        נסה שוב
      </button>
    </div>
  );
}
