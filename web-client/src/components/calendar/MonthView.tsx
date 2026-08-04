"use client";

import type { ApiCalendarEvent } from "@/api/calendarApi";
import { IconButton } from "@/components/ui/primitives/IconButton";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";
import {
  addDays,
  eventTypeDot,
  eventsOnDay,
  localeBcp47,
  sameDay,
  startOfDay,
} from "./calendarUtils";

type Props = {
  cursor: Date;
  selectedDay: Date;
  events: ApiCalendarEvent[];
  onCursorChange: (d: Date) => void;
  onSelectDay: (d: Date) => void;
};

export function MonthView({
  cursor,
  selectedDay,
  events,
  onCursorChange,
  onSelectDay,
}: Props) {
  const { t, locale } = useTranslation();
  const tag = localeBcp47(locale);
  const year = cursor.getFullYear();
  const month = cursor.getMonth();
  const first = new Date(year, month, 1);
  const gridStart = addDays(first, -first.getDay());
  const cells = Array.from({ length: 42 }, (_, i) => addDays(gridStart, i));
  const today = startOfDay(new Date());

  const monthLabel = cursor.toLocaleDateString(tag, {
    month: "long",
    year: "numeric",
  });

  const weekdays = [
    t("calendar.daySun"),
    t("calendar.dayMon"),
    t("calendar.dayTue"),
    t("calendar.dayWed"),
    t("calendar.dayThu"),
    t("calendar.dayFri"),
    t("calendar.daySat"),
  ];

  return (
    <section className={`${glassPanelNested} overflow-hidden p-3 sm:p-4`}>
      <div className="mb-3 flex items-center justify-between gap-2">
        <IconButton
          variant="ghost"
          size="sm"
          label={t("calendar.prevMonthAria")}
          onClick={() => onCursorChange(new Date(year, month - 1, 1))}
          icon={<span aria-hidden>‹</span>}
        />
        <h3 className="font-frank text-base font-bold capitalize text-primary sm:text-lg">
          {monthLabel}
        </h3>
        <IconButton
          variant="ghost"
          size="sm"
          label={t("calendar.nextMonthAria")}
          onClick={() => onCursorChange(new Date(year, month + 1, 1))}
          icon={<span aria-hidden>›</span>}
        />
      </div>

      <div className="grid grid-cols-7 gap-1 text-center text-[10px] font-bold uppercase tracking-wide text-muted sm:text-xs">
        {weekdays.map((d) => (
          <div key={d} className="py-1">
            {d}
          </div>
        ))}
      </div>

      <div className="mt-1 grid grid-cols-7 gap-1">
        {cells.map((day) => {
          const inMonth = day.getMonth() === month;
          const selected = sameDay(day, selectedDay);
          const isToday = sameDay(day, today);
          const dayEvents = eventsOnDay(events, day);
          return (
            <button
              key={day.toISOString()}
              type="button"
              onClick={() => onSelectDay(day)}
              className={`relative flex min-h-[3.25rem] flex-col items-center rounded-xl px-0.5 py-1 text-sm transition duration-200 sm:min-h-[4rem] ${
                selected
                  ? "bg-veto-gold/20 ring-2 ring-veto-gold/70"
                  : "hover:bg-white/[0.04]"
              } ${inMonth ? "text-primary" : "text-muted/50"}`}
            >
              <span
                className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold ${
                  isToday ? "bg-veto-gold text-zinc-950" : ""
                }`}
              >
                {day.getDate()}
              </span>
              <span className="mt-0.5 flex max-w-full gap-0.5 overflow-hidden">
                {dayEvents.slice(0, 3).map((ev) => (
                  <span
                    key={ev._id}
                    className={`h-1.5 w-1.5 shrink-0 rounded-full ${eventTypeDot(ev.type)}`}
                  />
                ))}
              </span>
            </button>
          );
        })}
      </div>
    </section>
  );
}
