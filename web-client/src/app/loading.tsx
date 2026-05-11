"use client";

import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanel } from "@/lib/vetoGlass";

export default function RootLoading() {
  const { t, locale } = useTranslation();

  return (
    <div
      className="flex min-h-[40vh] w-full flex-col items-center justify-center px-4 py-20"
      aria-busy="true"
      aria-label={t("loadingPage.aria")}
      dir={locale === "he" ? "rtl" : "ltr"}
    >
      <div className="w-full max-w-sm space-y-4 text-center">
        <div className="flex justify-center">
          <VetoBrandLogo className="mx-auto h-10 w-auto sm:h-11" />
        </div>
        <p className="sr-only">{t("loadingPage.brand")}</p>
        <div
          className={`flex flex-col gap-4 p-6 shadow-lg shadow-slate-900/10 ${glassPanel}`}
        >
          <div className="flex animate-pulse flex-col gap-3 text-start">
            <div className="h-3 w-3/4 rounded-lg bg-white/[0.04]" />
            <div className="h-24 rounded-2xl bg-white/[0.03]" />
            <div className="h-14 rounded-2xl bg-white/[0.03]" />
          </div>
        </div>
      </div>
    </div>
  );
}
