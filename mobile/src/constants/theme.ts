/**
 * VETO Legal — design tokens (aligned with tailwind.config.js theme.extend.colors).
 * Prefer Tailwind classes in UI; use these when a raw value is required programmatically.
 */
export const theme = {
  colors: {
    primary: "#1e3a8a",
    primaryLight: "#2563eb",
    primaryDark: "#172554",
    background: "#ffffff",
    surface: "#f8fafc",
    slate: "#334155",
    slateMuted: "#64748b",
    slateLight: "#475569",
    accentDanger: "#991b1b",
    accentSos: "#b91c1c",
  },
} as const;

export type Theme = typeof theme;
