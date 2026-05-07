"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { fetchProfile, updateProfile } from "@/api/userApi";
import { getJwt } from "@/lib/authToken";
import type { Locale } from "@/lib/i18n/types";
import { LOCALES } from "@/lib/i18n/types";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassInput,
  glassPanelNested,
} from "@/lib/vetoGlass";

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
      /* ignore */
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
        setErr(e instanceof Error ? e.message : "Error");
      } finally {
        setBusy(false);
      }
    })();
  };

  return (
    <div className="mx-auto flex max-w-lg flex-1 flex-col justify-center px-4 py-16">
      <main className={`p-6 md:p-8 ${glassPanelNested}`}>
        <h1 className="font-frank text-2xl font-bold text-slate-900">
          {t("onboarding.title")}
        </h1>
        <p className="mt-2 text-sm text-slate-600">{t("onboarding.subtitle")}</p>

        <div className="mt-6">
          <label className="text-xs font-semibold text-slate-700">
            {t("onboarding.language")}
          </label>
          <select
            value={pref}
            onChange={(e) => setPref(e.target.value as Locale)}
            className={`mt-1 w-full ${glassInput}`}
          >
            {LOCALES.map((l) => (
              <option key={l} value={l}>
                {l.toUpperCase()}
              </option>
            ))}
          </select>
        </div>

        <p className="mt-3 text-xs text-slate-500">{t("onboarding.skipHint")}</p>

        {err && (
          <p className="mt-4 text-sm text-red-800" role="alert">
            {err}
          </p>
        )}

        <div className="mt-8 flex flex-wrap gap-3">
          <button
            type="button"
            disabled={busy}
            onClick={() => finish()}
            className={`px-5 py-3 text-sm font-semibold ${btnPrimaryDark} disabled:opacity-50`}
          >
            {busy ? "…" : t("onboarding.done")}
          </button>
          <button
            type="button"
            onClick={() => router.push("/settings?tab=profile")}
            className={`px-5 py-3 text-sm ${btnSecondaryGlass}`}
          >
            {t("settings.title")}
          </button>
        </div>
      </main>
    </div>
  );
}
