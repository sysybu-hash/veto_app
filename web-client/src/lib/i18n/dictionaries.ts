import type { Dict } from "./types";
import type { Locale } from "./types";
import { en } from "./locales/en";
import { he } from "./locales/he";
import { ru } from "./locales/ru";

export const dictionaries: Record<Locale, Dict> = {
  he,
  en,
  ru,
};
