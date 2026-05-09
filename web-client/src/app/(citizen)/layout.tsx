"use client";

import type { ReactNode } from "react";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export default function CitizenLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  const { t } = useTranslation();

  return (
    <div className="flex min-h-full flex-col text-slate-100">
      <header className="shrink-0 border-b border-white/10 bg-white/[0.05] px-4 py-3 backdrop-blur-xl">
        <div className="mx-auto flex max-w-lg items-center justify-between">
          <span className="font-frank text-sm font-bold tracking-tight text-slate-100">
            VETO
          </span>
          <span className="text-xs font-medium text-slate-400">
            {t("citizenLayout.subtitle")}
          </span>
        </div>
      </header>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}
