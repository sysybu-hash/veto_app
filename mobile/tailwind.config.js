/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#1e3a8a",
          light: "#2563eb",
          dark: "#172554",
        },
        background: "#ffffff",
        surface: "#f8fafc",
        "legal-slate": {
          DEFAULT: "#334155",
          muted: "#64748b",
          light: "#475569",
        },
        accent: {
          danger: "#991b1b",
          sos: "#b91c1c",
        },
      },
    },
  },
  plugins: [],
};
