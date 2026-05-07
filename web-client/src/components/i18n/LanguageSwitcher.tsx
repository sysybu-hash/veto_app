"use client";

import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";
const ORDER = ["he", "en", "ru"] as const;

export function LanguageSwitcher() {
  const { locale, setLocale, t } = useTranslation();

  return (
    <div
      className={`${glassPanelNested} pointer-events-auto fixed right-4 top-4 z-[100] flex items-center gap-1 p-1 shadow-lg`}
      role="group"
      aria-label={t("language.label")}
    >
      {ORDER.map((code) => {
        const active = locale === code;
        const label =
          code === "he"
            ? t("language.he")
            : code === "en"
              ? t("language.en")
              : t("language.ru");
        return (
          <button
            key={code}
            type="button"
            onClick={() => setLocale(code)}
            aria-pressed={active}
            className={
              active
                ? "rounded-2xl bg-[#C5A059] px-3 py-1.5 text-xs font-black uppercase tracking-wide text-black shadow-sm"
                : "rounded-2xl px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-white/40"
            }
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
