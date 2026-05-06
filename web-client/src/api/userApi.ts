import { apiUrl, authJsonHeaders } from "@/api/apiClient";

/**
 * Profile API: Express exposes `GET` / `PUT` `/api/users/me` (not `/profile`).
 */

export type UserSettings = {
  notifyEmergency?: boolean;
  notifyUpdates?: boolean;
  notifySms?: boolean;
};

export type UserProfile = {
  _id: string;
  full_name?: string;
  email?: string | null;
  phone?: string | null;
  preferred_language?: string;
  settings?: UserSettings;
  is_subscribed?: boolean;
  subscription_expiry?: string | null;
  role?: string;
};

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as { error?: string; message?: string };
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export type UpdateProfilePayload = {
  full_name?: string;
  email?: string;
  phone?: string;
  preferred_language?: string;
  settings?: UserSettings;
};

export async function fetchProfile(): Promise<UserProfile> {
  const res = await fetch(apiUrl("/api/users/me"), {
    method: "GET",
    headers: authJsonHeaders(),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  const data = (await res.json()) as { user?: UserProfile };
  if (!data.user) {
    throw new Error("Invalid profile response");
  }
  return data.user;
}

export async function updateProfile(
  payload: UpdateProfilePayload,
): Promise<UserProfile> {
  const res = await fetch(apiUrl("/api/users/me"), {
    method: "PUT",
    headers: authJsonHeaders(),
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
  const data = (await res.json()) as { user?: UserProfile };
  if (!data.user) {
    throw new Error("Invalid profile response");
  }
  return data.user;
}
