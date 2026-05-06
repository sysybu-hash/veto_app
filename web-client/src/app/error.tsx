"use client";

import { useEffect } from "react";
import { btnSecondaryGlass, glassPanel } from "@/lib/vetoGlass";

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("[VETO] route error:", error);
  }, [error]);

  return (
    <div
      className="flex min-h-[50vh] w-full flex-col items-center justify-center px-4 py-16"
      dir="rtl"
    >
      <div
        className={`w-full max-w-md space-y-4 p-8 text-center shadow-lg shadow-slate-900/10 ${glassPanel}`}
      >
        <h1 className="font-frank text-xl font-black text-slate-900">
          משהו השתבש
        </h1>
        <p className="text-sm leading-relaxed text-slate-700">
          נתקלנו בבעיה טכנית. אפשר לנסות שוב — הנתונים המאובטחים שלך בשרת לא
          הושפעו מכשל תצוגה זה.
        </p>
        {process.env.NODE_ENV === "development" && error.message ? (
          <pre className="max-h-32 overflow-auto rounded-lg border border-red-200/60 bg-red-50/80 p-3 text-start text-xs text-red-900">
            {error.message}
          </pre>
        ) : null}
        <button
          type="button"
          onClick={reset}
          className={`font-frank w-full py-3 text-sm font-bold ${btnSecondaryGlass}`}
        >
          נסה שוב
        </button>
      </div>
    </div>
  );
}
