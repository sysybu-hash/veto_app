"use client";

import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { ContactForm } from "@/components/contact/ContactForm";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type Props = {
  email: string;
  waHref: string;
  approved: boolean;
};

export function ContactPageClient({ email, waHref, approved }: Props) {
  const { t } = useTranslation();

  return (
    <div className="min-h-screen text-primary">
      <main className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12">
        <div className="mb-8">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-xl bg-veto-gold px-5 py-2.5 text-sm font-bold text-primary transition hover:opacity-90"
          >
            {t("contactPage.backHome")}
          </Link>
        </div>

        <header className="mb-8 text-center md:text-start">
          <div className="mb-4 flex justify-center md:justify-start">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            {t("contactPage.title")}
          </h1>
          {!approved && (
            <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
              <strong>{t("contactPage.draftBanner")}</strong>
            </p>
          )}
          <p className="mt-3 text-sm leading-7 text-secondary md:text-base">
            {t("contactPage.intro")}{" "}
            <strong className="text-primary">{t("contactPage.emergencyStrong")}</strong>{" "}
            {t("contactPage.sosHint")}
          </p>
        </header>

        <div className="mb-6 grid gap-3 sm:grid-cols-2">
          {email ? (
            <a
              href={`mailto:${email}`}
              className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm font-semibold text-primary shadow-sm transition hover:border-veto-gold"
              dir="ltr"
            >
              <span className="mb-1 block text-xs font-bold text-muted" dir="auto">
                {t("contactPage.emailLabel")}
              </span>
              {email}
            </a>
          ) : (
            <div className="rounded-2xl border border-dashed border-subtle bg-surface-raised-2 px-4 py-4 text-sm text-secondary shadow-sm">
              <span className="mb-1 block text-xs font-bold text-muted">
                {t("contactPage.emailLabel")}
              </span>
              {t("contactPage.emailPending")}
            </div>
          )}

          {waHref ? (
            <a
              href={waHref}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm font-semibold text-primary shadow-sm transition hover:border-veto-gold"
            >
              <span className="mb-1 block text-xs font-bold text-muted">
                {t("contactPage.whatsappLabel")}
              </span>
              {t("contactPage.whatsappOpen")}
            </a>
          ) : (
            <div className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm text-secondary shadow-sm">
              <span className="mb-1 block text-xs font-bold text-muted">
                {t("contactPage.responseTimesLabel")}
              </span>
              {t("contactPage.responseTimesBody")}
            </div>
          )}
        </div>

        <ContactForm supportEmail={email} />

        <div className="mt-6 space-y-3 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm shadow-sm md:p-8">
          <h2 className="text-lg font-bold text-primary">{t("contactPage.usefulLinks")}</h2>
          <div className="grid gap-2 sm:grid-cols-2">
            <Link
              href="/privacy-rights"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              {t("contactPage.privacyRights")}
            </Link>
            <Link
              href="/playbooks"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              {t("contactPage.playbooks")}
            </Link>
            <Link
              href="/register/lawyer"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              {t("contactPage.lawyerJoin")}
            </Link>
            <Link
              href="/pricing"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              {t("contactPage.pricing")}
            </Link>
          </div>
          <div className="flex flex-wrap gap-4 border-t border-subtle pt-4 text-xs font-semibold text-muted md:text-sm">
            <Link href="/privacy" className="hover:text-primary">
              {t("footer.privacy")}
            </Link>
            <Link href="/terms" className="hover:text-primary">
              {t("footer.terms")}
            </Link>
            <Link href="/cookies" className="hover:text-primary">
              {t("footer.cookies")}
            </Link>
          </div>
        </div>
      </main>
    </div>
  );
}
