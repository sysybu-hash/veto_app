"use client";

import { useCallback, useState } from "react";
import {
  glassInput,
  glassPanelNested,
  modalBackdrop,
} from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";

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
      className={`fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-4 ${modalBackdrop}`}
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
        className={`relative z-10 w-full max-w-md rounded-t-3xl p-6 shadow-2xl sm:rounded-3xl ${glassPanelNested}`}
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <h2
            id="create-event-title"
            className="font-frank text-lg font-bold tracking-tight text-primary"
          >
            {t("calendar.modalTitle")}
          </h2>
          <IconButton
            variant="ghost"
            size="sm"
            onClick={handleClose}
            disabled={submitting}
            label={t("common.close")}
            icon={
              <svg className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={1.75} viewBox="0 0 24 24">
                <path d="M6 18L18 6M6 6l12 12" />
              </svg>
            }
          />
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
            <label className="mb-1 block text-xs font-medium text-secondary">
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
              <label className="mb-1 block text-xs font-medium text-secondary">
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
              <label className="mb-1 block text-xs font-medium text-secondary">
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
            <label className="mb-1 block text-xs font-medium text-secondary">
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
            <p className="text-sm text-red-600 dark:text-red-300" role="alert">
              {error}
            </p>
          )}

          <div className="flex gap-3 pt-2">
            <Button variant="secondary" size="lg" className="flex-1" onClick={handleClose} disabled={submitting}>
              {t("common.cancel")}
            </Button>
            <Button variant="primary" size="lg" className="flex-1" type="submit" loading={submitting}>
              {submitting ? t("settings.saving") : t("calendar.saveEvent")}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
