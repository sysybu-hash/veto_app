"use client";

import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { PLAYBOOKS, pickText } from "@/lib/playbooks";

type Props = {
  approved: boolean;
};

export function PlaybooksIndexClient({ approved }: Props) {
  const { t, locale } = useTranslation();

  return (
    <div className="min-h-screen text-primary">
      <main className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12">
        <div className="mb-8 flex flex-wrap gap-3">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-xl bg-veto-gold px-5 py-2.5 text-sm font-bold text-primary transition hover:opacity-90"
          >
            {t("playbooksUi.backHome")}
          </Link>
          <Link
            href="/login?redirect=%2Fhub"
            className="inline-flex items-center justify-center rounded-xl border border-subtle bg-surface-raised px-5 py-2.5 text-sm font-bold text-primary transition hover:border-veto-gold"
          >
            {t("playbooksUi.loginSos")}
          </Link>
        </div>

        <header className="mb-8 text-center md:text-start">
          <div className="mb-4 flex justify-center md:justify-start">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            {t("playbooksUi.title")}
          </h1>
          <p className="mt-3 text-sm leading-7 text-secondary md:text-base">
            {t("playbooksUi.subtitle")}
          </p>
          <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
            <strong>{t("playbooksUi.disclaimer")}</strong>
            {!approved ? t("playbooksUi.draftExtra") : null}
          </p>
        </header>

        <ul className="space-y-3">
          {PLAYBOOKS.map((p) => (
            <li key={p.id}>
              <Link
                href={`/playbooks/${p.id}`}
                className="block rounded-2xl border border-subtle bg-surface-raised-2 p-5 shadow-sm transition hover:border-veto-gold"
              >
                <h2 className="text-lg font-bold text-primary">{pickText(locale, p.title)}</h2>
                <p className="mt-1 text-sm text-secondary">{pickText(locale, p.subtitle)}</p>
                <span className="mt-3 inline-block text-xs font-bold text-veto-gold">
                  {t("playbooksUi.openGuide")}
                </span>
              </Link>
            </li>
          ))}
        </ul>

        <p className="mt-8 text-center text-sm text-muted">
          {t("playbooksUi.alsoSee")}{" "}
          <Link href="/terms" className="font-semibold underline">
            {t("playbooksUi.terms")}
          </Link>{" "}
          {t("playbooksUi.and")}{" "}
          <Link href="/contact" className="font-semibold underline">
            {t("playbooksUi.contact")}
          </Link>
        </p>
      </main>
    </div>
  );
}
