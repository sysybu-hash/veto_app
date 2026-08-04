import type { CalendarEventType, ApiCalendarEvent } from "@/api/calendarApi";
import type { Locale } from "@/lib/i18n/types";

export function localeBcp47(locale: Locale): string {
  switch (locale) {
    case "he":
      return "he-IL";
    case "ru":
      return "ru-RU";
    default:
      return "en-US";
  }
}

export function eventTypeClass(type?: CalendarEventType): string {
  switch (type) {
    case "hearing":
      return "bg-veto-gold text-zinc-950";
    case "meeting":
      return "bg-sky-700/90 text-sky-50";
    default:
      return "bg-zinc-600/90 text-zinc-100";
  }
}

export function eventTypeDot(type?: CalendarEventType): string {
  switch (type) {
    case "hearing":
      return "bg-veto-gold";
    case "meeting":
      return "bg-sky-500";
    default:
      return "bg-zinc-400";
  }
}

export function sameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function startOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

export function addDays(d: Date, n: number): Date {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

export function startOfWeekSunday(d: Date): Date {
  const x = startOfDay(d);
  x.setDate(x.getDate() - x.getDay());
  return x;
}

export function eventsOnDay(events: ApiCalendarEvent[], day: Date): ApiCalendarEvent[] {
  return events
    .filter((ev) => sameDay(new Date(ev.start), day))
    .sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());
}

export function formatTimeRange(
  ev: ApiCalendarEvent,
  locale: Locale,
): string {
  const tag = localeBcp47(locale);
  const start = new Date(ev.start);
  const end = new Date(ev.end);
  return `${start.toLocaleTimeString(tag, {
    hour: "numeric",
    minute: "2-digit",
  })} – ${end.toLocaleTimeString(tag, {
    hour: "numeric",
    minute: "2-digit",
  })}`;
}

export function toDateInputValue(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function toTimeInputValue(d: Date): string {
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

export function combineLocalRange(
  dateStr: string,
  startTime: string,
  endTime: string,
): { start: string; end: string } {
  const start = new Date(`${dateStr}T${startTime}:00`);
  let end = new Date(`${dateStr}T${endTime}:00`);
  if (!(end.getTime() > start.getTime())) {
    end = new Date(start.getTime() + 60 * 60 * 1000);
  }
  return { start: start.toISOString(), end: end.toISOString() };
}
