"use client";

import { useEffect } from "react";

/**
 * ThemeProvider — Phase 5 dark mode restoration.
 *
 * History: commit `22ee246` switched VETO to a light-only theme by adding
 * the `.veto-light` class to <body>. Internal class names still encode
 * a dark base (slate-900, white/15, etc.), so removing `.veto-light`
 * automatically restores dark mode without rewriting components.
 *
 * Strategy:
 *   - The pre-paint inline script (`themeBootstrapScript`) reads the
 *     persisted preference from localStorage (or `prefers-color-scheme`)
 *     and adds / removes `.veto-light` *before* React hydrates. This
 *     prevents a flash of the wrong theme on first paint.
 *   - This component only re-runs when storage changes in another tab
 *     so multiple windows stay in sync.
 *
 * The actual toggle button lives in `ThemeToggle.tsx`.
 */

const STORAGE_KEY = "veto:theme";

export type Theme = "light" | "dark";

export function getStoredTheme(): Theme | null {
  if (typeof window === "undefined") return null;
  const v = window.localStorage.getItem(STORAGE_KEY);
  return v === "dark" || v === "light" ? v : null;
}

export function setStoredTheme(t: Theme) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(STORAGE_KEY, t);
  applyTheme(t);
  // Synthetic StorageEvent so useSyncExternalStore subscribers in the
  // same tab notice the change (the native one only fires across tabs).
  try {
    window.dispatchEvent(
      new StorageEvent("storage", { key: STORAGE_KEY, newValue: t }),
    );
  } catch {
    /* StorageEvent constructor not supported (very old browsers) */
  }
}

export function applyTheme(t: Theme) {
  if (typeof document === "undefined") return;
  const body = document.body;
  if (!body) return;
  if (t === "light") {
    body.classList.add("veto-light");
    body.classList.remove("veto-dark");
  } else {
    body.classList.remove("veto-light");
    body.classList.add("veto-dark");
  }
  // Update the theme-color meta so mobile browser chrome matches.
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) {
    meta.setAttribute("content", t === "dark" ? "#0f172a" : "#eef1f5");
  }
}

/**
 * Inline script string injected via <Script strategy="beforeInteractive">.
 * Runs before React hydrates so the body class is correct on first paint.
 */
export const themeBootstrapScript = `
(function () {
  try {
    var key = "${STORAGE_KEY}";
    var stored = window.localStorage.getItem(key);
    var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    var theme = stored === 'dark' || stored === 'light'
      ? stored
      : (prefersDark ? 'dark' : 'light');
    var body = document.body;
    if (!body) {
      // body not parsed yet on early head injection; defer.
      window.addEventListener('DOMContentLoaded', function () {
        document.body.classList.toggle('veto-light', theme === 'light');
        document.body.classList.toggle('veto-dark', theme === 'dark');
      });
    } else {
      body.classList.toggle('veto-light', theme === 'light');
      body.classList.toggle('veto-dark', theme === 'dark');
    }
  } catch (_) { /* no-op */ }
})();
`;

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Cross-tab sync.
    const onStorage = (e: StorageEvent) => {
      if (e.key !== STORAGE_KEY) return;
      const v = e.newValue;
      if (v === "dark" || v === "light") applyTheme(v);
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  return <>{children}</>;
}
