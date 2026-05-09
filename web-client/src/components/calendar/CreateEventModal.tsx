"use client";

import { useCallback, useState } from "react";
import {
  btnPrimaryGold,
  btnSecondaryGlass,
  glassInput,
} from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export type CreateEventModalSubmit = {
  title: string;
  date: string;
  time: string;
  notes: string;
};

type Props = {
  open: boolean;
  onClose: () => void;
  onSubmit: (payload: CreateEventModalSubmit) => Promise<void>;
};

export function CreateEventModal({ open, onClose, onSubmit }: Props) {
  const { t } = useTranslation();
  const [title, setTitle] = useState("");
  const [date, setDate] = useState("");
  const [time, setTime] = useState("");
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reset = useCallback(() => {
    setTitle("");
    setDate("");
    setTime("");
    setNotes("");
    setError(null);
    setSubmitting(false);
  }, []);

  const handleClose = useCallback(() => {
    if (submitting) return;
    reset();
    onClose();
  }, [onClose, reset, submitting]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/40 p-0 backdrop-blur-sm sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="create-event-title"
    >
      <button
        type="button"
        className="absolute inset-0 cursor-default"
        aria-label={t("calendar.modalBackdropClose")}
        onClick={handleClose}
      />

      <div
        className="relative z-10 w-full max-w-md rounded-t-3xl border border-white/10 bg-white/[0.05] p-6 shadow-2xl shadow-slate-900/20 backdrop-blur-xl sm:rounded-3xl"
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <h2
            id="create-event-title"
            className="font-frank text-lg font-bold tracking-tight text-slate-100"
          >
            {t("calendar.modalTitle")}
          </h2>
          <button
            type="button"
            onClick={handleClose}
            disabled={submitting}
            className="rounded-lg p-1 text-slate-400 transition hover:bg-white/[0.04] hover:text-slate-100 disabled:opacity-50"
            aria-label={t("common.close")}
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              strokeWidth={1.75}
              viewBox="0 0 24 24"
            >
              <path d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form
          className="flex flex-col gap-4"
          onSubmit={async (e) => {
            e.preventDefault();
            setError(null);
            if (!title.trim() || !date || !time) {
              setError(t("calendar.requiredFields"));
              return;
            }
            setSubmitting(true);
            try {
              await onSubmit({
                title: title.trim(),
                date,
                time,
                notes: notes.trim(),
              });
              reset();
              onClose();
            } catch (err) {
              setError(
                err instanceof Error ? err.message : t("calendar.saveFailed"),
              );
            } finally {
              setSubmitting(false);
            }
          }}
        >
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-400">
              {t("calendar.fieldTitle")}
            </label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className={glassInput}
              placeholder={t("calendar.placeholderTitle")}
              autoComplete="off"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-400">
                {t("calendar.fieldDate")}
              </label>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className={glassInput}
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-slate-400">
                {t("calendar.fieldTime")}
              </label>
              <input
                type="time"
                value={time}
                onChange={(e) => setTime(e.target.value)}
                className={glassInput}
              />
            </div>
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-400">
              {t("calendar.fieldNotes")}
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className={`${glassInput} resize-none`}
              placeholder={t("calendar.placeholderNotes")}
            />
          </div>

          {error && (
            <p className="text-sm text-red-300" role="alert">
              {error}
            </p>
          )}

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={handleClose}
              disabled={submitting}
              className={`flex-1 py-3 text-sm ${btnSecondaryGlass} disabled:opacity-50`}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className={`flex-1 py-3 text-sm ${btnPrimaryGold} disabled:opacity-60`}
            >
              {submitting ? t("settings.saving") : t("calendar.saveEvent")}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
