/**
 * VETO light interface tokens — centralized Tailwind class bundles.
 *
 * Phase 5: brand colours now reference the `@theme` tokens defined in
 * `globals.css` (`veto-gold`, `veto-gold-light`, `veto-gold-dark`,
 * `veto-gold-deep`). This keeps inline `[#C5A059]` literals out of new
 * code paths so a future re-skin only touches CSS variables.
 */

/** Standard modal scrim — pair with `glassPanel` / `glassPanelNested` content */
export const modalBackdrop =
  "bg-slate-900/50 backdrop-blur-sm dark:bg-black/55";

/** Extra bottom padding for routes with `CitizenBottomNav` + home indicator */
export const citizenBottomSafe =
  "pb-[calc(7rem+env(safe-area-inset-bottom))]";

/** Visible keyboard focus — compose on custom icon buttons / chips */
export const focusRing =
  "outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/60 focus-visible:ring-offset-2 focus-visible:ring-offset-veto-canvas dark:focus-visible:ring-offset-veto-ink";

export const glassPanel =
  "rounded-[28px] border border-slate-200/80 bg-white/85 text-slate-950 shadow-[0_18px_50px_-30px_rgba(15,23,42,0.25)] backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/88 dark:text-slate-50 dark:shadow-[0_24px_64px_-28px_rgba(0,0,0,0.65)]";

export const glassPanelNested =
  "rounded-2xl border border-slate-200/80 bg-white/90 text-slate-950 shadow-[0_10px_32px_-26px_rgba(15,23,42,0.25)] backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/92 dark:text-slate-50 dark:shadow-[0_16px_48px_-24px_rgba(0,0,0,0.55)]";

export const glassCard =
  "rounded-2xl border border-slate-200/80 bg-white/85 text-slate-950 shadow-sm backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/85 dark:text-slate-50";

export const glassList =
  "divide-y divide-slate-200 overflow-hidden rounded-2xl border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-xl dark:divide-white/10 dark:border-white/10 dark:bg-slate-900/90 dark:text-slate-50";

export const glassInput =
  "w-full rounded-xl border border-slate-300 bg-white/95 px-3 py-2.5 text-sm font-semibold text-slate-950 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 focus-visible:ring-2 focus-visible:ring-veto-gold/40 disabled:opacity-60 dark:border-white/15 dark:bg-slate-950/80 dark:text-slate-100 dark:placeholder:text-slate-500";

export const btnPrimaryGold =
  "rounded-lg bg-veto-gold font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition hover:-translate-y-0.5 hover:bg-veto-gold-light disabled:opacity-50 disabled:hover:translate-y-0 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold-dark/50 focus-visible:ring-offset-2 focus-visible:ring-offset-veto-canvas dark:focus-visible:ring-offset-veto-ink";

export const btnPrimaryDark = btnPrimaryGold;

export const btnSecondaryGlass =
  "rounded-lg border border-slate-300 bg-white/90 font-semibold text-slate-900 shadow-sm transition hover:border-slate-400 hover:bg-white disabled:opacity-50 dark:border-white/15 dark:bg-white/8 dark:text-slate-100 dark:hover:border-white/25 dark:hover:bg-white/12 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/55 focus-visible:ring-offset-2 focus-visible:ring-offset-veto-canvas dark:focus-visible:ring-offset-veto-ink";

export const darkPage = "text-slate-950";

export const darkPanel =
  "rounded-2xl border border-slate-200/80 bg-white/85 text-slate-950 shadow-sm backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/85 dark:text-slate-50";

export const darkCard =
  "rounded-2xl border border-slate-200/80 bg-white/90 text-slate-950 backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/88 dark:text-slate-50";

export const darkList =
  "divide-y divide-slate-200 overflow-hidden rounded-2xl border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-xl dark:divide-white/10 dark:border-white/10 dark:bg-slate-900/90 dark:text-slate-50";

export const darkInput =
  "w-full rounded-xl border border-slate-300 bg-white/95 px-3 py-2.5 text-sm font-semibold text-slate-950 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 disabled:opacity-60 dark:border-white/15 dark:bg-slate-950/80 dark:text-slate-100";

export const darkBtnPrimary = btnPrimaryGold;

export const darkBtnSecondary = btnSecondaryGlass;

export const darkAccentText =
  "bg-gradient-to-b from-veto-gold-dark via-veto-gold to-veto-gold-deep bg-clip-text text-transparent";

export const glassBubbleUser =
  "rounded-2xl rounded-be-none border border-veto-gold/45 bg-veto-gold/20 text-slate-950 shadow-[0_2px_12px_-4px_rgba(197,160,89,0.25)] dark:border-veto-gold/40 dark:bg-veto-gold/15 dark:text-slate-50";

export const glassBubbleAssistant =
  "rounded-2xl rounded-bs-none border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-lg dark:border-white/12 dark:bg-slate-800/90 dark:text-slate-100";

/** Dark “VETO glass” — login / register on `bg-veto-ink` */
export const authGlassPanel =
  "rounded-[28px] border border-white/10 bg-white/5 text-slate-100 shadow-[0_24px_64px_rgba(0,0,0,0.45)] backdrop-blur-xl";

export const authGlassInput =
  "w-full rounded-xl border border-white/10 bg-white/[0.06] px-3 py-2.5 text-sm font-semibold text-slate-100 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/50 focus:ring-2 focus:ring-veto-gold/20 focus-visible:ring-2 focus-visible:ring-veto-gold/45 disabled:opacity-60";

export const authBtnSecondary =
  "rounded-lg border border-white/15 bg-white/[0.06] font-semibold text-slate-100 shadow-sm transition hover:border-white/25 hover:bg-white/[0.1] disabled:opacity-50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/50 focus-visible:ring-offset-2 focus-visible:ring-offset-veto-ink";

export const authBtnPasskey =
  "rounded-xl border border-veto-gold/40 bg-veto-gold/15 font-bold text-veto-gold shadow-[0_8px_32px_-8px_rgba(197,160,89,0.35)] transition hover:border-veto-gold/60 hover:bg-veto-gold/25 disabled:opacity-50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold/60 focus-visible:ring-offset-2 focus-visible:ring-offset-veto-ink";
