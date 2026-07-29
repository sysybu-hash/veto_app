import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  {
    // Phase 3 UI-overhaul ratchet: flags hardcoded hex/slate Tailwind
    // classes that should be semantic tokens instead (see
    // src/app/globals.css + src/lib/vetoGlass.ts). `warn`, not `error` —
    // several routes are still mid-migration (see the plan's route
    // order). Once a route/directory finishes migrating, add a
    // directory-scoped override below raising it to `error` for that
    // path so it can't regress.
    rules: {
      "no-restricted-syntax": [
        "warn",
        {
          selector: "JSXAttribute[name.name='className'] Literal[value=/\\[#[0-9a-fA-F]{3,8}\\]/]",
          message: "Hardcoded hex color — use a semantic token from globals.css/vetoGlass.ts instead.",
        },
        {
          selector: "JSXAttribute[name.name='className'] Literal[value=/(text|bg|border|ring|divide)-slate-/]",
          message: "Hardcoded slate-* color — use a semantic token (text-primary/secondary/muted, border-subtle/default, ...) instead.",
        },
      ],
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // next-pwa generated service worker output (see next.config.mjs / .gitignore) —
    // minified/generated, not source; only present locally after `npm run build`.
    "public/sw.js",
    "public/workbox-*.js",
    "public/worker-*.js",
    "public/fallback-*.js",
    "public/swe-worker-*.js",
  ]),
]);

export default eslintConfig;
