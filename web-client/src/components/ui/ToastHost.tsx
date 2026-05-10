"use client";

import { AnimatePresence, motion } from "framer-motion";
import { btnSecondaryGlass, glassPanelNested } from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";

const variantStyles: Record<string, string> = {
  success:
    "border-[#C5A059]/45 bg-[#C5A059]/15 text-slate-950 ring-1 ring-[#C5A059]/30",
  error: "border-red-300 bg-red-50 text-red-800 ring-1 ring-red-200",
  info: "border-slate-200 bg-white text-slate-900 ring-1 ring-slate-200",
  alert:
    "border-red-300 bg-gradient-to-br from-red-50 to-[#C5A059]/15 text-slate-950 ring-2 ring-red-300 shadow-[0_0_28px_rgba(239,68,68,0.18)]",
};

export function ToastHost() {
  const items = useToastStore((s) => s.items);
  const dismiss = useToastStore((s) => s.dismiss);

  return (
    <div
      className="pointer-events-none fixed start-4 end-4 top-20 z-[100] flex flex-col items-center gap-2 sm:items-stretch sm:ps-[min(24rem,calc(100%-2rem))]"
      dir="rtl"
    >
      <AnimatePresence mode="popLayout">
        {items.map((t) => (
          <motion.div
            key={t.id}
            layout
            initial={{ opacity: 0, y: -8, scale: 0.98 }}
            animate={
              t.variant === "alert"
                ? {
                    opacity: 1,
                    y: 0,
                    scale: [1, 1.02, 1],
                  }
                : { opacity: 1, y: 0, scale: 1 }
            }
            transition={
              t.variant === "alert"
                ? {
                    scale: {
                      repeat: Infinity,
                      duration: 1.85,
                      ease: "easeInOut",
                    },
                    opacity: { duration: 0.2 },
                    y: { duration: 0.2 },
                  }
                : { duration: 0.2 }
            }
            exit={{ opacity: 0, y: -6, scale: 0.98 }}
            className={`pointer-events-auto max-w-md backdrop-blur-xl ${glassPanelNested} px-4 py-3 text-sm font-medium shadow-lg ${variantStyles[t.variant] ?? variantStyles.info}`}
          >
            <div className="flex items-start gap-3">
              <p className="min-w-0 flex-1 leading-snug">{t.message}</p>
              <button
                type="button"
                onClick={() => dismiss(t.id)}
                className={`shrink-0 rounded-lg px-2 py-1 text-xs ${btnSecondaryGlass}`}
              >
                סגור
              </button>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
