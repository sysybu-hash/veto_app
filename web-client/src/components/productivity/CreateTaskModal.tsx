"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  createTask,
  priorityRelatedType,
} from "@/api/productivityApi";

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
  const [form, setForm] = useState<NewTaskPayload>(emptyForm);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const titleRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (open) {
      setForm(emptyForm);
      setSubmitError(null);
      setIsSubmitting(false);
      queueMicrotask(() => titleRef.current?.focus());
    }
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
      setSubmitError(e instanceof Error ? e.message : "Could not create task");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/50 p-4 sm:items-center"
      role="presentation"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !isSubmitting) handleClose();
      }}
    >
      <div
        className="flex max-h-[min(90dvh,640px)] w-full max-w-lg flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
        role="dialog"
        aria-modal="true"
        aria-labelledby="task-modal-title"
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div>
            <h2
              id="task-modal-title"
              className="text-lg font-semibold text-slate-900"
            >
              New task
            </h2>
            <p className="mt-0.5 text-sm text-slate-500">
              Track something you need to complete for your case.
            </p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-40"
            aria-label="Close"
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
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500"
            >
              Task title
            </label>
            <input
              ref={titleRef}
              id="task-title"
              value={form.title}
              disabled={isSubmitting}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:bg-slate-50"
              placeholder="e.g. Submit national ID copy"
            />
          </div>
          <div>
            <label
              htmlFor="task-desc"
              className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500"
            >
              Description
            </label>
            <textarea
              id="task-desc"
              value={form.description}
              disabled={isSubmitting}
              onChange={(e) =>
                setForm((f) => ({ ...f, description: e.target.value }))
              }
              rows={4}
              className="w-full resize-y rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:bg-slate-50"
              placeholder="Add context, links, or notes..."
            />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label
                htmlFor="task-due"
                className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500"
              >
                Due date
              </label>
              <input
                id="task-due"
                type="date"
                value={form.dueDate}
                disabled={isSubmitting}
                onChange={(e) =>
                  setForm((f) => ({ ...f, dueDate: e.target.value }))
                }
                className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:bg-slate-50"
              />
            </div>
            <div>
              <label
                htmlFor="task-priority"
                className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-slate-500"
              >
                Priority
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
                className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:bg-slate-50"
              >
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
              </select>
            </div>
          </div>
          {submitError && (
            <p
              className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800"
              role="alert"
            >
              {submitError}
            </p>
          )}
        </div>

        <div className="flex gap-3 border-t border-slate-100 px-5 py-4">
          <button
            type="button"
            onClick={handleClose}
            disabled={isSubmitting}
            className="flex-1 rounded-xl border border-slate-200 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => void submit()}
            disabled={!form.title.trim() || isSubmitting}
            className="flex-1 rounded-xl bg-blue-600 py-3 text-sm font-semibold text-white hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isSubmitting ? "Saving…" : "Save task"}
          </button>
        </div>
      </div>
    </div>
  );
}
