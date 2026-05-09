"use client";

import { useState } from "react";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import type { SpecializationId } from "@/lib/specializations";

type SpecializationDialogProps = {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (specializationId: SpecializationId) => void;
};

const SPECIALIZATIONS: ReadonlyArray<{
  id: SpecializationId;
  labelKey: string;
  icon: string;
}> = [
  { id: "criminal", labelKey: "specialization.criminal", icon: "⚖️" },
  { id: "traffic", labelKey: "specialization.traffic", icon: "🚗" },
  { id: "civil", labelKey: "specialization.civil", icon: "📄" },
  { id: "family", labelKey: "specialization.family", icon: "👨‍👩‍👧‍👦" },
  { id: "labor", labelKey: "specialization.labor", icon: "💼" },
  { id: "general", labelKey: "specialization.general", icon: "🚨" },
];

export function SpecializationDialog({
  isOpen,
  onClose,
  onSelect,
}: SpecializationDialogProps) {
  const { t } = useTranslation();
  const [selected, setSelected] = useState<SpecializationId | null>(null);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[90] flex items-center justify-center bg-slate-900/40 p-4 backdrop-blur-sm">
      <div className="w-full max-w-md overflow-hidden rounded-xl border border-white/10 bg-slate-900/95 shadow-2xl backdrop-blur-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between border-b border-white/10 p-6">
          <h2 className="text-xl font-bold text-slate-100">
            {t("dialog.chooseSpecialization")}
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={t("common.close")}
            className="text-slate-400 transition hover:text-white"
          >
            ✕
          </button>
        </div>

        <div className="grid grid-cols-2 gap-3 p-6">
          {SPECIALIZATIONS.map((spec) => (
            <button
              key={spec.id}
              type="button"
              onClick={() => setSelected(spec.id)}
              className={`flex flex-col items-center gap-2 rounded-lg border p-4 text-sm font-medium transition ${
                selected === spec.id
                  ? "border-[#C5A059] bg-[#C5A059]/15 text-[#e8c987] shadow-[0_0_16px_rgba(197,160,89,0.25)]"
                  : "border-white/10 bg-white/[0.04] text-slate-200 hover:border-white/20 hover:bg-white/[0.08]"
              }`}
            >
              <span className="text-2xl">{spec.icon}</span>
              <span>{t(spec.labelKey)}</span>
            </button>
          ))}
        </div>

        <div className="flex justify-end gap-3 border-t border-white/10 bg-slate-950/60 p-6">
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-white/[0.08] hover:text-white"
          >
            {t("common.cancel")}
          </button>
          <button
            type="button"
            disabled={!selected}
            onClick={() => selected && onSelect(selected)}
            className={`rounded-md px-6 py-2 text-sm font-bold transition ${
              selected
                ? "bg-[#C5A059] text-slate-950 shadow-[0_8px_24px_-8px_rgba(197,160,89,0.5)] hover:bg-[#d4b06a]"
                : "cursor-not-allowed bg-white/[0.06] text-slate-500"
            }`}
          >
            {t("common.continue")}
          </button>
        </div>
      </div>
    </div>
  );
}
