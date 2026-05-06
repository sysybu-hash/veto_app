"use client";

import Link from "next/link";

export type CitizenNavActive = "hub" | "vault" | "productivity";

const linkBase =
  "relative flex flex-1 min-w-0 flex-col items-center gap-0.5 rounded-xl px-1 py-2 text-center sm:px-3";

const idle =
  "border-2 border-transparent text-slate-400 transition hover:bg-white/5 hover:text-white sm:border-transparent";

const activeStyle =
  "relative border-2 border-blue-500 bg-blue-600/20 text-xs font-semibold text-blue-100 shadow-[0_0_20px_rgba(37,99,235,0.35)]";

export function CitizenBottomNav({ active }: { active: CitizenNavActive }) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 border-t border-white/10 bg-slate-950/95 px-2 py-2 backdrop-blur-md sm:px-4 sm:py-3">
      <div className="mx-auto flex max-w-lg justify-center gap-1 sm:gap-3">
        <Link
          href="/hub"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "hub" ? activeStyle : idle
          }`}
        >
          <svg
            className={`mx-auto h-5 w-5 sm:h-6 sm:w-6 ${active === "hub" ? "text-blue-300" : ""}`}
            fill="none"
            stroke="currentColor"
            strokeWidth={1.75}
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M3 12l9-9 9 9M4 10v10a1 1 0 001 1h5v-6h4v6h5a1 1 0 001-1V10" />
          </svg>
          <span className="truncate sm:max-none">Home</span>
          {active === "hub" && (
            <span className="absolute -top-0.5 right-1 rounded-full bg-blue-500 px-1 text-[9px] font-bold text-white sm:right-2 sm:text-[10px]">
              SOS
            </span>
          )}
        </Link>

        <Link
          href="/vault"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "vault" ? activeStyle : idle
          } ${active === "vault" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 sm:h-6 sm:w-6 ${active === "vault" ? "text-blue-300" : "text-blue-400"}`}
            fill="none"
            stroke="currentColor"
            strokeWidth={1.75}
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m0 0h-4M9 12h6M9 16h6" />
          </svg>
          <span className="truncate">Vault</span>
          {active === "vault" && (
            <span className="absolute -top-0.5 right-1 rounded-full bg-blue-500 px-1 text-[9px] font-bold text-white sm:right-2 sm:px-1.5 sm:text-[10px]">
              Files
            </span>
          )}
        </Link>

        <Link
          href="/productivity"
          className={`${linkBase} text-[10px] font-medium sm:text-xs ${
            active === "productivity" ? activeStyle : idle
          } ${active === "productivity" ? "font-semibold" : ""}`}
        >
          <svg
            className={`mx-auto h-5 w-5 sm:h-6 sm:w-6 ${active === "productivity" ? "text-blue-300" : "text-blue-400"}`}
            fill="none"
            stroke="currentColor"
            strokeWidth={1.75}
            viewBox="0 0 24 24"
            aria-hidden
          >
            <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 012-2h2a2 2 0 012 2v0M9 5a2 2 0 012 2h2a2 2 0 012-2m-6 9h6m-6 4h6" />
          </svg>
          <span className="truncate">Work</span>
          {active === "productivity" && (
            <span className="absolute -top-0.5 right-1 rounded-full bg-blue-500 px-1 text-[9px] font-bold text-white sm:right-2 sm:px-1.5 sm:text-[10px]">
              Plan
            </span>
          )}
        </Link>
      </div>
    </nav>
  );
}
