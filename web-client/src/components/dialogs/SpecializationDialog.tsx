"use client";

import { useEffect, useState } from "react";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { focusRing } from "@/lib/vetoGlass";
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

  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-[90] flex items-center justify-center bg-surface-scrim p-4 backdrop-blur-sm"
      role="presentation"
      onClick={onClose}
    >
      <div
        data-surface="stage"
        role="dialog"
        aria-modal="true"
        aria-labelledby="spec-dialog-title"
        className="w-full max-w-md overflow-hidden rounded-xl border border-subtle bg-surface-canvas shadow-2xl backdrop-blur-xl animate-in fade-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-subtle p-6">
          <h2 id="spec-dialog-title" className="text-xl font-bold text-primary">
            {t("dialog.chooseSpecialization")}
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={t("common.close")}
            className={`rounded-lg p-2 text-muted transition hover:bg-white/10 hover:text-white ${focusRing} focus-visible:ring-offset-slate-900`}
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
              className={`flex flex-col items-center gap-2 rounded-lg border p-4 text-sm font-medium transition ${focusRing} focus-visible:ring-offset-slate-900 ${
                selected === spec.id
                  ? "border-veto-gold bg-veto-gold/15 text-brand-100 shadow-[0_0_16px_rgba(197,160,89,0.25)]" : "border-subtle bg-white/[0.04] text-secondary hover:border-white/20 hover:bg-white/[0.08]"}`}
            >
              <span className="text-2xl">{spec.icon}</span>
              <span>{t(spec.labelKey)}</span>
            </button>
          ))}
        </div>

        <div className="flex justify-end gap-3 border-t border-subtle bg-surface-raised p-6">
          <button
            type="button"
            onClick={onClose}
            className={`rounded-md px-4 py-2 text-sm font-medium text-slate-300 transition hover:bg-white/[0.08] hover:text-white ${focusRing} focus-visible:ring-offset-slate-900`}
          >
            {t("common.cancel")}
          </button>
          <button
            type="button"
            disabled={!selected}
            onClick={() => selected && onSelect(selected)}
            className={`rounded-md px-6 py-2 text-sm font-bold transition ${focusRing} focus-visible:ring-offset-slate-900 ${
              selected
                ? "bg-veto-gold text-on-brand shadow-[0_8px_24px_-8px_rgba(197,160,89,0.5)] hover:bg-veto-gold-light" : "cursor-not-allowed bg-white/[0.06] text-muted"}`}
          >
            {t("common.continue")}
          </button>
        </div>
      </div>
    </div>
  );
}
