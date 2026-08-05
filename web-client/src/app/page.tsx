"use client";

import Link from "next/link";
import { useMemo } from "react";
import { motion } from "framer-motion";
import { LivePreviewMockup } from "@/components/ui/LivePreviewMockup";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  Shield,
  Zap,
  Scale,
  Clock,
  ChevronDown,
  ArrowLeft,
  ArrowRight,
  type LucideIcon,
} from "lucide-react";

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: "easeOut" as const },
  },
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.2 } },
};

export default function Home() {
  const { t, locale } = useTranslation();
  const isRtl = locale === "he";
  const CtaArrow = isRtl ? ArrowLeft : ArrowRight;

  const features: { icon: LucideIcon; title: string; desc: string }[] = useMemo(
    () => [
      {
        icon: Clock,
        title: t("landing.featSpeedTitle"),
        desc: t("landing.featSpeedDesc"),
      },
      {
        icon: Shield,
        title: t("landing.featEncryptTitle"),
        desc: t("landing.featEncryptDesc"),
      },
      {
        icon: Zap,
        title: t("landing.featVaultTitle"),
        desc: t("landing.featVaultDesc"),
      },
    ],
    [t],
  );

  const faqs = useMemo(
    () => [
      { q: t("landing.faq1q"), a: t("landing.faq1a") },
      { q: t("landing.faq2q"), a: t("landing.faq2a") },
      { q: t("landing.faq3q"), a: t("landing.faq3a") },
    ],
    [t],
  );

  const faqJsonLd = useMemo(
    () => ({
      "@context": "https://schema.org",
      "@type": "FAQPage",
      mainEntity: faqs.map((f) => ({
        "@type": "Question",
        name: f.q,
        acceptedAnswer: { "@type": "Answer", text: f.a },
      })),
    }),
    [faqs],
  );

  return (
    <main className="min-h-screen overflow-hidden bg-veto-canvas text-primary selection:bg-veto-gold/35 selection:text-veto-ink dark:bg-veto-ink dark:selection:bg-veto-gold dark:selection:text-veto-ink">
      <script
        type="application/ld+json"
        suppressHydrationWarning
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />

      <section className="relative flex min-h-[90vh] w-full flex-col items-center justify-center px-6 pt-20">
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center opacity-[0.12] dark:opacity-20">
          <motion.div
            animate={{ scale: [1, 2, 3], opacity: [0.5, 0.1, 0] }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            className="absolute h-64 w-64 rounded-full border-2 border-veto-gold"
          />
          <motion.div
            animate={{ scale: [1, 2, 3], opacity: [0.5, 0.1, 0] }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "linear",
              delay: 1,
            }}
            className="absolute h-64 w-64 rounded-full border-2 border-veto-gold"
          />
        </div>

        <motion.div
          initial="hidden"
          animate="visible"
          variants={staggerContainer}
          className="relative z-10 mx-auto flex max-w-4xl flex-col items-center text-center"
        >
          <motion.div
            variants={fadeUp}
            className="mb-8 inline-flex items-center gap-2 rounded-full border border-veto-gold/30 bg-veto-gold/10 px-4 py-2 text-sm font-medium text-brand-text backdrop-blur-md"
          >
            <span className="relative flex h-3 w-3">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-veto-gold opacity-75" />
              <span className="relative inline-flex h-3 w-3 rounded-full bg-veto-gold" />
            </span>
            {t("landing.badge")}
          </motion.div>

          <motion.h1
            variants={fadeUp}
            className="mb-6 bg-gradient-to-br from-veto-ink via-slate-700 to-slate-500 bg-clip-text text-5xl font-bold tracking-tight text-transparent dark:from-white dark:via-gray-200 dark:to-gray-500 md:text-7xl"
          >
            {t("landing.heroLine1")}
            <br />
            {t("landing.heroLine2")}
          </motion.h1>

          <motion.p
            variants={fadeUp}
            className="mb-10 max-w-2xl text-lg leading-relaxed text-secondary md:text-xl"
          >
            {t("landing.heroSubtitle")}
          </motion.p>

          <motion.div
            variants={fadeUp}
            className="flex w-full flex-col gap-4 sm:w-auto sm:flex-row"
          >
            <Link
              href="/login"
              className="flex items-center justify-center gap-2 rounded-2xl bg-veto-gold px-8 py-4 text-lg font-bold text-veto-ink shadow-[0_0_20px_rgba(197,160,89,0.4)] transition-all hover:bg-veto-gold-light active:scale-95"
            >
              {t("landing.ctaPersonal")} <CtaArrow size={20} />
            </Link>
            <Link
              href="/register/lawyer"
              className="flex items-center justify-center rounded-2xl border border-veto-gold/45 bg-[rgba(197,160,89,0.14)] px-8 py-4 text-lg font-bold text-brand-text shadow-[inset_0_1px_0_rgba(255,255,255,0.12)] backdrop-blur-md transition-all hover:border-veto-gold/70 hover:bg-[rgba(197,160,89,0.24)] hover:text-veto-gold-light active:scale-95"
            >
              {t("landing.ctaLawyer")}
            </Link>
          </motion.div>
        </motion.div>
      </section>

      <section className="relative w-full bg-gradient-to-b from-veto-canvas via-white to-slate-100 px-6 py-24 dark:from-veto-ink dark:via-veto-ink dark:to-veto-ink">
        <div className="mx-auto max-w-6xl">
          <div className="mb-16 text-center">
            <h2 className="mb-4 text-3xl font-bold text-primary md:text-4xl">
              {t("landing.featuresTitle")}
            </h2>
            <div className="mx-auto h-1 w-20 rounded-full bg-veto-gold" />
          </div>

          <motion.div
            initial="hidden"
            animate="visible"
            variants={staggerContainer}
            className="grid grid-cols-1 gap-6 md:grid-cols-3"
          >
            {features.map((feat) => {
              const Icon = feat.icon;
              return (
                <motion.div
                  key={feat.title}
                  variants={fadeUp}
                  className="group flex flex-col rounded-3xl border border-subtle bg-surface-raised p-8 shadow-sm backdrop-blur-xl transition-colors hover:bg-surface-overlay"
                >
                  <div className="mb-6 flex h-14 w-14 items-center justify-center rounded-2xl bg-veto-gold/20 text-brand-text transition-transform group-hover:scale-110">
                    <Icon size={28} />
                  </div>
                  <h3 className="mb-3 text-xl font-bold text-primary">{feat.title}</h3>
                  <p className="leading-relaxed text-secondary">{feat.desc}</p>
                </motion.div>
              );
            })}
          </motion.div>
        </div>
      </section>

      <section className="bg-surface-sunken px-6 py-24">
        <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-12 md:grid-cols-2">
          <motion.div
            initial={{ opacity: 0, x: isRtl ? 50 : -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.55, ease: "easeOut" }}
          >
            <p className="mb-2 text-xs font-black tracking-[0.22em] text-brand-text">
              {t("landing.experienceEyebrow")}
            </p>
            <h2 className="mb-6 text-4xl font-bold text-primary">
              {t("landing.experienceTitle")}
            </h2>
            <p className="mb-6 text-lg leading-relaxed text-secondary">
              {t("landing.experienceBody")}
            </p>
            <ul className="space-y-4">
              <li className="flex items-center gap-3 text-brand-text">
                <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-veto-gold" />
                {t("landing.experienceBullet1")}
              </li>
              <li className="flex items-center gap-3 text-brand-text">
                <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-veto-gold" />
                {t("landing.experienceBullet2")}
              </li>
            </ul>
          </motion.div>

          <div className="flex justify-center">
            <LivePreviewMockup />
          </div>
        </div>
      </section>

      <section className="border-t border-subtle px-6 py-24">
        <div className="mx-auto max-w-4xl text-center">
          <Scale size={48} className="mx-auto mb-6 text-brand-text opacity-80" />
          <h2 className="mb-6 text-3xl font-bold text-primary md:text-4xl">
            {t("landing.pricingTitle")}
          </h2>
          <p className="mb-8 text-lg text-secondary">{t("landing.pricingBody")}</p>
          <Link
            href="/pricing"
            className="inline-flex rounded-full border border-veto-gold px-8 py-3 font-medium text-brand-text transition-colors hover:bg-veto-gold/10"
          >
            {t("landing.pricingCta")}
          </Link>
        </div>
      </section>

      <section className="bg-surface-sunken px-6 py-24">
        <div className="mx-auto max-w-3xl">
          <div className="mb-12 text-center">
            <h2 className="mb-4 text-3xl font-bold text-primary">{t("landing.faqTitle")}</h2>
          </div>
          <div className="space-y-4">
            {faqs.map((faq) => (
              <details
                key={faq.q}
                className="group cursor-pointer rounded-2xl border border-subtle bg-surface-raised p-6 transition-colors hover:bg-surface-overlay"
              >
                <summary className="flex list-none items-center justify-between text-lg font-medium text-primary">
                  {faq.q}
                  <span className="transition group-open:rotate-180">
                    <ChevronDown size={20} className="text-brand-text" />
                  </span>
                </summary>
                <div className="mt-4 border-s-2 border-veto-gold/30 ps-2 leading-relaxed text-secondary">
                  {faq.a}
                </div>
              </details>
            ))}
          </div>
        </div>
      </section>

      <footer className="border-t border-subtle px-6 py-10">
        <div className="mx-auto flex max-w-4xl flex-wrap items-center justify-center gap-4 text-sm font-semibold text-muted">
          <Link href="/contact" className="hover:text-primary">
            {t("footer.contact")}
          </Link>
          <Link href="/playbooks" className="hover:text-primary">
            {t("footer.playbooks")}
          </Link>
          <Link href="/pricing" className="hover:text-primary">
            {t("footer.pricing")}
          </Link>
          <Link href="/terms" className="hover:text-primary">
            {t("footer.terms")}
          </Link>
          <Link href="/privacy" className="hover:text-primary">
            {t("footer.privacy")}
          </Link>
          <Link href="/cookies" className="hover:text-primary">
            {t("footer.cookies")}
          </Link>
          <Link href="/accessibility" className="hover:text-primary">
            {t("footer.accessibility")}
          </Link>
        </div>
      </footer>
    </main>
  );
}
