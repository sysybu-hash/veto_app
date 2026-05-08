import { apiUrl, authFetch } from "@/api/apiClient";

export type CitizenDashboardSummary = {
  totals?: {
    contracts?: number;
    tasks?: number;
    contacts?: number;
  };
  metrics?: Record<string, unknown>;
  labels?: Record<string, string>;
};

export type CitizenNotification = {
  _id: string;
  title?: string;
  body?: string;
  read?: boolean;
  createdAt?: string;
};

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as { error?: string; message?: string };
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export async function fetchCitizenDashboardSummary(): Promise<CitizenDashboardSummary> {
  const res = await authFetch(apiUrl("/api/citizen-dashboard/summary"));
  if (!res.ok) throw new Error(await parseJsonError(res));
  return (await res.json()) as CitizenDashboardSummary;
}

export async function fetchCitizenNotifications(): Promise<CitizenNotification[]> {
  const res = await authFetch(apiUrl("/api/citizen-dashboard/notifications"));
  if (!res.ok) throw new Error(await parseJsonError(res));
  const data = await res.json();
  return Array.isArray(data) ? data : Array.isArray(data.notifications) ? data.notifications : [];
}

export async function markCitizenNotificationRead(id: string): Promise<void> {
  const res = await authFetch(
    apiUrl(`/api/citizen-dashboard/notifications/${encodeURIComponent(id)}/read`),
    { method: "PATCH", body: "{}" },
  );
  if (!res.ok) throw new Error(await parseJsonError(res));
}
