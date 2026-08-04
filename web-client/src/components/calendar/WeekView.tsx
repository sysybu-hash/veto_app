"use client";

import type { ApiCalendarEvent } from "@/api/calendarApi";
import { IconButton } from "@/components/ui/primitives/IconButton";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";
import {
  addDays,
  eventTypeClass,
  eventsOnDay,
  formatTimeRange,
  localeBcp47,
  sameDay,
  startOfWeekSunday,
} from "./calendarUtils";

type Props = {
  cursor: Date;
  selectedDay: Date;
  events: ApiCalendarEvent[];
  onCursorChange: (d: Date) => void;
  onSelectDay: (d: Date) => void;
  onOpenEvent: (ev: ApiCalendarEvent) => void;
};

export function WeekView({
  cursor,
  selectedDay,
  events,
  onCursorChange,
  onSelectDay,
  onOpenEvent,
}: Props) {
  const { t, locale } = useTranslation();
  const tag = localeBcp47(locale);
  const weekStart = startOfWeekSunday(cursor);
  const days = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));

  return (
    <section className={`${glassPanelNested} p-3 sm:p-4`}>
      <div className="mb-3 flex items-center justify-between">
        <IconButton
          variant="ghost"
          size="sm"
          label={t("calendar.prevWeekAria")}
          onClick={() => onCursorChange(addDays(cursor, -7))}
          icon={<span aria-hidden>‹</span>}
        />
        <h3 className="font-frank text-sm font-bold text-primary sm:text-base">
          {weekStart.toLocaleDateString(tag, { day: "numeric", month: "short" })}
          {" – "}
          {addDays(weekStart, 6).toLocaleDateString(tag, {
            day: "numeric",
            month: "short",
            year: "numeric",
          })}
        </h3>
        <IconButton
          variant="ghost"
          size="sm"
          label={t("calendar.nextWeekAria")}
          onClick={() => onCursorChange(addDays(cursor, 7))}
          icon={<span aria-hidden>›</span>}
        />
      </div>

      <div className="grid grid-cols-1 gap-2 sm:grid-cols-7">
        {days.map((day) => {
          const dayEvents = eventsOnDay(events, day);
          const selected = sameDay(day, selectedDay);
          return (
            <div
              key={day.toISOString()}
              className={`min-h-[7rem] rounded-xl border p-2 transition ${
                selected
                  ? "border-veto-gold/50 bg-veto-gold/10"
                  : "border-white/[0.06] bg-black/20"
              }`}
            >
              <button
                type="button"
                className="mb-2 w-full text-start text-xs font-bold text-secondary"
                onClick={() => onSelectDay(day)}
              >
                {day.toLocaleDateString(tag, { weekday: "short", day: "numeric" })}
              </button>
              <ul className="space-y-1">
                {dayEvents.map((ev) => (
                  <li key={ev._id}>
                    <button
                      type="button"
                      onClick={() => onOpenEvent(ev)}
                      className={`w-full truncate rounded-lg px-1.5 py-1 text-start text-[10px] font-semibold ${eventTypeClass(ev.type)}`}
                    >
                      <span className="block opacity-80">{formatTimeRange(ev, locale)}</span>
                      {ev.title}
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </div>
    </section>
  );
}
