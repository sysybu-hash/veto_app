"use client";

import { useTranslation } from "@/lib/i18n/LocaleProvider";

/**
 * Wraps the existing `t()` so v2 components can declare their copy inline:
 *
 *   const tt = useTrWithFallback();
 *   tt("call.v2.preCheck.title", "Ready your call")
 *
 * `translate()` returns the key string unchanged when a translation is
 * missing, so we detect that exact case and substitute the fallback.
 * Once the i18n sweep adds the keys to he.ts/en.ts/ru.ts the fallback
 * is silently ignored.
 */
export function useTrWithFallback() {
  const { t } = useTranslation();
  return (key: string, fallback: string) => {
    const result = t(key);
    return result === key ? fallback : result;
  };
}
