"use client";

import Link from "next/link";
import { useState, useSyncExternalStore } from "react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { Button } from "@/components/ui";

export const CONSENT_STORAGE_KEY = "veto_cookie_consent_v1";
export const CONSENT_CHANGE_EVENT = "veto-cookie-consent-change";

export type CookieConsentV1 = {
  necessary: true;
  analytics: boolean;
  marketing: boolean;
  acceptedAt: string;
};

function readConsent(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(CONSENT_STORAGE_KEY);
}

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

function saveConsent(consent: CookieConsentV1) {
  window.localStorage.setItem(CONSENT_STORAGE_KEY, JSON.stringify(consent));
  window.dispatchEvent(new CustomEvent(CONSENT_CHANGE_EVENT, { detail: consent }));
}

/**
 * True while the cookie banner is still showing (no consent decision saved
 * yet). Routes with a fixed-position CTA near the bottom of the viewport
 * (e.g. the hub's SOS button) can use this to reserve extra clearance so
 * the banner never overlaps a safety-critical control on mobile.
 */
export function useCookieConsentPending(): boolean {
  const stored = useSyncExternalStore(subscribe, readConsent, () => "server");
  return !stored;
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
            <Link href="/contact" className="hover:text-primary">צור קשר</Link>
          </div>
        </div>

        <div className="flex flex-wrap gap-2 md:justify-end">
          <Button variant="secondary" size="md" onClick={() => accept({ analytics: false, marketing: false })}>
            חיוניות בלבד
          </Button>
          <Button variant="secondary" size="md" onClick={() => setExpanded((v) => !v)}>
            התאמה אישית
          </Button>
          <Button variant="primary" size="md" onClick={() => accept({ analytics: true, marketing: true })}>
            אישור הכל
          </Button>
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
          <Button variant="primary" size="md" onClick={() => accept({ analytics, marketing })} className="sm:col-span-2">
            שמירת העדפות
          </Button>
        </div>
      )}
    </section>
  );
}
