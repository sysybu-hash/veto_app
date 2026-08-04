/**
 * VETO interface tokens — centralized Tailwind class bundles.
 *
 * Phase 1 (UI overhaul): every bundle below is built from the semantic,
 * dual-mode tokens defined in `globals.css` (`surface-*`, `text-*`/`primary`
 * `secondary`/`muted`, `border-*`/`subtle`/`default`, `brand-*`, `shadow-*`,
 * `radius-*`). Because each token already has a light AND dark value under
 * the same CSS variable name, none of these bundles need a `dark:` variant
 * anymore — the previous "light base + `dark:` override" pattern is gone.
 *
 * This is what makes it safe to eventually delete the `.veto-light
 * [class*="..."]` substring overrides in `globals.css`: those overrides
 * only exist to patch up hardcoded `slate-*`/`white` classes, and nothing
 * in this file uses those anymore.
 *
 * Every export name from the previous version is preserved so existing
 * call sites keep working untouched; names marked `@deprecated` are pure
 * aliases kept only for backwards compatibility — do not import them in
 * new code, use the primary name instead.
 */

/** Standard modal scrim — pair with `glassPanel` / `glassPanelNested` content */
export const modalBackdrop = "bg-surface-scrim backdrop-blur-sm";

/** Extra bottom padding for routes with `CitizenBottomNav` + home indicator (mobile only) */
export const citizenBottomSafe =
  "pb-[calc(7rem+env(safe-area-inset-bottom))] md:pb-6";

/** Visible keyboard focus — compose on custom icon buttons / chips */
export const focusRing =
  "outline-none focus-visible:ring-2 focus-visible:ring-focus/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas";

export const glassPanel =
  "rounded-panel border border-subtle bg-surface-raised text-primary shadow-panel backdrop-blur-xl";

export const glassPanelNested =
  "rounded-lg border border-subtle bg-surface-raised-2 text-primary shadow-card backdrop-blur-xl";

export const glassCard =
  "rounded-lg border border-subtle bg-surface-raised text-primary shadow-sm backdrop-blur-xl";

export const glassList =
  "divide-y divide-subtle overflow-hidden rounded-lg border border-subtle bg-surface-raised-2 text-primary backdrop-blur-xl";

export const glassInput =
  "w-full rounded-md border border-default bg-surface-overlay px-3 py-2.5 text-sm font-semibold text-primary outline-none transition placeholder:text-muted focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 focus-visible:ring-2 focus-visible:ring-veto-gold/40 disabled:opacity-50";

export const btnPrimaryGold =
  "rounded-sm bg-veto-gold font-bold text-on-brand shadow-brand-glow transition hover:-translate-y-0.5 hover:bg-veto-gold-light disabled:opacity-50 disabled:hover:translate-y-0 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold-dark/50 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas";

/** @deprecated alias of `btnPrimaryGold` */
export const btnPrimaryDark = btnPrimaryGold;

export const btnSecondaryGlass =
  "rounded-sm border border-default bg-surface-raised-2 font-semibold text-primary shadow-sm transition hover:border-strong hover:bg-surface-overlay disabled:opacity-50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/55 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas";

/** @deprecated use `text-primary` directly */
export const darkPage = "text-primary";

/** @deprecated alias of `glassPanel` */
export const darkPanel = glassPanel;

/** @deprecated alias of `glassCard` */
export const darkCard = glassCard;

/** @deprecated alias of `glassList` */
export const darkList = glassList;

/** @deprecated alias of `glassInput` */
export const darkInput = glassInput;

/** @deprecated alias of `btnPrimaryGold` */
export const darkBtnPrimary = btnPrimaryGold;

/** @deprecated alias of `btnSecondaryGlass` */
export const darkBtnSecondary = btnSecondaryGlass;

export const darkAccentText =
  "bg-gradient-to-b from-veto-gold-dark via-veto-gold to-veto-gold-deep bg-clip-text text-transparent";

export const glassBubbleUser =
  "rounded-2xl rounded-be-none border border-veto-gold/45 bg-veto-gold/20 text-primary shadow-[0_2px_12px_-4px_rgba(197,160,89,0.25)]";

export const glassBubbleAssistant =
  "rounded-2xl rounded-bs-none border border-subtle bg-surface-raised-2 text-primary backdrop-blur-lg";

/**
 * Login/register hero surface — always renders as the dark "ink" surface
 * regardless of site theme. Backed by `[data-surface="ink"]` in
 * globals.css, so wrap the hero container with `data-surface="ink"`.
 */
export const authGlassPanel =
  "rounded-panel border border-subtle bg-surface-raised text-primary shadow-modal backdrop-blur-xl";

export const authGlassInput =
  "w-full rounded-md border border-subtle bg-surface-raised px-3 py-2.5 text-sm font-semibold text-primary outline-none transition placeholder:text-muted focus:border-veto-gold/50 focus:ring-2 focus:ring-veto-gold/20 focus-visible:ring-2 focus-visible:ring-veto-gold/45 disabled:opacity-50";

export const authBtnSecondary =
  "rounded-sm border border-subtle bg-surface-raised font-semibold text-primary shadow-sm transition hover:border-default hover:bg-surface-raised-2 disabled:opacity-50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/50 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas";

export const authBtnPasskey =
  "rounded-md border border-veto-gold/40 bg-veto-gold/15 font-bold text-veto-gold shadow-brand-glow transition hover:border-veto-gold/60 hover:bg-veto-gold/25 disabled:opacity-50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/60 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-canvas";
