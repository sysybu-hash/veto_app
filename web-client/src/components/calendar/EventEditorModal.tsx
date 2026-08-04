"use client";

import { useState } from "react";
import type { ApiCalendarEvent, CalendarEventType } from "@/api/calendarApi";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassInput, glassPanelNested, modalBackdrop } from "@/lib/vetoGlass";
import {
  combineLocalRange,
  toDateInputValue,
  toTimeInputValue,
} from "./calendarUtils";

export type EventEditorSave = {
  title: string;
  type: CalendarEventType;
  start: string;
  end: string;
  notes: string;
  locationAddress: string;
  reminderBeforeMinutes: number[];
};

type Props = {
  open: boolean;
  mode: "create" | "edit";
  initial?: ApiCalendarEvent | null;
  defaultDay?: Date | null;
  onClose: () => void;
  onSave: (payload: EventEditorSave) => Promise<void>;
  onDelete?: () => Promise<void>;
};

const REMINDER_OPTS = [0, 15, 60, 1440] as const;

function formDefaults(initial?: ApiCalendarEvent | null, defaultDay?: Date | null) {
  if (initial) {
    const s = new Date(initial.start);
    const e = new Date(initial.end);
    return {
      title: initial.title,
      type: (initial.type || "other") as CalendarEventType,
      date: toDateInputValue(s),
      startTime: toTimeInputValue(s),
      endTime: toTimeInputValue(e),
      notes: initial.notes || "",
      locationAddress: initial.locationAddress || "",
      reminders: initial.reminderBeforeMinutes?.length
        ? initial.reminderBeforeMinutes
        : [15, 60],
    };
  }
  const base = defaultDay || new Date();
  return {
    title: "",
    type: "meeting" as CalendarEventType,
    date: toDateInputValue(base),
    startTime: "09:00",
    endTime: "10:00",
    notes: "",
    locationAddress: "",
    reminders: [15, 60],
  };
}

/**
 * Remount via `key` when open/edit target changes so form state is initialized
 * without setState-in-effect (ESLint react-hooks/set-state-in-effect).
 */
export function EventEditorModal({
  open,
  mode,
  initial,
  defaultDay,
  onClose,
  onSave,
  onDelete,
}: Props) {
  if (!open) return null;
  const editorKey = initial?._id ?? `new-${defaultDay?.toISOString() ?? "blank"}`;
  return (
    <EventEditorForm
      key={editorKey}
      mode={mode}
      initial={initial}
      defaultDay={defaultDay}
      onClose={onClose}
      onSave={onSave}
      onDelete={onDelete}
    />
  );
}

function EventEditorForm({
  mode,
  initial,
  defaultDay,
  onClose,
  onSave,
  onDelete,
}: Omit<Props, "open">) {
  const { t } = useTranslation();
  const defaults = formDefaults(initial, defaultDay);
  const [title, setTitle] = useState(defaults.title);
  const [type, setType] = useState<CalendarEventType>(defaults.type);
  const [date, setDate] = useState(defaults.date);
  const [startTime, setStartTime] = useState(defaults.startTime);
  const [endTime, setEndTime] = useState(defaults.endTime);
  const [notes, setNotes] = useState(defaults.notes);
  const [locationAddress, setLocation] = useState(defaults.locationAddress);
  const [reminders, setReminders] = useState<number[]>(defaults.reminders);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const toggleReminder = (n: number) => {
    setReminders((prev) =>
      prev.includes(n) ? prev.filter((x) => x !== n) : [...prev, n].sort((a, b) => a - b),
    );
  };

  const submit = async () => {
    if (!title.trim() || !date || !startTime || !endTime) {
      setError(t("calendar.requiredFields"));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const range = combineLocalRange(date, startTime, endTime);
      await onSave({
        title: title.trim(),
        type,
        start: range.start,
        end: range.end,
        notes: notes.trim(),
        locationAddress: locationAddress.trim(),
        reminderBeforeMinutes: reminders,
      });
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : t("calendar.saveFailed"));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      className={`fixed inset-0 z-[90] flex items-end justify-center p-0 sm:items-center sm:p-4 ${modalBackdrop}`}
      role="dialog"
      aria-modal="true"
      aria-labelledby="event-editor-title"
    >
      <button
        type="button"
        className="absolute inset-0 cursor-default"
        aria-label={t("calendar.modalBackdropClose")}
        onClick={() => !busy && onClose()}
      />
      <div
        className={`relative z-10 max-h-[92dvh] w-full max-w-lg overflow-y-auto rounded-t-3xl p-6 shadow-2xl sm:rounded-3xl ${glassPanelNested}`}
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <h2 id="event-editor-title" className="font-frank text-lg font-bold text-primary">
            {mode === "edit" ? t("calendar.editEvent") : t("calendar.modalTitle")}
          </h2>
          <IconButton
            variant="ghost"
            size="sm"
            onClick={onClose}
            disabled={busy}
            label={t("calendar.close")}
            icon={<span aria-hidden>✕</span>}
          />
        </div>

        <div className="space-y-3">
          <label className="block text-xs font-bold text-muted">
            {t("calendar.fieldTitle")}
            <input
              className={`mt-1 w-full ${glassInput}`}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t("calendar.placeholderTitle")}
            />
          </label>

          <label className="block text-xs font-bold text-muted">
            {t("calendar.fieldType")}
            <select
              className={`mt-1 w-full ${glassInput}`}
              value={type}
              onChange={(e) => setType(e.target.value as CalendarEventType)}
            >
              <option value="hearing">{t("calendar.typeHearing")}</option>
              <option value="meeting">{t("calendar.typeMeeting")}</option>
              <option value="other">{t("calendar.typeOther")}</option>
            </select>
          </label>

          <div className="grid grid-cols-2 gap-2">
            <label className="block text-xs font-bold text-muted">
              {t("calendar.fieldDate")}
              <input
                type="date"
                className={`mt-1 w-full ${glassInput}`}
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </label>
            <div className="grid grid-cols-2 gap-2">
              <label className="block text-xs font-bold text-muted">
                {t("calendar.fieldStart")}
                <input
                  type="time"
                  className={`mt-1 w-full ${glassInput}`}
                  value={startTime}
                  onChange={(e) => setStartTime(e.target.value)}
                />
              </label>
              <label className="block text-xs font-bold text-muted">
                {t("calendar.fieldEnd")}
                <input
                  type="time"
                  className={`mt-1 w-full ${glassInput}`}
                  value={endTime}
                  onChange={(e) => setEndTime(e.target.value)}
                />
              </label>
            </div>
          </div>

          <label className="block text-xs font-bold text-muted">
            {t("calendar.fieldLocation")}
            <input
              className={`mt-1 w-full ${glassInput}`}
              value={locationAddress}
              onChange={(e) => setLocation(e.target.value)}
              placeholder={t("calendar.placeholderLocation")}
            />
          </label>

          <fieldset>
            <legend className="text-xs font-bold text-muted">{t("calendar.fieldReminders")}</legend>
            <div className="mt-2 flex flex-wrap gap-2">
              {REMINDER_OPTS.map((n) => (
                <button
                  key={n}
                  type="button"
                  onClick={() => toggleReminder(n)}
                  className={`rounded-full px-3 py-1 text-xs font-bold transition ${
                    reminders.includes(n)
                      ? "bg-veto-gold text-zinc-950"
                      : "border border-subtle text-secondary"
                  }`}
                >
                  {n === 0
                    ? t("calendar.reminderAtStart")
                    : n === 1440
                      ? t("calendar.reminder1d")
                      : t("calendar.reminderMin").replace("{n}", String(n))}
                </button>
              ))}
            </div>
          </fieldset>

          <label className="block text-xs font-bold text-muted">
            {t("calendar.fieldNotes")}
            <textarea
              className={`mt-1 min-h-[80px] w-full ${glassInput}`}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={t("calendar.placeholderNotes")}
            />
          </label>
        </div>

        {error ? <p className="mt-3 text-sm text-red-300">{error}</p> : null}

        <div className="mt-5 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          {mode === "edit" && onDelete ? (
            <Button
              variant="secondary"
              className="border-red-500/40 text-red-200"
              disabled={busy}
              onClick={() => {
                void (async () => {
                  if (!window.confirm(t("calendar.deleteConfirm"))) return;
                  setBusy(true);
                  try {
                    await onDelete();
                    onClose();
                  } catch (e) {
                    setError(e instanceof Error ? e.message : t("calendar.deleteFailed"));
                  } finally {
                    setBusy(false);
                  }
                })();
              }}
            >
              {t("calendar.delete")}
            </Button>
          ) : null}
          <Button variant="secondary" disabled={busy} onClick={onClose}>
            {t("calendar.close")}
          </Button>
          <Button variant="primary" loading={busy} onClick={() => void submit()}>
            {t("calendar.saveEvent")}
          </Button>
        </div>
      </div>
    </div>
  );
}
