"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { dictionaries } from "./dictionaries";
import { LOCALE_COOKIE, parseLocale, writeLocaleCookie } from "./localeCookie";
import type { Locale } from "./types";
import { LOCALES, STORAGE_KEY } from "./types";
import { translate } from "./translate";

function applyDocumentLocale(locale: Locale) {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.lang = locale;
  root.dir = locale === "he" ? "rtl" : "ltr";
}

type LocaleContextValue = {
  locale: Locale;
  setLocale: (next: Locale) => void;
  t: (path: string) => string;
};

const LocaleContext = createContext<LocaleContextValue | null>(null);

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>("he");

  useEffect(() => {
    queueMicrotask(() => {
      try {
        let raw = localStorage.getItem(STORAGE_KEY);
        if (!raw && typeof document !== "undefined") {
          const match = document.cookie
            .split("; ")
            .find((row) => row.startsWith(`${LOCALE_COOKIE}=`));
          raw = match?.split("=")[1] ?? null;
        }
        const stored = parseLocale(raw);
        setLocaleState(stored);
        writeLocaleCookie(stored);
        applyDocumentLocale(stored);
      } catch {
        applyDocumentLocale("he");
      }
    });
  }, []);

  const setLocale = useCallback((next: Locale) => {
    if (!LOCALES.includes(next)) return;
    setLocaleState(next);
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch {
      /* ignore */
    }
    writeLocaleCookie(next);
    applyDocumentLocale(next);
  }, []);

  useEffect(() => {
    applyDocumentLocale(locale);
  }, [locale]);

  const value = useMemo<LocaleContextValue>(() => {
    const t = (path: string) =>
      translate(dictionaries, locale, path, "he");
    return { locale, setLocale, t };
  }, [locale, setLocale]);

  return (
    <LocaleContext.Provider value={value}>{children}</LocaleContext.Provider>
  );
}

export function useTranslation(): LocaleContextValue {
  const ctx = useContext(LocaleContext);
  if (!ctx) {
    throw new Error("useTranslation must be used within LocaleProvider");
  }
  return ctx;
}
