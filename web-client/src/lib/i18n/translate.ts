import type { Dict } from "./types";
import type { Locale } from "./types";

export function lookup(dict: Dict, path: string): string | undefined {
  const parts = path.split(".").filter(Boolean);
  let cur: string | Dict | undefined = dict;
  for (const p of parts) {
    if (cur === undefined || typeof cur === "string") return undefined;
    cur = cur[p] as string | Dict | undefined;
  }
  return typeof cur === "string" ? cur : undefined;
}

export function translate(
  dictionaries: Record<Locale, Dict>,
  locale: Locale,
  path: string,
  fallbackLocale: Locale = "he",
): string {
  const hit = lookup(dictionaries[locale], path);
  if (hit != null) return hit;
  const fb = lookup(dictionaries[fallbackLocale], path);
  if (fb != null) return fb;
  if (fallbackLocale !== "he") {
    const heFb = lookup(dictionaries.he, path);
    if (heFb != null) return heFb;
  }
  return path;
}
