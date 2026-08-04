"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  createEvent,
  deleteEvent,
  fetchEvents,
  updateEvent,
  type ApiCalendarEvent,
} from "@/api/calendarApi";
import { Button } from "@/components/ui/primitives/Button";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { citizenBottomSafe } from "@/lib/vetoGlass";
import { AgendaView } from "./AgendaView";
import { EventEditorModal, type EventEditorSave } from "./EventEditorModal";
import { GoogleCalendarCard } from "./GoogleCalendarCard";
import { IcalFeedButton } from "./IcalFeedButton";
import { MonthView } from "./MonthView";
import { WeekView } from "./WeekView";
import { startOfDay } from "./calendarUtils";

type ViewMode = "month" | "week" | "agenda";

export function CalendarShell() {
  const { t } = useTranslation();
  const [view, setView] = useState<ViewMode>("month");
  const [cursor, setCursor] = useState(() => startOfDay(new Date()));
  const [selectedDay, setSelectedDay] = useState(() => startOfDay(new Date()));
  const [events, setEvents] = useState<ApiCalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editorOpen, setEditorOpen] = useState(false);
  const [editing, setEditing] = useState<ApiCalendarEvent | null>(null);
  const [syncOpen, setSyncOpen] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const y = cursor.getFullYear();
      const m = cursor.getMonth() + 1;
      const prev = m === 1 ? { y: y - 1, m: 12 } : { y, m: m - 1 };
      const next = m === 12 ? { y: y + 1, m: 1 } : { y, m: m + 1 };
      const [a, b, c] = await Promise.all([
        fetchEvents(prev.y, prev.m),
        fetchEvents(y, m),
        fetchEvents(next.y, next.m),
      ]);
      const merged = [...a, ...b, ...c];
      const seen = new Set<string>();
      const unique: ApiCalendarEvent[] = [];
      for (const ev of merged) {
        if (seen.has(ev._id)) continue;
        seen.add(ev._id);
        unique.push(ev);
      }
      unique.sort(
        (x, y) => new Date(x.start).getTime() - new Date(y.start).getTime(),
      );
      setEvents(unique);
    } catch (e) {
      setEvents([]);
      setError(e instanceof Error ? e.message : t("calendar.loadFailed"));
    } finally {
      setLoading(false);
    }
  }, [cursor, t]);

  useEffect(() => {
    queueMicrotask(() => {
      void load();
    });
  }, [load]);

  // Snapshot once per mount — avoids impure Date.now() during render/useMemo.
  const [nowMs] = useState(() => Date.now());
  const upcomingSorted = useMemo(
    () =>
      events
        .filter((ev) => new Date(ev.end).getTime() >= nowMs - 60_000)
        .sort(
          (a, b) => new Date(a.start).getTime() - new Date(b.start).getTime(),
        ),
    [events, nowMs],
  );

  const openCreate = () => {
    setEditing(null);
    setEditorOpen(true);
  };

  const openEdit = (ev: ApiCalendarEvent) => {
    setEditing(ev);
    setEditorOpen(true);
  };

  const save = async (payload: EventEditorSave) => {
    if (editing) {
      await updateEvent(editing._id, payload);
    } else {
      await createEvent(payload);
    }
    await load();
  };

  const remove = async () => {
    if (!editing) return;
    await deleteEvent(editing._id);
    await load();
  };

  const tabs: { id: ViewMode; label: string }[] = [
    { id: "month", label: t("calendar.viewMonth") },
    { id: "week", label: t("calendar.viewWeek") },
    { id: "agenda", label: t("calendar.viewAgenda") },
  ];

  return (
    <div
      className={`mx-auto flex w-full max-w-6xl flex-col px-3 pt-3 sm:px-4 sm:pt-4 ${citizenBottomSafe}`}
    >
      <header className="flex flex-wrap items-center justify-between gap-2 border-b border-white/[0.06] pb-3">
        <div className="min-w-0">
          <h1 className="font-frank text-xl font-black tracking-tight text-primary sm:text-2xl">
            {t("calendar.heroTitle")}
          </h1>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setSyncOpen((v) => !v)}
            aria-expanded={syncOpen}
          >
            {t("calendar.syncToggle")}
          </Button>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => void load()}
            disabled={loading}
          >
            {t("calendar.refresh")}
          </Button>
          <Button variant="primary" size="sm" onClick={openCreate}>
            {t("calendar.newEvent")}
          </Button>
        </div>
      </header>

      {syncOpen ? (
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          <GoogleCalendarCard />
          <IcalFeedButton />
        </div>
      ) : null}

      <div
        className="mt-3 flex gap-1 rounded-xl border border-white/[0.06] bg-black/30 p-0.5"
        role="tablist"
        aria-label={t("calendar.viewsAria")}
      >
        {tabs.map((tab) => (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={view === tab.id}
            onClick={() => setView(tab.id)}
            className={`flex-1 rounded-lg px-2 py-1.5 text-sm font-bold transition ${
              view === tab.id
                ? "bg-veto-gold text-zinc-950 shadow"
                : "text-secondary hover:bg-white/[0.04]"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {error ? (
        <p className="mt-2 rounded-xl border border-red-500/30 bg-red-950/40 px-3 py-2 text-sm text-red-100">
          {error}
        </p>
      ) : null}

      <div className="mt-3 min-h-0 flex-1">
        {view === "month" ? (
          <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_280px] lg:items-start">
            <MonthView
              cursor={cursor}
              selectedDay={selectedDay}
              events={events}
              onCursorChange={setCursor}
              onSelectDay={(d) => {
                setSelectedDay(d);
                setCursor(new Date(d.getFullYear(), d.getMonth(), 1));
              }}
            />
            <AgendaView
              events={upcomingSorted}
              selectedDay={selectedDay}
              filterSelectedDay
              onOpenEvent={openEdit}
              onCreate={openCreate}
            />
          </div>
        ) : null}

        {view === "week" ? (
          <WeekView
            cursor={cursor}
            selectedDay={selectedDay}
            events={events}
            onCursorChange={setCursor}
            onSelectDay={setSelectedDay}
            onOpenEvent={openEdit}
          />
        ) : null}

        {view === "agenda" ? (
          <AgendaView
            events={upcomingSorted}
            selectedDay={selectedDay}
            filterSelectedDay={false}
            onOpenEvent={openEdit}
            onCreate={openCreate}
          />
        ) : null}
      </div>

      <EventEditorModal
        open={editorOpen}
        mode={editing ? "edit" : "create"}
        initial={editing}
        defaultDay={selectedDay}
        onClose={() => {
          setEditorOpen(false);
          setEditing(null);
        }}
        onSave={save}
        onDelete={editing ? remove : undefined}
      />
    </div>
  );
}
