"use client";

import Link from "next/link";
import { LanguageSwitcher } from "@/components/i18n/LanguageSwitcher";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export default function Home() {
  const { t } = useTranslation();
  const heroSubtitle = t("home.heroSubtitle");
  const heroSubtitleBreakAt = heroSubtitle.indexOf(". ");
  const heroSubtitleLine1 =
    heroSubtitleBreakAt > -1
      ? `${heroSubtitle.slice(0, heroSubtitleBreakAt + 1)}`
      : heroSubtitle;
  const heroSubtitleLine2 =
    heroSubtitleBreakAt > -1
      ? heroSubtitle.slice(heroSubtitleBreakAt + 2)
      : "";

  const bento = [
    {
      title: t("home.bentoEmergencyTitle"),
      desc: t("home.bentoEmergencyDesc"),
      tag: t("home.bentoEmergencyTag"),
    },
    {
      title: t("home.bentoVaultTitle"),
      desc: t("home.bentoVaultDesc"),
      tag: t("home.bentoVaultTag"),
    },
    {
      title: t("home.bentoDocGenTitle"),
      desc: t("home.bentoDocGenDesc"),
      tag: t("home.bentoDocGenTag"),
    },
    {
      title: t("home.bentoContractsTitle"),
      desc: t("home.bentoContractsDesc"),
      tag: t("home.bentoContractsTag"),
    },
    {
      title: t("home.bentoCalendarTitle"),
      desc: t("home.bentoCalendarDesc"),
      tag: t("home.bentoCalendarTag"),
    },
    {
      title: t("home.bentoNetworkTitle"),
      desc: t("home.bentoNetworkDesc"),
      tag: t("home.bentoNetworkTag"),
    },
  ] as const;

  return (
    <div className="relative flex min-h-screen flex-col text-slate-100">
      <nav className="relative z-10 border-b border-white/5">
        <div className="container mx-auto flex items-center justify-between px-6 py-5">
          <img
            src="/veto-logo.svg"
            alt="VETO"
            className="h-8 w-auto select-none"
            draggable={false}
          />

          <div className="hidden items-center gap-10 text-sm font-semibold text-slate-300 md:flex">
            <a href="#" className="transition-colors hover:text-[#C5A059]">
              {t("home.navSystem")}
            </a>
            <a href="#" className="transition-colors hover:text-[#C5A059]">
              {t("home.navSecurity")}
            </a>
            <a href="#" className="transition-colors hover:text-[#C5A059]">
              {t("home.navTeam")}
            </a>
          </div>

          <div className="flex items-center gap-3">
            <LanguageSwitcher className="shrink-0" />
            <Link
              href="/register?role=lawyer"
              className="hidden rounded-md border border-white/10 bg-white/[0.03] px-3 py-2 text-sm font-semibold text-slate-200 transition-colors hover:bg-white/[0.07] sm:inline-block"
            >
              הצטרפות עורכי דין
            </Link>
            <Link
              href="/login"
              className="hidden rounded-md px-3 py-2 text-sm font-semibold text-slate-300 transition-colors hover:text-white sm:inline-block"
            >
              {t("home.loginLawyers")}
            </Link>
            <Link
              href="/login"
              className="rounded-md border border-[#C5A059]/40 bg-[#C5A059] px-4 py-2 text-sm font-bold text-slate-950 shadow-[0_0_24px_-6px_rgba(197,160,89,0.6)] transition-all hover:bg-[#d4b06a]"
            >
              {t("home.personalArea")}
            </Link>
          </div>
        </div>
      </nav>

      <main className="relative z-10 container mx-auto flex grow flex-col items-center justify-center px-6 py-24 text-center">
        <div className="mb-8 inline-flex items-center gap-2 rounded-full border border-[#C5A059]/30 bg-[#C5A059]/[0.08] px-4 py-1.5 text-[11px] font-bold tracking-[0.2em] text-[#C5A059] uppercase">
          <span className="h-1.5 w-1.5 rounded-full bg-[#C5A059] shadow-[0_0_8px_rgba(197,160,89,0.8)]" />
          {t("home.badge")}
        </div>

        <h1 className="mb-8 font-frank text-6xl font-black leading-[0.95] tracking-tight text-white md:text-[112px]">
          <span className="block">{t("home.heroLine1")}</span>
          <span className="block bg-gradient-to-b from-[#e8c987] via-[#C5A059] to-[#8a6d35] bg-clip-text text-transparent">
            {t("home.heroLine2")}
          </span>
        </h1>

        <p className="mb-12 max-w-2xl text-lg leading-relaxed text-slate-400 md:text-xl">
          {heroSubtitleLine1}
          {heroSubtitleLine2 ? (
            <>
              <br />
              {heroSubtitleLine2}
            </>
          ) : null}
        </p>

        <div className="flex flex-col items-center gap-4 sm:flex-row">
          <Link
            href="/login"
            className="group relative overflow-hidden rounded-lg bg-[#C5A059] px-8 py-4 text-base font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition-all hover:-translate-y-0.5 hover:shadow-[0_12px_40px_-8px_rgba(197,160,89,0.7)]"
          >
            {t("home.cta")}
          </Link>
          <a
            href="#features"
            className="rounded-lg border border-white/10 bg-white/[0.03] px-8 py-4 text-base font-semibold text-slate-200 backdrop-blur-sm transition-colors hover:bg-white/[0.07]"
          >
            {t("home.ctaSecondary")}
          </a>
          <Link
            href="/register?role=lawyer"
            className="rounded-lg border border-[#C5A059]/30 bg-[#C5A059]/10 px-8 py-4 text-base font-semibold text-[#C5A059] backdrop-blur-sm transition-colors hover:bg-[#C5A059]/15"
          >
            הצטרפות עורכי דין
          </Link>
        </div>
      </main>

      <div className="relative z-10 mx-auto mb-10 px-6 text-center" style={{ maxWidth: "72rem" }}>
        <div className="mb-3 text-[11px] font-bold tracking-[0.25em] text-[#C5A059] uppercase">
          {t("home.sectionEyebrow")}
        </div>
        <h2 className="font-frank text-3xl font-bold text-white md:text-4xl">
          {t("home.sectionTitle")}
        </h2>
      </div>

      <section
        id="features"
        className="relative z-10 container mx-auto grid grid-cols-1 gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/5 px-0 mx-6 mb-24 md:mx-auto md:grid-cols-2 lg:grid-cols-3"
        style={{ maxWidth: "min(100% - 3rem, 72rem)" }}
      >
        {bento.map((item) => (
          <div
            key={item.tag}
            className="group relative bg-slate-950/80 p-8 transition-colors hover:bg-slate-900/80"
          >
            <div className="mb-6 flex items-center gap-3">
              <span className="h-px w-8 bg-[#C5A059]" />
              <span className="text-[10px] font-bold tracking-[0.25em] text-[#C5A059] uppercase">
                {item.tag}
              </span>
            </div>
            <h3 className="mb-3 font-frank text-2xl font-bold text-white">
              {item.title}
            </h3>
            <p className="text-sm leading-relaxed text-slate-400">
              {item.desc}
            </p>
            <div
              aria-hidden
              className="pointer-events-none absolute inset-x-8 bottom-0 h-px bg-gradient-to-r from-transparent via-[#C5A059]/40 to-transparent opacity-0 transition-opacity group-hover:opacity-100"
            />
          </div>
        ))}
      </section>
    </div>
  );
}
