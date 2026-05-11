"use client";

import { useEffect } from "react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { btnSecondaryGlass, glassPanel } from "@/lib/vetoGlass";

export default function AppError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { t, locale } = useTranslation();

  useEffect(() => {
    console.error("[VETO] route error:", error);
  }, [error]);

  return (
    <div
      className="pointer-events-auto flex min-h-[50vh] w-full flex-col items-center justify-center px-4 py-16"
      dir={locale === "he" ? "rtl" : "ltr"}
    >
      <div
        className={`w-full max-w-md space-y-4 p-8 text-center shadow-lg shadow-slate-900/10 ${glassPanel}`}
      >
        <div className="flex justify-center">
          <VetoBrandLogo className="h-9 w-auto" />
        </div>
        <h1 className="font-frank text-xl font-black text-slate-100">
          {t("errorPage.title")}
        </h1>
        <p className="text-sm leading-relaxed text-slate-300">
          {t("errorPage.body")}
        </p>
        {process.env.NODE_ENV === "development" && error.message ? (
          <pre className="max-h-32 overflow-auto rounded-lg border border-red-500/40 bg-red-500/10 p-3 text-start text-xs text-red-200">
            {error.message}
          </pre>
        ) : null}
        <button
          type="button"
          onClick={reset}
          className={`font-frank w-full py-3 text-sm font-bold ${btnSecondaryGlass}`}
        >
          {t("errorPage.retry")}
        </button>
      </div>
    </div>
  );
}
