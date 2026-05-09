/** VETO Signature 2027 — ריכוז חוקי הזכוכית (Tailwind, פלטה כהה). */

export const glassPanel =
  "rounded-[40px] border border-white/10 bg-white/[0.04] shadow-[0_1px_0_rgba(255,255,255,0.04)_inset] backdrop-blur-xl";

export const glassPanelNested =
  "rounded-3xl border border-white/10 bg-slate-900/70 backdrop-blur-xl";

/** רכיבי כרטיס / סטט — פחות עגול מ-panels מלאים */
export const glassCard =
  "rounded-2xl border border-white/10 bg-white/[0.04] shadow-[0_1px_0_rgba(255,255,255,0.04)_inset] backdrop-blur-xl";

export const glassList =
  "divide-y divide-white/[0.06] overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03] backdrop-blur-xl";

export const glassInput =
  "w-full rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2.5 text-sm text-slate-100 outline-none transition placeholder:text-slate-500 focus:border-[#C5A059]/60 focus:ring-2 focus:ring-[#C5A059]/30 disabled:opacity-60";

// כפתורים
export const btnPrimaryGold =
  "rounded-lg bg-[#C5A059] font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition hover:bg-[#d4b06a] hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0";

export const btnPrimaryDark =
  "rounded-lg bg-[#C5A059] font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition hover:bg-[#d4b06a] hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0";

export const btnSecondaryGlass =
  "rounded-lg border border-white/10 bg-white/[0.04] text-slate-100 transition hover:bg-white/[0.08] disabled:opacity-50";

// === VETO Dark (Wave 1+) — פלטה כהה אחידה לכל החלונות ===

/** רקע מסך כהה — להחיל על מיכל root של דף. הרקע הגלובלי כבר כהה דרך layout. */
export const darkPage = "text-slate-100";

/** משטח עיקרי כהה — תחליף ל-glassPanel */
export const darkPanel =
  "rounded-2xl border border-white/10 bg-white/[0.04] shadow-[0_1px_0_rgba(255,255,255,0.04)_inset] backdrop-blur-xl";

/** כרטיס נמוך-בולט */
export const darkCard =
  "rounded-2xl border border-white/10 bg-slate-900/60 backdrop-blur-xl";

/** רשימה עם מפרידים */
export const darkList =
  "divide-y divide-white/[0.06] overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03] backdrop-blur-xl";

/** שדה קלט כהה */
export const darkInput =
  "w-full rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2.5 text-sm text-slate-100 outline-none transition placeholder:text-slate-500 focus:border-[#C5A059]/60 focus:ring-2 focus:ring-[#C5A059]/30 disabled:opacity-60";

/** כפתור ראשי בזהב */
export const darkBtnPrimary =
  "rounded-lg bg-[#C5A059] font-bold text-slate-950 shadow-[0_8px_32px_-8px_rgba(197,160,89,0.5)] transition hover:bg-[#d4b06a] hover:-translate-y-0.5 disabled:opacity-50 disabled:hover:translate-y-0";

/** כפתור משני שקוף */
export const darkBtnSecondary =
  "rounded-lg border border-white/10 bg-white/[0.04] font-semibold text-slate-100 transition hover:bg-white/[0.08] disabled:opacity-50";

/** הילת זהב לכותרות */
export const darkAccentText =
  "bg-gradient-to-b from-[#e8c987] via-[#C5A059] to-[#8a6d35] bg-clip-text text-transparent";

// בועות AI
export const glassBubbleUser =
  "rounded-2xl rounded-be-none border border-[#C5A059]/40 bg-[#C5A059]/15 text-slate-100 shadow-[0_2px_12px_-4px_rgba(197,160,89,0.3)]";

export const glassBubbleAssistant =
  "rounded-2xl rounded-bs-none border border-white/10 bg-white/[0.04] text-slate-100 backdrop-blur-lg";
