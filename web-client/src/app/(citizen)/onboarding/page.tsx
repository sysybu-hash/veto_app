"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { Check, Globe2, LockKeyhole, ShieldCheck, Sparkles } from "lucide-react";
import { fetchProfile, updateProfile } from "@/api/userApi";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import type { Locale } from "@/lib/i18n/types";
import { LOCALES } from "@/lib/i18n/types";
import { citizenBottomSafe, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { Button } from "@/components/ui/primitives/Button";

const languageNames: Record<Locale, string> = {
  he: "עברית",
  en: "English",
  ru: "Русский",
};

const languageHints: Record<Locale, string> = {
  he: "ממשק מלא מימין לשמאל",
  en: "English interface",
  ru: "Интерфейс на русском",
};

export default function OnboardingPage() {
  const router = useRouter();
  const { t, locale, setLocale } = useTranslation();
  const [pref, setPref] = useState<Locale>(locale);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
    }
  }, [router]);

  const load = useCallback(async () => {
    try {
      const u = await fetchProfile();
      if (u.onboarding_completed === true) {
        router.replace("/hub");
        return;
      }
      const pl = u.preferred_language;
      if (pl === "en" || pl === "ru" || pl === "he") {
        setPref(pl);
        setLocale(pl);
      }
    } catch {
      /* keep the page usable; submit will surface auth/API errors */
    }
  }, [router, setLocale]);

  useEffect(() => {
    queueMicrotask(() => {
      void load();
    });
  }, [load]);

  const finish = () => {
    void (async () => {
      setBusy(true);
      setErr(null);
      try {
        setLocale(pref);
        await updateProfile({
          preferred_language: pref,
          onboarding_completed: true,
        });
        router.replace("/hub");
      } catch (e) {
        const raw = e instanceof Error ? e.message : "Error";
        if (/unauthorized/i.test(raw)) {
          setErr(t("onboarding.errSession"));
          router.replace("/login");
          return;
        }
        setErr(raw);
      } finally {
        setBusy(false);
      }
    })();
  };

  return (
    <div className="flex flex-1 flex-col overflow-hidden">
      <main
        className={`mx-auto grid w-full max-w-6xl flex-1 items-center gap-8 px-5 py-8 md:grid-cols-[minmax(0,0.9fr)_minmax(420px,1fr)] md:px-8 lg:gap-12 ${citizenBottomSafe}`}
      >
        <section className="min-w-0 space-y-6">
          <div className="inline-flex items-center gap-2 rounded-full border border-veto-gold/40 bg-veto-gold/15 px-3 py-1.5 text-xs font-bold text-primary">
            <Sparkles className="h-4 w-4" aria-hidden />
            <span>{t("onboarding.badge")}</span>
          </div>

          <div className="space-y-3">
            <h1 className="font-frank max-w-2xl text-4xl font-black leading-tight text-primary sm:text-5xl">
              {t("onboarding.heroTitle")}
            </h1>
            <p className="max-w-xl text-base leading-8 text-muted sm:text-lg">
              {t("onboarding.heroSubtitle")}
            </p>
          </div>

          <div className="grid gap-3 sm:grid-cols-3 md:grid-cols-1 lg:grid-cols-3">
            {[
              { icon: ShieldCheck, label: t("onboarding.promiseSos") },
              { icon: LockKeyhole, label: t("onboarding.promiseVault") },
              { icon: Globe2, label: t("onboarding.promiseLanguage") },
            ].map((item) => {
              const Icon = item.icon;
              return (
                <div
                  key={item.label}
                  className="rounded-2xl border border-subtle bg-white/[0.04] px-4 py-4 shadow-sm backdrop-blur-xl"
                >
                  <Icon className="mb-3 h-5 w-5 text-veto-gold-dark" aria-hidden />
                  <p className="text-sm font-bold leading-6 text-primary">
                    {item.label}
                  </p>
                </div>
              );
            })}
          </div>
        </section>

        <section
          className={`${glassPanel} min-w-0 p-5 shadow-xl shadow-slate-900/5 sm:p-7`}
        >
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.18em] text-veto-gold-dark">
                {t("onboarding.step")}
              </p>
              <h2 className="font-frank mt-2 text-2xl font-black text-primary">
                {t("onboarding.language")}
              </h2>
              <p className="mt-2 text-sm leading-6 text-muted">
                {t("onboarding.subtitle")}
              </p>
            </div>
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-surface-inverse text-inverse shadow-lg">
              <Globe2 className="h-5 w-5" aria-hidden />
            </div>
          </div>

          <div
            className="mt-6 grid gap-3"
            role="radiogroup"
            aria-label={t("onboarding.language")}
          >
            {LOCALES.map((l) => {
              const active = pref === l;
              return (
                <button
                  key={l}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  onClick={() => {
                    setPref(l);
                    setLocale(l);
                  }}
                  className={`flex min-h-16 items-center justify-between gap-4 rounded-2xl border px-4 py-3 text-start transition ${
                    active
                      ? "border-veto-gold bg-veto-gold/20 shadow-[0_0_24px_rgba(197,160,89,0.22)]" : "border-subtle bg-white/[0.03] hover:bg-white/[0.05]"}`}
                >
                  <span className="min-w-0">
                    <span className="block text-base font-black text-primary">
                      {languageNames[l]}
                    </span>
                    <span className="block text-xs font-medium text-muted">
                      {languageHints[l]}
                    </span>
                  </span>
                  <span
                    className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full border ${
                      active
                        ? "border-veto-gold bg-veto-gold text-black" : "border-subtle bg-white/[0.04] text-transparent"}`}
                  >
                    <Check className="h-4 w-4" aria-hidden />
                  </span>
                </button>
              );
            })}
          </div>

          <div className={`${glassPanelNested} mt-5 p-4`}>
            <p className="text-sm font-bold text-primary">
              {t("onboarding.readyTitle")}
            </p>
            <p className="mt-1 text-xs leading-5 text-muted">
              {t("onboarding.skipHint")}
            </p>
          </div>

          {err && (
            <p
              className="mt-4 rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200"
              role="alert"
            >
              {err}
            </p>
          )}

          <div className="mt-7 grid gap-3 sm:grid-cols-[1fr_auto]">
            <Button variant="primary" size="lg" disabled={busy} loading={busy} onClick={() => finish()}>
              {t("onboarding.done")}
            </Button>
            <Button variant="secondary" size="lg" onClick={() => router.push("/settings?tab=profile")}>
              {t("settings.title")}
            </Button>
          </div>
        </section>
      </main>
    </div>
  );
}
