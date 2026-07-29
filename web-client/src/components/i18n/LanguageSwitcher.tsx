"use client";

import { useEffect, useRef, useState } from "react";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";
const ORDER = ["he", "en", "ru"] as const;

export function LanguageSwitcher({ className = "" }: { className?: string }) {
  const { locale, setLocale, t } = useTranslation();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;

    const onPointerDown = (event: MouseEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    };

    const onEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setOpen(false);
      }
    };

    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onEscape);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onEscape);
    };
  }, [open]);

  const currentLabel =
    locale === "he"
      ? t("language.he")
      : locale === "en"
        ? t("language.en")
        : t("language.ru");

  return (
    <div
      ref={rootRef}
      className={`pointer-events-auto relative z-[100] w-fit ${className}`}
    >
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        aria-haspopup="menu"
        aria-label={t("language.label")}
        className={`${glassPanelNested} flex min-w-[108px] items-center justify-between gap-2 px-3 py-2 text-xs font-semibold text-primary shadow-lg transition hover:bg-slate-50/90 dark:text-slate-100 dark:hover:bg-white/8`}
      >
        <span className="truncate">{currentLabel}</span>
        <svg
          aria-hidden
          viewBox="0 0 20 20"
          className={`h-4 w-4 shrink-0 transition-transform ${open ? "rotate-180" : ""}`}
        >
          <path
            d="M5 7.5l5 5 5-5"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </button>

      {open && (
        <div
          role="menu"
          aria-label={t("language.label")}
          className={`${glassPanelNested} absolute end-0 mt-2 flex min-w-[140px] flex-col gap-1 p-1 shadow-lg`}
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
                role="menuitemradio"
                aria-checked={active}
                onClick={() => {
                  setLocale(code);
                  setOpen(false);
                }}
                className={
                  active
                    ? "rounded-2xl bg-veto-gold px-3 py-2 text-start text-xs font-black text-on-brand shadow-sm"
                    : "rounded-2xl px-3 py-2 text-start text-xs font-semibold text-secondary transition hover:bg-hover-overlay"
                }
              >
                {label}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
