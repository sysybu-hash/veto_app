import { apiUrl, authFetch } from "@/api/apiClient";

/**
 * Calendar endpoints map to Express:
 * - CRUD: `/api/calendar/events`
 * - Feed: `/api/calendar/feed`
 * - Google: `/api/integrations/gcal/*`
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
  reminderBeforeMinutes?: number[];
  sourceCaseId?: string | null;
};

export type CalendarEventPayload = {
  title: string;
  start: string;
  end: string;
  timezone?: string;
  notes?: string;
  type?: CalendarEventType;
  locationAddress?: string;
  reminderBeforeMinutes?: number[];
  sourceCaseId?: string | null;
};

export type GoogleCalendarStatus = {
  enabled: boolean;
  connected: boolean;
  calendarId?: string | null;
  lastSyncAt?: string | null;
};

export type CalendarFeedInfo = {
  token: string;
  webcalUrl: string;
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
  const res = await authFetch(apiUrl(`/api/calendar/events?${q}`), {
    method: "GET",
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

export async function getEvent(id: string): Promise<ApiCalendarEvent> {
  const res = await authFetch(apiUrl(`/api/calendar/events/${id}`), {
    method: "GET",
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as ApiCalendarEvent;
}

/** POST `/api/calendar/events`. */
export async function createEvent(
  payload: CalendarEventPayload,
): Promise<ApiCalendarEvent> {
  const res = await authFetch(apiUrl("/api/calendar/events"), {
    method: "POST",
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

export async function updateEvent(
  id: string,
  payload: Partial<CalendarEventPayload>,
): Promise<ApiCalendarEvent> {
  const res = await authFetch(apiUrl(`/api/calendar/events/${id}`), {
    method: "PUT",
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as ApiCalendarEvent;
}

export async function deleteEvent(id: string): Promise<void> {
  const res = await authFetch(apiUrl(`/api/calendar/events/${id}`), {
    method: "DELETE",
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
}

export async function getFeedInfo(): Promise<CalendarFeedInfo> {
  const res = await authFetch(apiUrl("/api/calendar/feed"), { method: "GET" });
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = (await res.json()) as Partial<CalendarFeedInfo>;
  if (!data.token || !data.webcalUrl) {
    throw new Error("Invalid feed response");
  }
  return { token: data.token, webcalUrl: data.webcalUrl };
}

export async function getGoogleStatus(): Promise<GoogleCalendarStatus> {
  const res = await authFetch(apiUrl("/api/integrations/gcal/status"), {
    method: "GET",
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as GoogleCalendarStatus;
}

/**
 * Returns Google OAuth URL for Calendar sync.
 * Backend: POST `/api/integrations/gcal/connect` → `{ authUrl }`.
 */
export async function getGoogleAuthUrl(): Promise<{ url: string }> {
  const res = await authFetch(apiUrl("/api/integrations/gcal/connect"), {
    method: "POST",
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

export async function disconnectGoogle(): Promise<void> {
  const res = await authFetch(apiUrl("/api/integrations/gcal/disconnect"), {
    method: "POST",
  });
  if (!res.ok) throw new Error(await parseJsonError(res));
}

/** @deprecated Use CalendarEventPayload */
export type CreateCalendarEventPayload = CalendarEventPayload;
