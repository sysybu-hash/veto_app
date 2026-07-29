"use client";

import { motion } from "framer-motion";
import { Lock, Shield } from "lucide-react";

const BAR_COUNT = 14;

function WaveformBar({ delay }: { delay: number }) {
  return (
    <motion.div
      className="w-[3px] origin-bottom rounded-full bg-veto-gold/90"
      style={{ height: 32 }}
      initial={false}
      animate={{
        scaleY: [0.35, 1, 0.5, 0.85, 0.4],
      }}
      transition={{
        duration: 1.15,
        repeat: Infinity,
        ease: "easeInOut",
        delay,
      }}
    />
  );
}

export function LivePreviewMockup() {
  return (
    <figure
      className="relative mx-auto w-full max-w-[300px]"
      aria-label="תצוגה מקדימה: שיחת חירום פעילה עם הצפנה"
    >
      <motion.div
        data-surface="stage"
        initial={{ opacity: 0, y: 16 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-40px" }}
        transition={{ duration: 0.5, ease: "easeOut" }}
        className="relative rounded-panel border border-subtle bg-gradient-to-b from-slate-900/95 to-black p-2 shadow-[0_24px_80px_-20px_rgba(197,160,89,0.35)]"
      >
        <div className="flex justify-center pt-1">
          <div className="h-1.5 w-16 rounded-full bg-white/20" aria-hidden />
        </div>

        <div className="overflow-hidden rounded-panel border border-subtle bg-surface-canvas">
          {/* Status bar */}
          <div className="flex items-center justify-between border-b border-white/5 px-4 pb-2 pt-7">
            <span className="text-[10px] font-bold tabular-nums text-muted">
              09:41
            </span>
            <div className="flex items-center gap-1.5">
              <motion.span
                className="h-2 w-2 rounded-full bg-red-500"
                animate={{ opacity: [1, 0.4, 1] }}
                transition={{ duration: 1.2, repeat: Infinity }}
                aria-hidden
              />
              <span className="text-[9px] font-black uppercase tracking-wider text-red-400">
                REC
              </span>
            </div>
          </div>

          <div className="space-y-5 p-4">
            {/* Waveform */}
            <div className="flex h-12 items-end justify-center gap-[3px] px-1">
              {Array.from({ length: BAR_COUNT }, (_, i) => (
                <WaveformBar key={i} delay={i * 0.08} />
              ))}
            </div>

            {/* Lawyer placeholder */}
            <div className="flex flex-col items-center text-center">
              <motion.div
                className="relative flex h-28 w-28 items-center justify-center rounded-full bg-gradient-to-br from-veto-gold/50 via-slate-600 to-slate-900 text-xl font-black text-primary shadow-inner ring-2 ring-veto-gold/30"
                animate={{ boxShadow: ["0 0 0 0 rgba(197,160,89,0.35)", "0 0 0 12px rgba(197,160,89,0)", "0 0 0 0 rgba(197,160,89,0)"] }}
                transition={{ duration: 2.2, repeat: Infinity, ease: "easeOut" }}
              >
                עו״ד
                <span className="absolute -bottom-1 rounded-full border border-emerald-400/50 bg-emerald-500/20 px-2 py-0.5 text-[9px] font-bold text-emerald-300">
                  E2EE
                </span>
              </motion.div>
              <p className="mt-4 text-sm font-bold text-primary">עו״ד בשיחה</p>
              <p className="mt-1 text-[11px] text-muted">וידאו מוצפן · חיבור יציב</p>
            </div>

            {/* Badges row */}
            <div className="flex flex-wrap items-center justify-center gap-2">
              <span className="inline-flex items-center gap-1.5 rounded-full border border-subtle bg-white/5 px-3 py-1.5 text-[10px] font-semibold text-veto-gold backdrop-blur-sm">
                <Shield className="h-3.5 w-3.5" aria-hidden />
                מפתחות מקומיים
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-subtle bg-white/5 px-3 py-1.5 text-[10px] font-semibold text-primary backdrop-blur-sm">
                <Lock className="h-3.5 w-3.5 text-veto-gold" aria-hidden />
                סוף לסוף
              </span>
            </div>

            {/* PiP citizen */}
            <div className="flex justify-end">
              <div className="flex items-center gap-2 rounded-2xl border border-subtle bg-surface-raised p-2 pe-3 backdrop-blur-md">
                <div className="h-11 w-11 rounded-xl bg-gradient-to-br from-slate-700 to-slate-900 ring-1 ring-white/10" />
                <div className="text-start">
                  <p className="text-[10px] font-bold text-secondary">אתה</p>
                  <p className="text-[9px] text-muted">מצלמה כבויה</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </motion.div>
    </figure>
  );
}
