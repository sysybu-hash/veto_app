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
import type { Locale } from "@/lib/i18n/types";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  btnPrimaryGold,
  btnSecondaryGlass,
  glassPanel,
} from "@/lib/vetoGlass";

function combineDateTimeToIsoRange(dateStr: string, timeStr: string): {
  start: string;
  end: string;
} {
  const start = new Date(`${dateStr}T${timeStr}:00`);
  const end = new Date(start.getTime() + 60 * 60 * 1000);
  return { start: start.toISOString(), end: end.toISOString() };
}

function localeBcp47(locale: Locale): string {
  switch (locale) {
    case "he":
      return "he-IL";
    case "ru":
      return "ru-RU";
    default:
      return "en-US";
  }
}

function buildMockEvents(tr: (key: string) => string): ApiCalendarEvent[] {
  return [
    {
      _id: "mock-1",
      title: tr("calendar.mockEvent1Title"),
      type: "meeting",
      start: new Date(Date.now() + 86400000).toISOString(),
      end: new Date(Date.now() + 86400000 + 3600000).toISOString(),
      notes: tr("calendar.mockEvent1Notes"),
    },
    {
      _id: "mock-2",
      title: tr("calendar.mockEvent2Title"),
      type: "hearing",
      start: new Date(Date.now() + 86400000 * 3).toISOString(),
      end: new Date(Date.now() + 86400000 * 3 + 7200000).toISOString(),
      notes: tr("calendar.mockEvent2Notes"),
    },
  ];
}

function formatEventWhen(
  ev: ApiCalendarEvent,
  locale: Locale,
): { dateLine: string; timeLine: string } {
  const tag = localeBcp47(locale);
  const start = new Date(ev.start);
  const end = new Date(ev.end);
  const dateLine = start.toLocaleDateString(tag, {
    weekday: "short",
    month: "short",
    day: "numeric",
    year:
      start.getFullYear() !== new Date().getFullYear() ? "numeric" : undefined,
  });
  const timeLine = `${start.toLocaleTimeString(tag, {
    hour: "numeric",
    minute: "2-digit",
  })} – ${end.toLocaleTimeString(tag, {
    hour: "numeric",
    minute: "2-digit",
  })}`;
  return { dateLine, timeLine };
}

function daysInCalendarMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate();
}

/** Transparent grid: `border-white/20`, selected / event days use gold glow. */
function CalendarMonthGrid({ events }: { events: ApiCalendarEvent[] }) {
  const { t, locale } = useTranslation();
  const [cursor, setCursor] = useState(() => new Date());
  const [selectedDay, setSelectedDay] = useState<number | null>(() => {
    const t = new Date();
    return t.getDate();
  });

  const y = cursor.getFullYear();
  const m = cursor.getMonth();
  const dim = daysInCalendarMonth(y, m);
  const firstDow = new Date(y, m, 1).getDay();

  const eventDays = useMemo(() => {
    const s = new Set<number>();
    for (const ev of events) {
      const d = new Date(ev.start);
      if (
        !Number.isNaN(d.getTime()) &&
        d.getFullYear() === y &&
        d.getMonth() === m
      ) {
        s.add(d.getDate());
      }
    }
    return s;
  }, [events, y, m]);

  const today = new Date();
  const isToday = (day: number) =>
    today.getFullYear() === y && today.getMonth() === m && today.getDate() === day;

  const cells: (number | null)[] = [];
  for (let i = 0; i < firstDow; i++) cells.push(null);
  for (let d = 1; d <= dim; d++) cells.push(d);

  const monthLabel = cursor.toLocaleDateString(localeBcp47(locale), {
    month: "long",
    year: "numeric",
  });

  const shiftMonth = (delta: number) => {
    setCursor((c) => new Date(c.getFullYear(), c.getMonth() + delta, 1));
    setSelectedDay(null);
  };

  const weekdayLabels = [
    t("calendar.daySun"),
    t("calendar.dayMon"),
    t("calendar.dayTue"),
    t("calendar.dayWed"),
    t("calendar.dayThu"),
    t("calendar.dayFri"),
    t("calendar.daySat"),
  ];

  return (
    <section className={`${glassPanel} p-4`}>
      <div className="mb-3 flex items-center justify-between gap-2">
        <button
          type="button"
          onClick={() => shiftMonth(-1)}
          className={`${btnSecondaryGlass} px-3 py-1.5 text-xs`}
          aria-label={t("calendar.prevMonthAria")}
        >
          ‹
        </button>
        <h2 className="font-frank text-center text-sm font-bold text-slate-900">
          {monthLabel}
        </h2>
        <button
          type="button"
          onClick={() => shiftMonth(1)}
          className={`${btnSecondaryGlass} px-3 py-1.5 text-xs`}
          aria-label={t("calendar.nextMonthAria")}
        >
          ›
        </button>
      </div>
      <div className="mb-1 grid grid-cols-7 gap-1 text-center text-[10px] font-semibold uppercase tracking-wide text-slate-600">
        {weekdayLabels.map((d) => (
          <div key={d}>{d}</div>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1">
        {cells.map((day, idx) =>
          day == null ? (
            <div key={`empty-${idx}`} className="aspect-square bg-transparent" />
          ) : (
            <button
              type="button"
              key={day}
              onClick={() => setSelectedDay(day)}
              className={`flex aspect-square flex-col items-center justify-center rounded-lg border text-sm font-semibold transition ${
                selectedDay === day
                  ? "border-[#C5A059] bg-[#C5A059]/30 text-slate-900 shadow-[0_0_16px_rgba(197,160,89,0.45)]"
                  : eventDays.has(day)
                    ? "border-[#C5A059]/50 bg-transparent text-slate-900 hover:bg-white/20"
                    : "border-white/20 bg-transparent text-slate-900 hover:bg-white/25"
              } ${isToday(day) ? "ring-2 ring-white/70" : ""}`}
            >
              <span>{day}</span>
              {eventDays.has(day) ? (
                <span
                  className="mt-0.5 h-1 w-1 shrink-0 rounded-full bg-[#C5A059] shadow-[0_0_8px_rgba(197,160,89,0.9)]"
                  aria-hidden
                />
              ) : (
                <span className="mt-0.5 h-1 w-1 shrink-0" aria-hidden />
              )}
            </button>
          ),
        )}
      </div>
    </section>
  );
}

export default function CitizenCalendarPage() {
  const { t, locale } = useTranslation();
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
    const mocks = buildMockEvents(t);
    try {
      const list = await fetchUpcomingEvents();
      if (list.length === 0) {
        setEvents(mocks);
        setUsingMock(true);
      } else {
        setEvents(list);
        setUsingMock(false);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : t("calendar.loadFailed");
      setLoadError(msg);
      setEvents(mocks);
      setUsingMock(true);
    } finally {
      setLoading(false);
    }
  }, [t]);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => {
      void load();
    });
  }, [router, load]);

  const handleGoogleSync = async () => {
    setSyncError(null);
    setSyncBusy(true);
    try {
      const { url } = await getGoogleAuthUrl();
      window.location.href = url;
    } catch (e) {
      setSyncError(
        e instanceof Error ? e.message : t("calendar.syncFailed"),
      );
      setSyncBusy(false);
    }
  };

  const sortedDisplay = useMemo(() => events, [events]);

  return (
    <>
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col gap-6 px-4 py-8 pb-28">
        <div>
          <h1 className="font-frank text-2xl font-bold tracking-tight text-slate-900">
            {t("calendar.heroTitle")}
          </h1>
          <p className="mt-1 text-sm text-slate-600">
            {t("calendar.heroSubtitle")}
          </p>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <button
            type="button"
            onClick={() => void handleGoogleSync()}
            disabled={syncBusy}
            className={`inline-flex w-full items-center justify-center gap-2 px-4 py-3.5 text-sm sm:flex-1 ${btnSecondaryGlass} disabled:opacity-60`}
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
            {syncBusy ? t("calendar.openingGoogle") : t("calendar.syncGoogle")}
          </button>
          <button
            type="button"
            onClick={() => setModalOpen(true)}
            className={`inline-flex w-full items-center justify-center px-4 py-3.5 text-sm sm:w-auto sm:shrink-0 ${btnPrimaryGold}`}
          >
            {t("calendar.newEvent")}
          </button>
        </div>
        {syncError && (
          <p className="rounded-xl border border-red-300/70 bg-white/50 px-3 py-2 text-sm text-red-900 backdrop-blur-xl">
            {syncError}
          </p>
        )}
        {usingMock && (
          <p className="rounded-xl border border-amber-300/60 bg-white/50 px-3 py-2 text-xs text-amber-900 backdrop-blur-xl">
            {loadError
              ? t("calendar.mockEventsBannerDetail").replace(
                  "{detail}",
                  loadError,
                )
              : t("calendar.mockEventsBanner")}
          </p>
        )}

        <CalendarMonthGrid events={sortedDisplay} />

        <section className={`${glassPanel} p-4`}>
          <h2 className="mb-3 font-frank text-xs font-bold uppercase tracking-wider text-slate-900">
            {t("calendar.upcoming")}
          </h2>
          {loading ? (
            <ul className="space-y-3">
              {[1, 2, 3].map((i) => (
                <li
                  key={i}
                  className="h-24 animate-pulse rounded-xl bg-white/30 backdrop-blur-md"
                />
              ))}
            </ul>
          ) : sortedDisplay.length === 0 ? (
            <p className="py-8 text-center text-sm text-slate-600">
              {t("calendar.noUpcoming")}
            </p>
          ) : (
            <ul className="space-y-3">
              {sortedDisplay.map((ev) => {
                const { dateLine, timeLine } = formatEventWhen(ev, locale);
                return (
                  <li
                    key={ev._id}
                    className="rounded-xl border border-white/40 bg-white/40 px-4 py-3 shadow-sm backdrop-blur-md"
                  >
                    <div className="flex flex-wrap items-baseline justify-between gap-2">
                      <span className="text-xs font-semibold text-[#8a6d3d] drop-shadow-sm">
                        {dateLine}
                      </span>
                      <span className="text-xs text-slate-600">{timeLine}</span>
                    </div>
                    <h3 className="mt-1 font-frank text-base font-bold text-slate-900">
                      {ev.title}
                    </h3>
                    {ev.notes ? (
                      <p className="mt-1 line-clamp-2 text-sm text-slate-600">
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
