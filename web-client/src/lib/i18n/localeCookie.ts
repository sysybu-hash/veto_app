import type { Locale } from "./types";
import { LOCALES } from "./types";

/** Cookie mirrors localStorage so we can eventually SSR locale-aware pages. */
export const LOCALE_COOKIE = "veto_ui_locale";
const COOKIE_MAX_AGE_SEC = 60 * 60 * 24 * 365;

export function parseLocale(raw: string | null | undefined): Locale {
  if (raw === "en" || raw === "ru" || raw === "he") return raw;
  return "he";
}

export function isLocale(value: string): value is Locale {
  return (LOCALES as string[]).includes(value);
}

export function writeLocaleCookie(locale: Locale): void {
  if (typeof document === "undefined") return;
  document.cookie = `${LOCALE_COOKIE}=${locale};path=/;max-age=${COOKIE_MAX_AGE_SEC};SameSite=Lax`;
}
