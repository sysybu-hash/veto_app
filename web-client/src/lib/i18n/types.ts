export type Locale = "he" | "en" | "ru";

export const LOCALES: Locale[] = ["he", "en", "ru"];

export const STORAGE_KEY = "veto_ui_locale";

/** Nested string dictionary leaves must be terminal strings */
export type Dict = { readonly [key: string]: string | Dict };
