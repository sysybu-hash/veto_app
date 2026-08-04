import { apiUrl, authFetch } from "@/api/apiClient";

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
  is_available?: boolean;
  is_online?: boolean;
  preferred_language?: string;
  settings?: UserSettings;
  is_subscribed?: boolean;
  subscription_expiry?: string | null;
  role?: string;
  onboarding_completed?: boolean;
  manually_added?: boolean;
  is_payment_exempt?: boolean;
};

async function parseJsonError(res: Response): Promise<string> {
  try {
    const j = (await res.json()) as { error?: string; message?: string };
    return j.error || j.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export async function updateLawyerAvailability(
  isAvailable: boolean,
): Promise<void> {
  const res = await authFetch(apiUrl("/api/lawyers/availability"), {
    method: "PUT",
    body: JSON.stringify({ is_available: isAvailable }),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
}

/** Persist lawyer GPS for SOS proximity sorting. */
export async function updateLawyerLocation(
  lat: number,
  lng: number,
): Promise<void> {
  const res = await authFetch(apiUrl("/api/lawyers/location"), {
    method: "PUT",
    body: JSON.stringify({ lat, lng }),
  });
  if (!res.ok) {
    throw new Error(await parseJsonError(res));
  }
}

export type UpdateProfilePayload = {
  full_name?: string;
  email?: string;
  phone?: string;
  preferred_language?: string;
  settings?: UserSettings;
  onboarding_completed?: boolean;
};

export async function fetchProfile(): Promise<UserProfile> {
  const res = await authFetch(apiUrl("/api/users/me"), {
    method: "GET",
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
  const res = await authFetch(apiUrl("/api/users/me"), {
    method: "PUT",
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
