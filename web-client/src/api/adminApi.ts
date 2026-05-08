import { apiUrl, authFetch } from "@/api/apiClient";

const BASE = "/api/admin";

/** Pending lawyer row from GET /api/admin/lawyers/pending */
export type ApiPendingLawyer = {
  _id: string;
  full_name?: string;
  phone?: string;
  email?: string;
  license_number?: string | null;
  specializations?: string[];
  years_of_experience?: number;
  createdAt?: string;
};

/** GET /api/admin/stats */
export type AdminStats = {
  totalUsers: number;
  activeLawyers: number;
  pendingLawyers: number;
  eventsToday: number;
  eventsWeek: number;
  eventsMonth: number;
};

export type ApiEmergencyEventUser = {
  _id?: string;
  full_name?: string;
  phone?: string;
};

/** Emergency event from GET /api/admin/emergency-logs */
export type ApiEmergencyEvent = {
  _id: string;
  status?: string;
  triggered_at?: string;
  createdAt?: string;
  user_id?: string | ApiEmergencyEventUser | null;
  assigned_lawyer_id?: string | ApiEmergencyEventUser | null;
};

async function readErrorMessage(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: unknown; message?: unknown };
    if (typeof data.error === "string") return data.error;
    if (typeof data.message === "string") return data.message;
  } catch {
    /* ignore */
  }
  return `Request failed (${res.status})`;
}

/**
 * GET /api/admin/lawyers/pending — `{ lawyers: [...] }`
 */
export async function fetchPendingLawyers(): Promise<ApiPendingLawyer[]> {
  const res = await authFetch(apiUrl(`${BASE}/lawyers/pending`), {
    method: "GET",
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data: unknown = await res.json();
  if (Array.isArray(data)) {
    return data as ApiPendingLawyer[];
  }
  const rec = data as { lawyers?: unknown };
  if (!Array.isArray(rec.lawyers)) {
    throw new Error("Invalid response: missing lawyers array");
  }
  return rec.lawyers as ApiPendingLawyer[];
}

/**
 * PUT /api/admin/lawyers/:id/approve — backend sets `is_approved: true`
 */
export async function approveLawyer(lawyerId: string): Promise<void> {
  const res = await authFetch(
    apiUrl(`${BASE}/lawyers/${encodeURIComponent(lawyerId)}/approve`),
    {
      method: "PUT",
      body: JSON.stringify({}),
    },
  );
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
}

/**
 * DELETE /api/admin/lawyers/:id/reject — removes pending lawyer record
 */
export async function rejectLawyer(lawyerId: string): Promise<void> {
  const res = await authFetch(
    apiUrl(`${BASE}/lawyers/${encodeURIComponent(lawyerId)}/reject`),
    {
      method: "DELETE",
    },
  );
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
}

/**
 * GET /api/admin/stats
 */
export async function fetchSystemStats(): Promise<AdminStats> {
  const res = await authFetch(apiUrl(`${BASE}/stats`), {
    method: "GET",
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data = (await res.json()) as Partial<AdminStats>;
  const required: (keyof AdminStats)[] = [
    "totalUsers",
    "activeLawyers",
    "pendingLawyers",
    "eventsToday",
    "eventsWeek",
    "eventsMonth",
  ];
  for (const k of required) {
    if (typeof data[k] !== "number" || !Number.isFinite(data[k] as number)) {
      throw new Error(`Invalid stats response: missing ${k}`);
    }
  }
  return data as AdminStats;
}

/**
 * GET /api/admin/emergency-logs — `{ events: [...] }` (SOS / emergency activity)
 */
export async function fetchEmergencyEvents(): Promise<ApiEmergencyEvent[]> {
  const res = await authFetch(apiUrl(`${BASE}/emergency-logs`), {
    method: "GET",
  });
  if (!res.ok) {
    throw new Error(await readErrorMessage(res));
  }
  const data: unknown = await res.json();
  if (Array.isArray(data)) {
    return data as ApiEmergencyEvent[];
  }
  const rec = data as { events?: unknown };
  if (!Array.isArray(rec.events)) {
    throw new Error("Invalid response: missing events array");
  }
  return rec.events as ApiEmergencyEvent[];
}

/** Alias for dashboards that label this feed “system logs”. */
export const fetchSystemLogs = fetchEmergencyEvents;
