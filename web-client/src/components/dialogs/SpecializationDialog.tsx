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
      <div className="w-full max-w-md overflow-hidden rounded-xl bg-white shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between border-b border-slate-100 p-6">
          <h2 className="text-xl font-bold text-slate-800">
            {t("dialog.chooseSpecialization")}
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={t("common.close")}
            className="text-slate-400 transition hover:text-slate-600"
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
                  ? "border-[#C5A059] bg-[#f6efe1]/50 text-slate-900 shadow-sm"
                  : "border-slate-200 bg-white text-slate-600 hover:border-slate-300 hover:bg-slate-50"
              }`}
            >
              <span className="text-2xl">{spec.icon}</span>
              <span>{t(spec.labelKey)}</span>
            </button>
          ))}
        </div>

        <div className="flex justify-end gap-3 border-t border-slate-100 bg-slate-50 p-6">
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-4 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-200"
          >
            {t("common.cancel")}
          </button>
          <button
            type="button"
            disabled={!selected}
            onClick={() => selected && onSelect(selected)}
            className={`rounded-md px-6 py-2 text-sm font-medium transition ${
              selected
                ? "bg-[#C5A059] text-white shadow-sm hover:bg-[#b08d4a]"
                : "cursor-not-allowed bg-slate-200 text-slate-400"
            }`}
          >
            {t("common.continue")}
          </button>
        </div>
      </div>
    </div>
  );
}
