"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  createTask,
  priorityRelatedType,
} from "@/api/productivityApi";
import {
  btnPrimaryGold,
  btnSecondaryGlass,
  glassInput,
  glassPanel,
  modalBackdrop,
  focusRing,
} from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export type NewTaskPayload = {
  title: string;
  description: string;
  dueDate: string;
  priority: "high" | "medium" | "low";
};

type CreateTaskModalProps = {
  open: boolean;
  onClose: () => void;
  onTaskCreated: () => void;
};

const emptyForm: NewTaskPayload = {
  title: "",
  description: "",
  dueDate: "",
  priority: "medium",
};

export function CreateTaskModal({
  open,
  onClose,
  onTaskCreated,
}: CreateTaskModalProps) {
  const { t } = useTranslation();
  const [form, setForm] = useState<NewTaskPayload>(emptyForm);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const titleRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    queueMicrotask(() => {
      setForm(emptyForm);
      setSubmitError(null);
      setIsSubmitting(false);
      queueMicrotask(() => titleRef.current?.focus());
    });
  }, [open]);

  const handleClose = useCallback(() => {
    if (isSubmitting) return;
    setForm(emptyForm);
    setSubmitError(null);
    onClose();
  }, [onClose, isSubmitting]);

  const submit = async () => {
    const title = form.title.trim();
    if (!title || isSubmitting) return;
    setSubmitError(null);
    setIsSubmitting(true);
    try {
      const dueAtRaw = form.dueDate.trim();
      const dueAt =
        dueAtRaw === ""
          ? undefined
          : new Date(`${dueAtRaw}T12:00:00`).toISOString();
      await createTask({
        title,
        description: form.description.trim(),
        dueAt,
        status: "open",
        relatedType: priorityRelatedType(form.priority),
      });
      setForm(emptyForm);
      onTaskCreated();
      onClose();
    } catch (e) {
      setSubmitError(
        e instanceof Error ? e.message : t("productivity.taskCreateFailed"),
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <div
      className={`fixed inset-0 z-[60] flex items-end justify-center p-4 sm:items-center ${modalBackdrop}`}
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !isSubmitting) handleClose();
      }}
    >
      <div
        className={`flex max-h-[min(90dvh,640px)] w-full max-w-lg flex-col overflow-hidden shadow-2xl shadow-slate-900/20 ${glassPanel}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="task-modal-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between border-b border-slate-200 px-5 py-4 dark:border-white/10">
          <div>
            <h2
              id="task-modal-title"
              className="font-frank text-lg font-bold text-slate-900 dark:text-slate-50"
            >
              {t("productivity.taskModalTitle")}
            </h2>
            <p className="mt-0.5 text-sm text-slate-600 dark:text-slate-400">
              {t("productivity.taskModalSubtitle")}
            </p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className={`rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-40 dark:text-slate-400 dark:hover:bg-white/10 dark:hover:text-slate-100 ${focusRing}`}
            aria-label={t("common.close")}
          >
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              viewBox="0 0 24 24"
            >
              <path d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-5 py-4">
          <div>
            <label
              htmlFor="task-title"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600 dark:text-slate-400"
            >
              {t("productivity.taskFieldTitle")}
            </label>
            <input
              ref={titleRef}
              id="task-title"
              value={form.title}
              disabled={isSubmitting}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              className={glassInput}
              placeholder={t("productivity.taskTitlePlaceholder")}
            />
          </div>
          <div>
            <label
              htmlFor="task-desc"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600 dark:text-slate-400"
            >
              {t("productivity.taskFieldDescription")}
            </label>
            <textarea
              id="task-desc"
              value={form.description}
              disabled={isSubmitting}
              onChange={(e) =>
                setForm((f) => ({ ...f, description: e.target.value }))
              }
              rows={4}
              className={`${glassInput} resize-y`}
              placeholder={t("productivity.taskDescriptionPlaceholder")}
            />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label
                htmlFor="task-due"
                className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600 dark:text-slate-400"
              >
                {t("productivity.taskFieldDue")}
              </label>
              <input
                id="task-due"
                type="date"
                value={form.dueDate}
                disabled={isSubmitting}
                onChange={(e) =>
                  setForm((f) => ({ ...f, dueDate: e.target.value }))
                }
                className={glassInput}
              />
            </div>
            <div>
              <label
                htmlFor="task-priority"
                className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-600 dark:text-slate-400"
              >
                {t("productivity.taskFieldPriority")}
              </label>
              <select
                id="task-priority"
                value={form.priority}
                disabled={isSubmitting}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    priority: e.target.value as NewTaskPayload["priority"],
                  }))
                }
                className={glassInput}
              >
                <option value="high">{t("productivity.priorityHigh")}</option>
                <option value="medium">{t("productivity.priorityMedium")}</option>
                <option value="low">{t("productivity.priorityLow")}</option>
              </select>
            </div>
          </div>
          {submitError && (
            <p
              className="rounded-xl border border-red-500/40 bg-red-500/15 px-3 py-2 text-sm text-red-200 backdrop-blur-sm"
              role="alert"
            >
              {submitError}
            </p>
          )}
        </div>

        <div className="flex gap-3 border-t border-slate-200 px-5 py-4 dark:border-white/10">
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className={`flex-1 py-3 text-sm ${btnSecondaryGlass} disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {t("common.cancel")}
          </button>
          <button
            type="button"
            onClick={() => void submit()}
            disabled={!form.title.trim() || isSubmitting}
            className={`flex-1 py-3 text-sm ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50`}
          >
            {isSubmitting ? t("settings.saving") : t("productivity.saveTask")}
          </button>
        </div>
      </div>
    </div>
  );
}
