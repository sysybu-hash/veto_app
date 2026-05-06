"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  createEvent,
  fetchUpcomingEvents,
  getGoogleAuthUrl,
  type ApiCalendarEvent,
} from "@/api/calendarApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { CreateEventModal } from "@/components/calendar/CreateEventModal";
import { getJwt } from "@/lib/authToken";

function combineDateTimeToIsoRange(dateStr: string, timeStr: string): {
  start: string;
  end: string;
} {
  const start = new Date(`${dateStr}T${timeStr}:00`);
  const end = new Date(start.getTime() + 60 * 60 * 1000);
  return { start: start.toISOString(), end: end.toISOString() };
}

const MOCK_EVENTS: ApiCalendarEvent[] = [
  {
    _id: "mock-1",
    title: "Consultation — contract review",
    type: "meeting",
    start: new Date(Date.now() + 86400000).toISOString(),
    end: new Date(Date.now() + 86400000 + 3600000).toISOString(),
    notes: "Bring signed draft and ID.",
  },
  {
    _id: "mock-2",
    title: "Small claims hearing (placeholder)",
    type: "hearing",
    start: new Date(Date.now() + 86400000 * 3).toISOString(),
    end: new Date(Date.now() + 86400000 * 3 + 7200000).toISOString(),
    notes: "Example entry when your calendar is empty.",
  },
];

function formatEventWhen(ev: ApiCalendarEvent): { dateLine: string; timeLine: string } {
  const start = new Date(ev.start);
  const end = new Date(ev.end);
  const dateLine = start.toLocaleDateString(undefined, {
    weekday: "short",
    month: "short",
    day: "numeric",
    year: start.getFullYear() !== new Date().getFullYear() ? "numeric" : undefined,
  });
  const timeLine = `${start.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  })} – ${end.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  })}`;
  return { dateLine, timeLine };
}

export default function CitizenCalendarPage() {
  const router = useRouter();
  const [events, setEvents] = useState<ApiCalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [usingMock, setUsingMock] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [syncBusy, setSyncBusy] = useState(false);
  const [syncError, setSyncError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!getJwt()) return;
    setLoading(true);
    setLoadError(null);
    try {
      const list = await fetchUpcomingEvents();
      if (list.length === 0) {
        setEvents(MOCK_EVENTS);
        setUsingMock(true);
      } else {
        setEvents(list);
        setUsingMock(false);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Failed to load calendar";
      setLoadError(msg);
      setEvents(MOCK_EVENTS);
      setUsingMock(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    void load();
  }, [router, load]);

  const handleGoogleSync = async () => {
    setSyncError(null);
    setSyncBusy(true);
    try {
      const { url } = await getGoogleAuthUrl();
      window.location.href = url;
    } catch (e) {
      setSyncError(e instanceof Error ? e.message : "Could not start Google sync");
      setSyncBusy(false);
    }
  };

  const sortedDisplay = useMemo(() => events, [events]);

  return (
    <>
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col gap-6 px-4 py-8 pb-28">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-white">
            My Legal Calendar
          </h1>
          <p className="mt-1 text-sm text-slate-400">
            Hearings, meetings, and deadlines in one place.
          </p>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <button
            type="button"
            onClick={() => void handleGoogleSync()}
            disabled={syncBusy}
            className="inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-white px-4 py-3.5 text-sm font-semibold text-slate-900 shadow-lg shadow-black/20 transition hover:bg-slate-100 disabled:opacity-60 sm:flex-1"
          >
            <svg
              className="h-5 w-5"
              viewBox="0 0 24 24"
              aria-hidden
            >
              <path
                fill="currentColor"
                d="M19.5 12h-15v-3h15v3zm0 4.5h-15v-3h15v3zm0-9h-15V4.5h15V7.5z"
              />
            </svg>
            {syncBusy ? "Opening Google…" : "Sync with Google Calendar"}
          </button>
          <button
            type="button"
            onClick={() => setModalOpen(true)}
            className="inline-flex w-full items-center justify-center rounded-2xl border-2 border-blue-500/60 bg-blue-600/15 px-4 py-3.5 text-sm font-semibold text-blue-100 shadow-[0_0_20px_rgba(37,99,235,0.25)] transition hover:bg-blue-600/25 sm:w-auto sm:shrink-0"
          >
            New Event
          </button>
        </div>
        {syncError && (
          <p className="rounded-xl border border-red-500/30 bg-red-950/40 px-3 py-2 text-sm text-red-200">
            {syncError}
          </p>
        )}
        {usingMock && (
          <p className="rounded-xl border border-amber-500/25 bg-amber-950/30 px-3 py-2 text-xs text-amber-100/90">
            Showing sample events until your calendar has entries
            {loadError ? ` (API: ${loadError})` : ""}.
          </p>
        )}

        <section className="rounded-2xl border border-white/10 bg-slate-900/60 p-4 backdrop-blur-sm">
          <h2 className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-500">
            Upcoming
          </h2>
          {loading ? (
            <ul className="space-y-3">
              {[1, 2, 3].map((i) => (
                <li
                  key={i}
                  className="h-24 animate-pulse rounded-xl bg-white/5"
                />
              ))}
            </ul>
          ) : sortedDisplay.length === 0 ? (
            <p className="py-8 text-center text-sm text-slate-500">
              No upcoming events.
            </p>
          ) : (
            <ul className="space-y-3">
              {sortedDisplay.map((ev) => {
                const { dateLine, timeLine } = formatEventWhen(ev);
                return (
                  <li
                    key={ev._id}
                    className="rounded-xl border border-white/5 bg-slate-950/50 px-4 py-3"
                  >
                    <div className="flex flex-wrap items-baseline justify-between gap-2">
                      <span className="text-xs font-medium text-blue-300/90">
                        {dateLine}
                      </span>
                      <span className="text-xs text-slate-500">{timeLine}</span>
                    </div>
                    <h3 className="mt-1 text-base font-semibold text-white">
                      {ev.title}
                    </h3>
                    {ev.notes ? (
                      <p className="mt-1 line-clamp-2 text-sm text-slate-400">
                        {ev.notes}
                      </p>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </main>

      <CreateEventModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onSubmit={async ({ title, date, time, notes }) => {
          const { start, end } = combineDateTimeToIsoRange(date, time);
          const created = await createEvent({ title, start, end, notes });
          setUsingMock(false);
          setEvents((prev) => {
            const next = prev.filter((e) => !e._id.startsWith("mock-"));
            const merged = [...next, created];
            return merged.sort(
              (a, b) =>
                new Date(a.start).getTime() - new Date(b.start).getTime(),
            );
          });
        }}
      />

      <CitizenBottomNav active="calendar" />
    </>
  );
}
