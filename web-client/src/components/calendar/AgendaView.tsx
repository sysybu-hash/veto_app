"use client";

import type { ApiCalendarEvent } from "@/api/calendarApi";
import { EmptyState } from "@/components/ui/EmptyState";
import { Button } from "@/components/ui/primitives/Button";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";
import {
  eventTypeClass,
  formatTimeRange,
  localeBcp47,
  sameDay,
} from "./calendarUtils";

type Props = {
  events: ApiCalendarEvent[];
  selectedDay: Date | null;
  filterSelectedDay: boolean;
  onOpenEvent: (ev: ApiCalendarEvent) => void;
  onCreate: () => void;
};

export function AgendaView({
  events,
  selectedDay,
  filterSelectedDay,
  onOpenEvent,
  onCreate,
}: Props) {
  const { t, locale } = useTranslation();
  const tag = localeBcp47(locale);
  const list =
    filterSelectedDay && selectedDay
      ? events.filter((ev) => sameDay(new Date(ev.start), selectedDay))
      : events;

  if (!list.length) {
    return (
      <div className="p-2">
        <EmptyState
          title={t("calendar.noUpcoming")}
          description={t("calendar.emptyHint")}
          action={
            <Button variant="primary" onClick={onCreate}>
              {t("calendar.newEvent")}
            </Button>
          }
        />
      </div>
    );
  }

  return (
    <section className={`${glassPanelNested} p-3 sm:p-4`}>
      <h2 className="mb-3 font-frank text-base font-bold text-primary">
        {filterSelectedDay ? t("calendar.dayAgenda") : t("calendar.upcoming")}
      </h2>
      <ul className="space-y-2">
        {list.map((ev) => {
          const start = new Date(ev.start);
          return (
            <li key={ev._id}>
              <button
                type="button"
                onClick={() => onOpenEvent(ev)}
                className="flex w-full items-start gap-3 rounded-2xl border border-white/[0.06] bg-black/25 px-3 py-3 text-start transition hover:border-veto-gold/30 hover:bg-black/40"
              >
                <span
                  className={`mt-0.5 shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${eventTypeClass(ev.type)}`}
                >
                  {ev.type === "hearing"
                    ? t("calendar.typeHearing")
                    : ev.type === "meeting"
                      ? t("calendar.typeMeeting")
                      : t("calendar.typeOther")}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block font-bold text-primary">{ev.title}</span>
                  <span className="mt-0.5 block text-xs text-muted">
                    {start.toLocaleDateString(tag, {
                      weekday: "short",
                      day: "numeric",
                      month: "short",
                    })}{" "}
                    · {formatTimeRange(ev, locale)}
                  </span>
                  {ev.locationAddress ? (
                    <span className="mt-0.5 block truncate text-xs text-secondary">
                      {ev.locationAddress}
                    </span>
                  ) : null}
                </span>
              </button>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
