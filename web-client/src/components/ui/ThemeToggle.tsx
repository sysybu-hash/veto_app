"use client";

import { useSyncExternalStore } from "react";
import {
  applyTheme,
  getStoredTheme,
  setStoredTheme,
  type Theme,
} from "@/components/providers/ThemeProvider";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

function useTr() {
  const { t } = useTranslation();
  return (key: string, fallback: string) => {
    const r = t(key);
    return r === key ? fallback : r;
  };
}

const STORAGE_KEY = "veto:theme";

function subscribeStorage(cb: () => void) {
  if (typeof window === "undefined") return () => {};
  const handler = (e: StorageEvent) => {
    if (e.key === STORAGE_KEY) cb();
  };
  window.addEventListener("storage", handler);
  return () => window.removeEventListener("storage", handler);
}

function readTheme(): Theme {
  if (typeof window === "undefined") return "light";
  const stored = getStoredTheme();
  if (stored) return stored;
  return window.matchMedia &&
    window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

function readServerTheme(): Theme {
  // Server snapshot — match the body's default (`veto-light`) to avoid
  // hydration mismatch warnings; the bootstrap script will have already
  // flipped to the right class before paint.
  return "light";
}

/**
 * ThemeToggle — sun / moon button that flips between light and dark.
 *
 * The button uses View Transitions (Phase 5) when available so the
 * crossfade between themes is smooth instead of an instant repaint.
 */
export function ThemeToggle({
  className = "",
}: {
  className?: string;
}) {
  const t = useTr();
  const theme = useSyncExternalStore(
    subscribeStorage,
    readTheme,
    readServerTheme,
  );

  function toggle() {
    const next: Theme = theme === "dark" ? "light" : "dark";
    const apply = () => {
      setStoredTheme(next);
      applyTheme(next);
    };
    const doc = document as unknown as {
      startViewTransition?: (cb: () => void) => unknown;
    };
    if (typeof doc.startViewTransition === "function") {
      doc.startViewTransition(apply);
    } else {
      apply();
    }
  }

  const isDark = theme === "dark";
  const label = isDark
    ? t("theme.switchToLight", "Switch to light theme")
    : t("theme.switchToDark", "Switch to dark theme");

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={label}
      title={label}
      className={`inline-flex h-9 w-9 items-center justify-center rounded-full border border-slate-300/70 bg-white/80 text-slate-900 shadow-sm transition hover:bg-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/60 ${className}`}
    >
      {isDark ? (
        // Sun icon — currently dark, click to go light
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-4 w-4"
          aria-hidden
        >
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
        </svg>
      ) : (
        // Moon icon — currently light, click to go dark
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="h-4 w-4"
          aria-hidden
        >
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      )}
    </button>
  );
}
