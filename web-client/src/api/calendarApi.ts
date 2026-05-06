import { apiUrl, authJsonHeaders } from "@/api/apiClient";

/**
 * Calendar endpoints map to Express:
 * - List/create: `/api/calendar/events` (not a bare `/api/calendar` collection route).
 * - Google connect: `POST /api/integrations/gcal/connect` → `{ authUrl }` (server.js).
 */
export type CalendarEventType = "hearing" | "meeting" | "other";

export type ApiCalendarEvent = {
  _id: string;
  title: string;
  type?: CalendarEventType;
  start: string;
  end: string;
  timezone?: string;
  notes?: string;
  locationAddress?: string;
};

export type CreateCalendarEventPayload = {
  title: string;
  start: string;
  end: string;
  timezone?: string;
  notes?: string;
  type?: CalendarEventType;
};

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as { error?: string; message?: string };
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

/** GET `/api/calendar/events?year=&month=` (month 1–12). */
export async function fetchEvents(
  year: number,
  month: number,
): Promise<ApiCalendarEvent[]> {
  const q = new URLSearchParams({
    year: String(year),
    month: String(month),
  });
  const res = await fetch(apiUrl(`/api/calendar/events?${q}`), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  const data = (await res.json()) as { events?: ApiCalendarEvent[] };
  return data.events ?? [];
}

/** Loads this month + next month, merges, keeps events that end on or after `from`. */
export async function fetchUpcomingEvents(from: Date = new Date()): Promise<
  ApiCalendarEvent[]
> {
  const y = from.getFullYear();
  const m = from.getMonth() + 1;
  const nextY = m === 12 ? y + 1 : y;
  const nextM = m === 12 ? 1 : m + 1;
  const [a, b] = await Promise.all([
    fetchEvents(y, m),
    fetchEvents(nextY, nextM),
  ]);
  const merged = [...a, ...b];
  const seen = new Set<string>();
  const unique: ApiCalendarEvent[] = [];
  for (const ev of merged) {
    const id = ev._id;
    if (seen.has(id)) continue;
    seen.add(id);
    unique.push(ev);
  }
  return unique
    .filter((ev) => new Date(ev.end).getTime() >= from.getTime() - 60_000)
    .sort((x, y) => new Date(x.start).getTime() - new Date(y.start).getTime());
}

/** POST `/api/calendar/events`. */
export async function createEvent(
  payload: CreateCalendarEventPayload,
): Promise<ApiCalendarEvent> {
  const res = await fetch(apiUrl("/api/calendar/events"), {
    method: "POST",
    headers: authJsonHeaders(),
    body: JSON.stringify({
      ...payload,
      timezone: payload.timezone ?? "Asia/Jerusalem",
    }),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  return (await res.json()) as ApiCalendarEvent;
}

/**
 * Returns Google OAuth URL for Calendar sync.
 * Backend: POST `/api/integrations/gcal/connect` → `{ authUrl }`.
 */
export async function getGoogleAuthUrl(): Promise<{ url: string }> {
  const res = await fetch(apiUrl("/api/integrations/gcal/connect"), {
    method: "POST",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  const data = (await res.json()) as { authUrl?: string; url?: string };
  const url = data.authUrl || data.url;
  if (!url || typeof url !== "string") {
    throw new Error("No OAuth URL in response");
  }
  return { url };
}
