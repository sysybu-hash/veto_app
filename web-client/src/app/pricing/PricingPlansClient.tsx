"use client";

import Link from "next/link";
import { useMemo } from "react";
import { ArrowLeft, ArrowRight, CheckCircle2, Users } from "lucide-react";
import PayPalCheckout from "@/components/billing/PayPalCheckout";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type Props = {
  isLoggedIn: boolean;
};

export function PricingPlansClient({ isLoggedIn }: Props) {
  const { t, locale } = useTranslation();
  const CtaArrow = locale === "he" ? ArrowLeft : ArrowRight;

  const plans = useMemo(
    () => [
      {
        id: "demo",
        name: t("pricingPage.demoName"),
        price: "₪0",
        href: "/plans",
        points: [
          t("pricingPage.demoP1"),
          t("pricingPage.demoP2"),
          t("pricingPage.demoP3"),
        ],
      },
      {
        id: "standard",
        name: t("pricingPage.standardName"),
        price: "₪99.00",
        href: "/plans",
        featured: true,
        points: [
          t("pricingPage.standardP1"),
          t("pricingPage.standardP2"),
          t("pricingPage.standardP3"),
          t("pricingPage.standardP4"),
        ],
      },
      {
        id: "family",
        name: t("pricingPage.familyName"),
        price: "₪199.99",
        href: "/plans",
        points: [
          t("pricingPage.familyP1"),
          t("pricingPage.familyP2"),
          t("pricingPage.familyP3"),
          t("pricingPage.familyP4"),
        ],
      },
    ],
    [t],
  );

  return (
    <main className="min-h-screen bg-surface-canvas px-5 py-16 text-secondary">
      <section className="mx-auto max-w-7xl">
        <div className="flex flex-wrap items-end gap-4">
          <VetoBrandLogo className="h-8 w-auto opacity-95 sm:h-9" />
          <p className="pb-1 text-xs font-black tracking-[0.24em] text-veto-gold-light">
            {t("pricingPage.eyebrow")}
          </p>
        </div>
        <h1 className="mt-4 max-w-3xl font-frank text-5xl font-black leading-tight text-primary">
          {t("pricingPage.title")}
        </h1>
        <p className="mt-5 max-w-2xl text-base leading-8 text-muted">
          {t("pricingPage.subtitle")}
        </p>

        <div className="mt-10 grid gap-5 lg:grid-cols-3">
          {plans.map((plan) => (
            <article
              key={plan.id}
              className={`rounded-lg border p-6 ${
                plan.featured
                  ? "border-veto-gold/70 bg-veto-gold/10 shadow-[0_22px_80px_-45px_rgba(216,184,103,0.9)]"
                  : "border-subtle bg-surface-raised-2"
              }`}
            >
              <div className="flex items-center justify-between gap-3">
                <h2 className="font-frank text-2xl font-black text-primary">{plan.name}</h2>
                {plan.id === "family" ? (
                  <Users className="h-6 w-6 text-veto-gold-light" aria-hidden />
                ) : null}
              </div>
              <p className="mt-4 text-4xl font-black text-veto-gold-light">{plan.price}</p>
              <p className="mt-1 text-sm text-muted">{t("pricingPage.perMonth")}</p>
              <ul className="mt-6 space-y-3">
                {plan.points.map((point) => (
                  <li key={point} className="flex items-center gap-2 text-sm text-secondary">
                    <CheckCircle2
                      className="h-4 w-4 shrink-0 text-veto-gold-light"
                      aria-hidden
                    />
                    {point}
                  </li>
                ))}
              </ul>

              {plan.featured ? (
                <div className="mt-7 space-y-3">
                  <Link
                    href={isLoggedIn ? "/plans" : "/login?next=/plans"}
                    className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-veto-gold/60 bg-veto-gold px-5 py-3 text-sm font-black text-primary shadow-[0_0_24px_-8px_rgba(197,160,89,0.8)] transition hover:bg-veto-gold-light"
                  >
                    {t("pricingPage.startPlan")}
                    <CtaArrow className="h-4 w-4" aria-hidden />
                  </Link>
                  <PayPalCheckout amount="99.00" isLoggedIn={isLoggedIn} />
                </div>
              ) : (
                <Link
                  href={
                    isLoggedIn
                      ? plan.href
                      : `/login?next=${encodeURIComponent(plan.href)}`
                  }
                  className="mt-7 inline-flex w-full items-center justify-center gap-2 rounded-xl border border-subtle px-5 py-3 text-sm font-black text-primary transition hover:bg-surface-overlay"
                >
                  {plan.id === "family"
                    ? t("pricingPage.familyCta")
                    : t("pricingPage.startPlan")}
                  <CtaArrow className="h-4 w-4" aria-hidden />
                </Link>
              )}
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
