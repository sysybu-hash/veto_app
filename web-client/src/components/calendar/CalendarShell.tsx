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
    void load();
  }, [load]);

  const upcomingSorted = useMemo(
    () =>
      events
        .filter((ev) => new Date(ev.end).getTime() >= Date.now() - 60_000)
        .sort(
          (a, b) => new Date(a.start).getTime() - new Date(b.start).getTime(),
        ),
    [events],
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
    <div className={`mx-auto w-full max-w-5xl px-4 pt-6 ${citizenBottomSafe}`}>
      <header className="relative overflow-hidden rounded-3xl border border-veto-gold/20 bg-gradient-to-br from-zinc-950 via-zinc-900 to-amber-950/40 px-5 py-6 shadow-[0_24px_80px_-40px_rgba(0,0,0,0.8)]">
        <div
          className="pointer-events-none absolute inset-0 opacity-40"
          style={{
            backgroundImage:
              "radial-gradient(ellipse 70% 60% at 80% 0%, rgba(197,160,89,0.35), transparent 55%)",
          }}
          aria-hidden
        />
        <div className="relative">
          <p className="text-[11px] font-black uppercase tracking-[0.28em] text-veto-gold">
            VETO
          </p>
          <h1 className="mt-2 font-frank text-3xl font-black tracking-tight text-primary sm:text-4xl">
            {t("calendar.heroTitle")}
          </h1>
          <p className="mt-2 max-w-xl text-sm leading-6 text-secondary">
            {t("calendar.heroSubtitle")}
          </p>
          <div className="mt-5 flex flex-wrap gap-2">
            <Button variant="primary" onClick={openCreate}>
              {t("calendar.newEvent")}
            </Button>
            <Button variant="secondary" onClick={() => void load()} disabled={loading}>
              {t("calendar.refresh")}
            </Button>
          </div>
        </div>
      </header>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <GoogleCalendarCard />
        <IcalFeedButton />
      </div>

      <div
        className="mt-5 flex gap-1 rounded-2xl border border-white/[0.06] bg-black/30 p-1"
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
            className={`flex-1 rounded-xl px-3 py-2 text-sm font-bold transition ${
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
        <p className="mt-3 rounded-xl border border-red-500/30 bg-red-950/40 px-3 py-2 text-sm text-red-100">
          {error}
        </p>
      ) : null}

      <div className="mt-4 space-y-4">
        {view === "month" ? (
          <>
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
          </>
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
