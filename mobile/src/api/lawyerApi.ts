import { apiClient } from "./apiClient";

export async function updateLawyerLocation(lat: number, lng: number) {
  await apiClient.put("/lawyers/location", { lat, lng });
}

export async function updateLawyerAvailability(is_available: boolean) {
  await apiClient.put("/lawyers/availability", { is_available });
}
