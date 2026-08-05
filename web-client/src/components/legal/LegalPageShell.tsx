"use client";

import Link from "next/link";
import type { ReactNode } from "react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type TitleKey =
  | "legalChrome.termsTitle"
  | "legalChrome.privacyTitle"
  | "legalChrome.cookiesTitle"
  | "legalChrome.accessibilityTitle";

type Props = {
  titleKey: TitleKey;
  approved: boolean;
  children: ReactNode;
};

export function LegalPageShell({ titleKey, approved, children }: Props) {
  const { t, locale } = useTranslation();

  return (
    <div className="min-h-screen text-primary">
      <main className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12">
        <div className="mb-8">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-xl bg-veto-gold px-5 py-2.5 text-sm font-bold text-brand-fg transition hover:opacity-90"
          >
            {t("legalChrome.backHome")}
          </Link>
        </div>

        <header className="mb-8 text-center md:text-start">
          <div className="mb-4 flex justify-center md:justify-start">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            {t(titleKey)}
          </h1>
          {!approved ? (
            <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
              <strong>{t("legalChrome.draftBanner")}</strong>{" "}
              <Link href="/contact" className="font-bold underline">
                {t("footer.contact")}
              </Link>
            </p>
          ) : (
            <p className="mt-3 text-sm text-muted">
              <Link href="/contact" className="font-semibold underline">
                {t("footer.contact")}
              </Link>
            </p>
          )}
          {locale !== "he" ? (
            <p className="mt-3 rounded-xl border border-subtle bg-surface-sunken px-4 py-3 text-sm text-secondary">
              {t("legalChrome.bindingNote")}
            </p>
          ) : null}
        </header>

        <div dir="rtl">{children}</div>
      </main>
    </div>
  );
}
