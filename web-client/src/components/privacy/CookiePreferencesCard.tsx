"use client";

import { useSyncExternalStore } from "react";
import { Button } from "@/components/ui";
import {
  CONSENT_CHANGE_EVENT,
  CONSENT_STORAGE_KEY,
  reopenCookiePreferences,
  type CookieConsentV1,
} from "@/components/privacy/CookieConsent";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

function subscribe(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const onChange = () => onStoreChange();
  window.addEventListener("storage", onChange);
  window.addEventListener(CONSENT_CHANGE_EVENT, onChange);
  return () => {
    window.removeEventListener("storage", onChange);
    window.removeEventListener(CONSENT_CHANGE_EVENT, onChange);
  };
}

function snapshot(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(CONSENT_STORAGE_KEY);
}

/**
 * Shows the visitor's current cookie decision and lets them change or withdraw
 * it. Required by GDPR Art. 7(3) — withdrawal must be as easy as consenting,
 * and the banner alone only ever appears before the first decision.
 */
export function CookiePreferencesCard() {
  const { t } = useTranslation();
  const raw = useSyncExternalStore(subscribe, snapshot, () => null);

  let consent: CookieConsentV1 | null = null;
  if (raw) {
    try {
      consent = JSON.parse(raw) as CookieConsentV1;
    } catch {
      consent = null;
    }
  }

  const badge = (on: boolean) => (
    <span
      className={`rounded-full px-2 py-0.5 text-xs font-bold ${
        on
          ? "bg-success-soft text-success-fg"
          : "bg-surface-raised text-muted"
      }`}
    >
      {on ? t("cookieConsent.statusOn") : t("cookieConsent.statusOff")}
    </span>
  );

  return (
    <section className="rounded-2xl border border-brand bg-brand-soft p-5">
      <h2 className="text-lg font-bold text-primary md:text-xl">
        {t("cookieConsent.manage")}
      </h2>
      <p className="mt-2 text-sm text-secondary">
        {t("cookieConsent.manageHint")}
      </p>

      {consent ? (
        <dl className="mt-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm">
          <div className="flex items-center gap-2">
            <dt className="text-secondary">
              {t("cookieConsent.currentAnalytics")}
            </dt>
            <dd>{badge(!!consent.analytics)}</dd>
          </div>
          <div className="flex items-center gap-2">
            <dt className="text-secondary">
              {t("cookieConsent.currentMarketing")}
            </dt>
            <dd>{badge(!!consent.marketing)}</dd>
          </div>
        </dl>
      ) : null}

      <div className="mt-4">
        <Button type="button" onClick={() => reopenCookiePreferences()}>
          {consent ? t("cookieConsent.withdraw") : t("cookieConsent.manage")}
        </Button>
      </div>
    </section>
  );
}
