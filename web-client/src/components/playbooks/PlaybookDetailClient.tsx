"use client";

import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { pickList, pickText, type Playbook } from "@/lib/playbooks";

type Props = {
  playbook: Playbook;
  approved: boolean;
};

export function PlaybookDetailClient({ playbook, approved }: Props) {
  const { t, locale } = useTranslation();
  const know = pickList(locale, playbook.know);
  const first = pickList(locale, playbook.first);

  return (
    <div className="min-h-screen text-primary">
      <main className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12">
        <div className="mb-8 flex flex-wrap gap-3">
          <Link
            href="/playbooks"
            className="inline-flex rounded-xl border border-subtle bg-surface-raised px-4 py-2 text-sm font-bold transition hover:border-veto-gold"
          >
            {t("playbooksUi.allGuides")}
          </Link>
          <Link
            href="/login?redirect=%2Fhub"
            className="inline-flex rounded-xl bg-veto-gold px-4 py-2 text-sm font-bold text-brand-fg"
          >
            {t("playbooksUi.loginSos")}
          </Link>
        </div>

        <header className="mb-6 text-center md:text-start">
          <div className="mb-4 flex justify-center md:justify-start">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold md:text-4xl">
            {pickText(locale, playbook.title)}
          </h1>
          <p className="mt-2 text-secondary">{pickText(locale, playbook.subtitle)}</p>
          {!approved && (
            <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
              {t("playbooksUi.draftBanner")}
            </p>
          )}
        </header>

        <article className="space-y-8 rounded-2xl border border-subtle bg-surface-raised-2 p-6 shadow-sm md:p-8">
          <section>
            <h2 className="text-lg font-bold">{t("playbooksUi.knowTitle")}</h2>
            <ul className="mt-3 list-disc space-y-2 ps-5 text-sm leading-7 text-secondary md:text-base">
              {know.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </section>
          <section>
            <h2 className="text-lg font-bold">{t("playbooksUi.firstTitle")}</h2>
            <ol className="mt-3 list-decimal space-y-2 ps-5 text-sm leading-7 text-secondary md:text-base">
              {first.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ol>
          </section>
          <p className="rounded-xl border border-veto-gold/40 bg-veto-gold/10 px-4 py-3 text-sm font-semibold text-primary">
            {pickText(locale, playbook.warn)}
          </p>
          <p className="text-xs text-muted">
            {t("playbooksUi.notAdvice")}{" "}
            <Link href="/terms" className="underline">
              {t("playbooksUi.terms")}
            </Link>
            .
          </p>
        </article>
      </main>
    </div>
  );
}
