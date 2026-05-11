"use client";

import { useEffect } from "react";

const STORAGE_KEY = "veto:theme";
/** Http-readable cookie so the server can render the correct `veto-light` / `veto-dark` classes (avoids React wiping body-only script classes). */
export const THEME_COOKIE = "veto-theme";
const COOKIE_MAX_AGE_SEC = 60 * 60 * 24 * 400;

export type Theme = "light" | "dark";

export function getStoredTheme(): Theme | null {
  if (typeof window === "undefined") return null;
  const v = window.localStorage.getItem(STORAGE_KEY);
  return v === "dark" || v === "light" ? v : null;
}

function writeThemeCookie(t: Theme) {
  if (typeof document === "undefined") return;
  document.cookie = `${THEME_COOKIE}=${t};path=/;max-age=${COOKIE_MAX_AGE_SEC};SameSite=Lax`;
}

export function setStoredTheme(t: Theme) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, t);
  applyTheme(t);
  try {
    window.dispatchEvent(
      new CustomEvent("veto-theme-change", { detail: t }),
    );
    window.dispatchEvent(
      new StorageEvent("storage", { key: STORAGE_KEY, newValue: t }),
    );
  } catch {
    /* StorageEvent constructor not supported (very old browsers) */
  }
}

/**
 * Apply theme to both `html` and `body` so Tailwind `dark:` variants and
 * legacy `.veto-light` / `.veto-dark` CSS keep working after React hydration.
 */
export function applyTheme(t: Theme) {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  const body = document.body;
  const light = t === "light";
  if (root) {
    root.classList.toggle("veto-light", light);
    root.classList.toggle("veto-dark", !light);
    root.style.colorScheme = light ? "light" : "dark";
  }
  if (body) {
    body.classList.toggle("veto-light", light);
    body.classList.toggle("veto-dark", !light);
  }
  writeThemeCookie(t);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute("content", light ? "#eef1f5" : "#0f172a");
  }
}

export const themeBootstrapScript = `
(function () {
  try {
    var key = "${STORAGE_KEY}";
    var cookieKey = "${THEME_COOKIE}";
    function readCookie(name) {
      var parts = ('; ' + document.cookie).split('; ' + name + '=');
      if (parts.length === 2) return decodeURIComponent(parts.pop().split(';').shift() || '');
      return null;
    }
    var stored = window.localStorage.getItem(key);
    var fromCookie = readCookie(cookieKey);
    var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    var theme = stored === 'dark' || stored === 'light'
      ? stored
      : (fromCookie === 'dark' || fromCookie === 'light' ? fromCookie : (prefersDark ? 'dark' : 'light'));
    var light = theme === 'light';
    var root = document.documentElement;
    if (root) {
      root.classList.toggle('veto-light', light);
      root.classList.toggle('veto-dark', !light);
      root.style.colorScheme = light ? 'light' : 'dark';
    }
    function applyBody() {
      var b = document.body;
      if (!b) return;
      b.classList.toggle('veto-light', light);
      b.classList.toggle('veto-dark', !light);
    }
    if (!document.body) {
      window.addEventListener('DOMContentLoaded', applyBody);
    } else {
      applyBody();
    }
  } catch (_) { /* no-op */ }
})();
`;

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key !== STORAGE_KEY) return;
      const v = e.newValue;
      if (v === "dark" || v === "light") applyTheme(v);
    };
    const onSameTab = (e: Event) => {
      const d = (e as CustomEvent<Theme>).detail;
      if (d === "dark" || d === "light") applyTheme(d);
    };
    window.addEventListener("storage", onStorage);
    window.addEventListener("veto-theme-change", onSameTab);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("veto-theme-change", onSameTab);
    };
  }, []);

  return <>{children}</>;
}
