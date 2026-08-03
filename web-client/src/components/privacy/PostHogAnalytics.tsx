"use client";

import { useEffect } from "react";
import posthog from "posthog-js";
import {
  CONSENT_CHANGE_EVENT,
  CONSENT_STORAGE_KEY,
  type CookieConsentV1,
} from "@/components/privacy/CookieConsent";

let posthogInitialized = false;

function readConsent(): CookieConsentV1 | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(CONSENT_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as CookieConsentV1;
  } catch {
    return null;
  }
}

function ensureInit(key: string, host: string) {
  if (posthogInitialized) return;
  posthog.init(key, {
    api_host: host,
    person_profiles: "identified_only",
    capture_pageview: true,
    capture_pageleave: true,
    persistence: "localStorage+cookie",
  });
  posthogInitialized = true;
}

/**
 * Loads PostHog only when CookieConsent analytics=true.
 * Opt-out when consent is withdrawn or never granted.
 */
export function PostHogAnalytics({
  apiKey,
  apiHost,
}: {
  apiKey: string;
  apiHost: string;
}) {
  useEffect(() => {
    if (!apiKey) return;

    const apply = () => {
      const consent = readConsent();
      if (consent?.analytics) {
        ensureInit(apiKey, apiHost);
        posthog.opt_in_capturing();
      } else if (posthogInitialized) {
        posthog.opt_out_capturing();
      }
    };

    apply();
    window.addEventListener(CONSENT_CHANGE_EVENT, apply);
    window.addEventListener("storage", apply);
    return () => {
      window.removeEventListener(CONSENT_CHANGE_EVENT, apply);
      window.removeEventListener("storage", apply);
    };
  }, [apiKey, apiHost]);

  return null;
}
