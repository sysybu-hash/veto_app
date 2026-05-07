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
      title: t("home.bentoSyncTitle"),
      desc: t("home.bentoSyncDesc"),
      tag: t("home.bentoSyncTag"),
    },
  ] as const;

  return (
    <div className="flex min-h-screen flex-col bg-[#f6efe1]">
      <nav className="container mx-auto flex items-center justify-between px-6 py-8">
        <img
          src="/veto-logo.svg"
          alt="VETO"
          className="h-9 w-auto select-none"
          draggable={false}
        />

        <div className="hidden items-center gap-8 font-bold text-white/90 md:flex">
          <a href="#" className="transition-all hover:text-[#C5A059]">
            {t("home.navSystem")}
          </a>
          <a href="#" className="transition-all hover:text-[#C5A059]">
            {t("home.navSecurity")}
          </a>
          <a href="#" className="transition-all hover:text-[#C5A059]">
            {t("home.navTeam")}
          </a>
        </div>
        <div className="flex items-center gap-4">
          <LanguageSwitcher className="shrink-0" />
          <Link
            href="/login"
            className="rounded-lg px-4 py-2 font-bold text-red-600 transition-all hover:bg-white/10"
          >
            {t("home.loginLawyers")}
          </Link>
          <Link
            href="/login"
            className="rounded-full bg-[#C5A059] px-6 py-2 font-black text-black shadow-lg transition-all hover:scale-105"
          >
            {t("home.personalArea")}
          </Link>
        </div>
      </nav>

      <main className="container mx-auto flex grow flex-col items-center justify-center px-6 py-20 text-center">
        <div className="mb-6 rounded-full border border-white/20 bg-white/10 px-4 py-1 text-xs font-black tracking-wide text-white backdrop-blur-md">
          {t("home.badge")}
        </div>
        <h1 className="mb-8 font-frank text-7xl font-black leading-[0.9] tracking-tighter text-slate-900 drop-shadow-sm md:text-[120px]">
          {t("home.heroLine1")}
          <br />
          {t("home.heroLine2")}
        </h1>
        <p className="mb-10 max-w-3xl text-xl font-medium leading-relaxed text-slate-700 md:text-2xl">
          {heroSubtitleLine1}
          {heroSubtitleLine2 ? (
            <>
              <br />
              {heroSubtitleLine2}
            </>
          ) : null}
        </p>

        <Link
          href="/login"
          className="rounded-2xl bg-slate-900 px-12 py-5 text-xl font-black text-white shadow-2xl transition-all hover:-translate-y-1 hover:bg-[#C5A059]"
        >
          {t("home.cta")}
        </Link>
      </main>

      <section className="container mx-auto grid grid-cols-1 gap-6 px-6 pb-20 md:grid-cols-3">
        {bento.map((item) => (
          <div
            key={item.tag}
            className="cursor-default rounded-[40px] border border-white/60 bg-white/40 p-10 shadow-sm backdrop-blur-xl transition-all hover:bg-white/60 hover:shadow-xl"
          >
            <span className="mb-4 block text-[10px] font-black tracking-widest text-[#C5A059] uppercase">
              {item.tag}
            </span>
            <h3 className="mb-4 font-frank text-3xl font-bold text-slate-900">
              {item.title}
            </h3>
            <p className="font-medium leading-relaxed text-slate-600">
              {item.desc}
            </p>
          </div>
        ))}
      </section>
    </div>
  );
}
