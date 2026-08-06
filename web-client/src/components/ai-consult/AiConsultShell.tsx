"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { AiDocumentDecodePanel } from "@/components/ai/AiDocumentDecodePanel";
import { DocumentGeneratorPanel } from "@/components/ai/DocumentGeneratorPanel";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { getRoleFromJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { citizenBottomSafe } from "@/lib/vetoGlass";
import { AiConsultChat, type AiConsultMode } from "./AiConsultChat";

const MODES: { id: AiConsultMode; labelKey: string }[] = [
  { id: "chat", labelKey: "aiConsult.modeChat" },
  { id: "decode", labelKey: "aiConsult.modeDecode" },
  { id: "generate", labelKey: "aiConsult.modeGenerate" },
];

export function AiConsultShell() {
  const { t } = useTranslation();
  const [mode, setMode] = useState<AiConsultMode>("chat");
  const [decodeError, setDecodeError] = useState<string | null>(null);
  const [role, setRole] = useState<string | null>(null);

  useEffect(() => {
    queueMicrotask(() => setRole(getRoleFromJwt()));
  }, []);

  const isLawyer = role === "lawyer" || role === "admin";
  const showCitizenNav = !isLawyer && role != null;
  const padClass = showCitizenNav || role == null ? citizenBottomSafe : "pb-8";

  return (
    <>
      {/* Not <main> — RoleAwareAppChrome (the /chat layout) owns that landmark. */}
      <div
        className={`relative min-h-[100dvh] bg-gradient-to-b from-zinc-100 via-white to-zinc-200/80 dark:from-zinc-950 dark:via-zinc-950 dark:to-zinc-900 ${padClass}`}
      >
        <div
          className="pointer-events-none absolute inset-0 opacity-40 dark:opacity-30"
          style={{
            backgroundImage:
              "radial-gradient(ellipse 80% 50% at 50% -10%, rgba(197,160,89,0.18), transparent 55%)",
          }}
          aria-hidden
        />

        <div className="relative mx-auto flex min-h-[100dvh] w-full max-w-3xl flex-col px-4 pt-5 sm:px-6 sm:pt-6 md:min-h-[calc(100dvh-4rem)] md:pb-6">
          <header className="shrink-0 pb-4">
            {isLawyer ? (
              <Link
                href="/dashboard"
                className="mb-3 inline-block text-sm font-bold text-brand-700 hover:underline dark:text-brand-text"
              >
                ← {t("nav.dashboard")}
              </Link>
            ) : null}
            <h1 className="font-frank text-3xl font-black tracking-tight text-primary sm:text-4xl">
              {t("aiConsult.title")}
            </h1>
            <p className="mt-1 text-sm font-medium text-secondary">
              {t("aiConsult.subtitle")}
            </p>

            <div
              className="mt-5 flex gap-1.5 rounded-2xl border border-black/8 bg-white/70 p-1 shadow-sm backdrop-blur-md dark:border-white/10 dark:bg-zinc-900/60"
              role="tablist"
              aria-label={t("aiConsult.modesAria")}
            >
              {MODES.map((tab) => {
                const selected = mode === tab.id;
                return (
                  <button
                    key={tab.id}
                    type="button"
                    role="tab"
                    aria-selected={selected}
                    onClick={() => {
                      setDecodeError(null);
                      setMode(tab.id);
                    }}
                    className={`flex-1 rounded-xl px-3 py-2.5 text-sm font-black transition ${
                      selected
                        ? "bg-veto-gold text-zinc-950 shadow-sm"
                        : "text-secondary hover:bg-black/[0.04] hover:text-primary dark:hover:bg-white/[0.06]"
                    }`}
                  >
                    {t(tab.labelKey)}
                  </button>
                );
              })}
            </div>
          </header>

          <section className="flex min-h-0 flex-1 flex-col">
            {mode === "chat" ? (
              <AiConsultChat onSwitchMode={setMode} />
            ) : null}

            {mode === "decode" ? (
              <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-2xl border border-black/8 bg-white/80 shadow-sm dark:border-white/10 dark:bg-zinc-900/50">
                {decodeError ? (
                  <p className="border-b border-amber-300/80 bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-950 dark:border-amber-500/40 dark:bg-amber-950/40 dark:text-amber-100">
                    {decodeError}
                  </p>
                ) : null}
                <AiDocumentDecodePanel
                  active={mode === "decode"}
                  className="flex-1"
                  onSignInRequired={() => setDecodeError(t("ai.signInBanner"))}
                />
              </div>
            ) : null}

            {mode === "generate" ? (
              <div className="min-h-0 flex-1 overflow-hidden rounded-2xl border border-black/8 bg-white/80 shadow-sm dark:border-white/10 dark:bg-zinc-900/50">
                <DocumentGeneratorPanel variant="embedded" />
              </div>
            ) : null}
          </section>
        </div>
      </div>
      {showCitizenNav ? <CitizenBottomNav active="chat" /> : null}
    </>
  );
}
