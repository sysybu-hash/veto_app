/**
 * VETO light interface tokens — centralized Tailwind class bundles.
 *
 * Phase 5: brand colours now reference the `@theme` tokens defined in
 * `globals.css` (`veto-gold`, `veto-gold-light`, `veto-gold-dark`,
 * `veto-gold-deep`). This keeps inline `[#C5A059]` literals out of new
 * code paths so a future re-skin only touches CSS variables.
 */

export const glassPanel =
  "rounded-[28px] border border-slate-200/80 bg-white/85 text-slate-950 shadow-[0_18px_50px_-30px_rgba(15,23,42,0.25)] backdrop-blur-xl";

export const glassPanelNested =
  "rounded-2xl border border-slate-200/80 bg-white/90 text-slate-950 shadow-[0_10px_32px_-26px_rgba(15,23,42,0.25)] backdrop-blur-xl";

export const glassCard =
  "rounded-2xl border border-slate-200/80 bg-white/85 text-slate-950 shadow-sm backdrop-blur-xl";

export const glassList =
  "divide-y divide-slate-200 overflow-hidden rounded-2xl border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-xl";

export const glassInput =
  "w-full rounded-xl border border-slate-300 bg-white/95 px-3 py-2.5 text-sm font-semibold text-slate-950 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 disabled:opacity-60";

export const btnPrimaryGold =
  "rounded-lg bg-veto-gold font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition hover:-translate-y-0.5 hover:bg-veto-gold-light disabled:opacity-50 disabled:hover:translate-y-0";

export const btnPrimaryDark = btnPrimaryGold;

export const btnSecondaryGlass =
  "rounded-lg border border-slate-300 bg-white/90 font-semibold text-slate-900 shadow-sm transition hover:border-slate-400 hover:bg-white disabled:opacity-50";

export const darkPage = "text-slate-950";

export const darkPanel =
  "rounded-2xl border border-slate-200/80 bg-white/85 text-slate-950 shadow-sm backdrop-blur-xl";

export const darkCard =
  "rounded-2xl border border-slate-200/80 bg-white/90 text-slate-950 backdrop-blur-xl";

export const darkList =
  "divide-y divide-slate-200 overflow-hidden rounded-2xl border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-xl";

export const darkInput =
  "w-full rounded-xl border border-slate-300 bg-white/95 px-3 py-2.5 text-sm font-semibold text-slate-950 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/70 focus:ring-2 focus:ring-veto-gold/25 disabled:opacity-60";

export const darkBtnPrimary = btnPrimaryGold;

export const darkBtnSecondary = btnSecondaryGlass;

export const darkAccentText =
  "bg-gradient-to-b from-veto-gold-dark via-veto-gold to-veto-gold-deep bg-clip-text text-transparent";

export const glassBubbleUser =
  "rounded-2xl rounded-be-none border border-veto-gold/45 bg-veto-gold/20 text-slate-950 shadow-[0_2px_12px_-4px_rgba(197,160,89,0.25)]";

export const glassBubbleAssistant =
  "rounded-2xl rounded-bs-none border border-slate-200 bg-white/90 text-slate-950 backdrop-blur-lg";

/** Dark “VETO glass” — login / register on `bg-veto-ink` */
export const authGlassPanel =
  "rounded-[28px] border border-white/10 bg-white/5 text-slate-100 shadow-[0_24px_64px_rgba(0,0,0,0.45)] backdrop-blur-xl";

export const authGlassInput =
  "w-full rounded-xl border border-white/10 bg-white/[0.06] px-3 py-2.5 text-sm font-semibold text-slate-100 outline-none transition placeholder:text-slate-500 focus:border-veto-gold/50 focus:ring-2 focus:ring-veto-gold/20 disabled:opacity-60";

export const authBtnSecondary =
  "rounded-lg border border-white/15 bg-white/[0.06] font-semibold text-slate-100 shadow-sm transition hover:border-white/25 hover:bg-white/[0.1] disabled:opacity-50";

export const authBtnPasskey =
  "rounded-xl border border-veto-gold/40 bg-veto-gold/15 font-bold text-veto-gold shadow-[0_8px_32px_-8px_rgba(197,160,89,0.35)] transition hover:border-veto-gold/60 hover:bg-veto-gold/25 disabled:opacity-50";
