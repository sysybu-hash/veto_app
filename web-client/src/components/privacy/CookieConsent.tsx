"use client";

import Link from "next/link";
import { useState, useSyncExternalStore } from "react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

const STORAGE_KEY = "veto_cookie_consent_v1";
const CHANGE_EVENT = "veto-cookie-consent-change";

type Consent = {
  necessary: true;
  analytics: boolean;
  marketing: boolean;
  acceptedAt: string;
};

function readConsent(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(STORAGE_KEY);
}

function subscribe(onStoreChange: () => void) {
  if (typeof window === "undefined") return () => {};
  const onChange = () => onStoreChange();
  window.addEventListener("storage", onChange);
  window.addEventListener(CHANGE_EVENT, onChange);
  return () => {
    window.removeEventListener("storage", onChange);
    window.removeEventListener(CHANGE_EVENT, onChange);
  };
}

function saveConsent(consent: Consent) {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(consent));
  window.dispatchEvent(new CustomEvent(CHANGE_EVENT, { detail: consent }));
}

export function CookieConsent() {
  const stored = useSyncExternalStore(subscribe, readConsent, () => "server");
  const [expanded, setExpanded] = useState(false);
  const [analytics, setAnalytics] = useState(false);
  const [marketing, setMarketing] = useState(false);

  if (stored) return null;

  const accept = (options: { analytics: boolean; marketing: boolean }) => {
    saveConsent({
      necessary: true,
      analytics: options.analytics,
      marketing: options.marketing,
      acceptedAt: new Date().toISOString(),
    });
  };

  return (
    <section
      data-print="hide"
      dir="rtl"
      aria-label="העדפות פרטיות ועוגיות"
      className="fixed inset-x-3 bottom-3 z-[70] mx-auto max-w-4xl rounded-2xl border border-subtle bg-surface-overlay p-4 text-primary shadow-2xl dark:shadow-[0_24px_64px_rgba(0,0,0,0.55)] sm:bottom-5 sm:p-5"
    >
      <div className="grid gap-4 md:grid-cols-[1fr_auto] md:items-start">
        <div>
          <div className="mb-2 flex justify-start">
            <VetoBrandLogo className="h-7 w-auto max-w-[180px]" />
          </div>
          <h2 className="text-base font-bold">העדפות פרטיות</h2>
          <p className="mt-1 text-sm leading-6 text-secondary">
            אנחנו משתמשים בעוגיות חיוניות להפעלת VETO. עוגיות מדידה או שיווק יופעלו רק לאחר אישור מפורש.
          </p>
          <div className="mt-2 flex flex-wrap gap-3 text-xs font-semibold text-muted">
            <Link href="/privacy" className="hover:text-primary">מדיניות פרטיות</Link>
            <Link href="/cookies" className="hover:text-primary">מדיניות עוגיות</Link>
            <Link href="/terms" className="hover:text-primary">תנאי שימוש</Link>
          </div>
        </div>

        <div className="flex flex-wrap gap-2 md:justify-end">
          <button
            type="button"
            onClick={() => accept({ analytics: false, marketing: false })}
            className="rounded-xl border border-subtle px-4 py-2 text-sm font-semibold text-secondary hover:bg-hover-overlay"
          >
            חיוניות בלבד
          </button>
          <button
            type="button"
            onClick={() => setExpanded((v) => !v)}
            className="rounded-xl border border-subtle px-4 py-2 text-sm font-semibold text-secondary hover:bg-hover-overlay"
          >
            התאמה אישית
          </button>
          <button
            type="button"
            onClick={() => accept({ analytics: true, marketing: true })}
            className="rounded-xl bg-veto-gold px-4 py-2 text-sm font-bold text-on-brand hover:bg-veto-gold-light"
          >
            אישור הכל
          </button>
        </div>
      </div>

      {expanded && (
        <div className="mt-4 grid gap-3 border-t border-subtle pt-4 sm:grid-cols-2">
          <label className="flex items-start gap-3 rounded-xl bg-surface-sunken p-3 dark:bg-white/5">
            <input
              type="checkbox"
              checked={analytics}
              onChange={(e) => setAnalytics(e.target.checked)}
              className="mt-1 h-4 w-4"
            />
            <span>
              <span className="block text-sm font-bold">מדידה ושיפור</span>
              <span className="text-xs leading-5 text-muted">עוזר לנו להבין תקלות ושימוש באתר.</span>
            </span>
          </label>
          <label className="flex items-start gap-3 rounded-xl bg-surface-sunken p-3 dark:bg-white/5">
            <input
              type="checkbox"
              checked={marketing}
              onChange={(e) => setMarketing(e.target.checked)}
              className="mt-1 h-4 w-4"
            />
            <span>
              <span className="block text-sm font-bold">שיווק</span>
              <span className="text-xs leading-5 text-muted">מיועד לקמפיינים עתידיים, רק בהסכמה.</span>
            </span>
          </label>
          <button
            type="button"
            onClick={() => accept({ analytics, marketing })}
            className="rounded-xl bg-veto-gold px-4 py-2 text-sm font-bold text-on-brand sm:col-span-2"
          >
            שמירת העדפות
          </button>
        </div>
      )}
    </section>
  );
}
