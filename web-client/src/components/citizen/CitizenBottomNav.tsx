"use client";

import Link from "next/link";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export type CitizenNavActive =
  | "hub"
  | "chat"
  | "vault"
  | "productivity"
  | "calendar"
  | "settings";

const linkBase =
  "relative flex min-w-0 flex-1 flex-col items-center gap-0.5 rounded-xl px-0.5 py-2 text-center sm:px-2";

const idle =
  "border-2 border-transparent text-slate-300 transition hover:bg-white/[0.06] hover:text-white sm:border-transparent";

const activeStyle =
  "relative border-2 border-[#C5A059] bg-[#C5A059]/20 text-[11px] font-bold text-[#C5A059] shadow-[0_0_22px_rgba(197,160,89,0.35)] sm:text-xs";

export function CitizenBottomNav({ active }: { active: CitizenNavActive }) {
  const { t } = useTranslation();

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-white/[0.06] bg-slate-950/70 px-1 py-2 backdrop-blur-xl supports-[backdrop-filter]:bg-slate-950/60 sm:px-3 sm:py-3">
      <div className="mx-auto flex max-w-lg justify-between gap-0.5 sm:gap-2">
        <Link
          href="/hub"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${active === "hub" ? activeStyle : idle}`}
        >
          <svg
            className={`mx-auto h-5 w-5 stroke-[1.75] sm:h-6 sm:w-6 ${
              active === "hub"
                ? "text-[#C5A059]"
                : "text-slate-400"
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M3 12l9-9 9 9M4 10v10a1 1 0 001 1h5v-6h4v6h5a1 1 0 001-1V10" />
          </svg>
          <span className="truncate">{t("navCitizen.home")}</span>
          {active === "hub" && (
            <span className="absolute -top-0.5 end-0 rounded-full bg-[#C5A059] px-1 text-[8px] font-bold text-slate-950 sm:end-0.5 sm:text-[9px]">
              {t("navCitizen.sosBadge")}
            </span>
          )}
        </Link>

        <Link
          href="/chat"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "chat" ? activeStyle : idle
          } ${active === "chat" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 stroke-[1.75] sm:h-6 sm:w-6 ${
              active === "chat" ? "text-[#C5A059]" : "text-slate-400"
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M21 15a4 4 0 01-4 4H8l-5 3V7a4 4 0 014-4h10a4 4 0 014 4v8z" />
          </svg>
          <span className="truncate">{t("navCitizen.chat")}</span>
        </Link>

        <Link
          href="/vault"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "vault" ? activeStyle : idle
          } ${active === "vault" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 stroke-[1.75] sm:h-6 sm:w-6 ${
              active === "vault" ? "text-[#C5A059]" : "text-slate-400"
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m0 0h-4M9 12h6M9 16h6" />
          </svg>
          <span className="truncate">{t("navCitizen.vault")}</span>
        </Link>

        <Link
          href="/calendar"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "calendar" ? activeStyle : idle
          } ${active === "calendar" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 stroke-[1.75] sm:h-6 sm:w-6 ${
              active === "calendar" ? "text-[#C5A059]" : "text-slate-400"
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <span className="truncate">{t("navCitizen.calendar")}</span>
        </Link>

        <Link
          href="/settings"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "settings" ? activeStyle : idle
          } ${active === "settings" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 stroke-[1.75] sm:h-6 sm:w-6 ${
              active === "settings" ? "text-[#C5A059]" : "text-slate-400"
            }`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span className="truncate">{t("navCitizen.settings")}</span>
        </Link>
      </div>
    </nav>
  );
}
