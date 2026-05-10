/**
 * Client-side specialization metadata for the SOS picker.
 *
 * The canonical list of legal areas + their match terms lives on the backend in
 * `backend/src/config/specializations.js` and is served from
 * `GET /api/config/specializations`. This file only defines the IDs that the
 * UI exposes in the picker (we intentionally don't show every backend area —
 * `realestate` is matchable by the AI controller but doesn't get a SOS card).
 *
 * The id sent to the backend (`emit('start_veto', { specialization })`) is the
 * canonical English id — the backend resolves Hebrew/English/aliases via
 * `findSpecialization()`. No Hebrew labels are sent over the wire from the
 * picker any more.
 */
export type SpecializationId =
  | "criminal"
  | "traffic"
  | "civil"
  | "family"
  | "labor"
  | "general";

export const SPECIALIZATION_IDS: readonly SpecializationId[] = [
  "criminal",
  "traffic",
  "civil",
  "family",
  "labor",
  "general",
] as const;

/** Optional fetcher for components that want fresh labels from the backend. */
export type ServerSpecialization = {
  id: string;
  label: { he: string; en: string; ru: string; ar: string };
};

export async function fetchSpecializationsFromServer(
  apiUrl: string,
  signal?: AbortSignal,
): Promise<ServerSpecialization[]> {
  try {
    const res = await fetch(`${apiUrl}/api/config/specializations`, {
      method: "GET",
      cache: "force-cache",
      signal,
    });
    if (!res.ok) return [];
    const data = (await res.json()) as { specializations?: ServerSpecialization[] };
    return Array.isArray(data.specializations) ? data.specializations : [];
  } catch {
    return [];
  }
}
