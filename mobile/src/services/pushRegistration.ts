import { Platform } from "react-native";
import * as Notifications from "expo-notifications";
import Constants from "expo-constants";
import type { Router } from "expo-router";

import { apiClient } from "@/api/apiClient";
import { useEmergencyFeedStore } from "@/store/emergencyFeedStore";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

function ingestSosPayload(data: Record<string, unknown> | undefined | null) {
  if (!data) return null;
  const eventId = typeof data.eventId === "string" ? data.eventId : null;
  if (!eventId) return null;
  const loc = data.location;
  const lat =
    loc && typeof loc === "object"
      ? Number((loc as { lat?: unknown }).lat)
      : Number(data.lat);
  const lng =
    loc && typeof loc === "object"
      ? Number((loc as { lng?: unknown }).lng)
      : Number(data.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return eventId;

  useEmergencyFeedStore.getState().push({
    eventId,
    userId: data.userId != null ? String(data.userId) : "",
    userName: typeof data.userName === "string" ? data.userName : "",
    location: { lat, lng },
    language: typeof data.language === "string" ? data.language : "he",
    timestamp:
      typeof data.timestamp === "string" ? data.timestamp : new Date().toISOString(),
  });
  return eventId;
}

/**
 * When the lawyer taps a SOS push, open the lawyer dashboard with that event
 * already in the feed (not a blank home screen).
 */
export function attachPushResponseHandler(router: Router): () => void {
  if (Platform.OS === "web") return () => undefined;

  const sub = Notifications.addNotificationResponseReceivedListener((response) => {
    const data = response.notification.request.content.data as Record<string, unknown>;
    const eventId = ingestSosPayload(data);
    if (eventId) {
      router.push(`/(lawyer)/dashboard?eventId=${encodeURIComponent(eventId)}`);
    } else {
      router.push("/(lawyer)/dashboard");
    }
  });

  void Notifications.getLastNotificationResponseAsync().then((last) => {
    if (!last) return;
    const data = last.notification.request.content.data as Record<string, unknown>;
    const eventId = ingestSosPayload(data);
    if (eventId) {
      router.push(`/(lawyer)/dashboard?eventId=${encodeURIComponent(eventId)}`);
    }
  });

  return () => sub.remove();
}

/**
 * Request permission, obtain Expo push token, register with backend FCM/Expo path.
 * Backend stores token on Lawyer/User.fcm_token and uses it during SOS dispatch when FCM is configured.
 */
export async function registerForPushNotifications(): Promise<string | null> {
  if (Platform.OS === "web") return null;

  const { status: existing } = await Notifications.getPermissionsAsync();
  let finalStatus = existing;
  if (existing !== "granted") {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  if (finalStatus !== "granted") return null;

  const projectId =
    Constants.expoConfig?.extra?.eas?.projectId ??
    Constants.easConfig?.projectId;

  const tokenResponse = await Notifications.getExpoPushTokenAsync(
    projectId ? { projectId } : undefined,
  );
  const token = tokenResponse.data;
  if (!token) return null;

  try {
    await apiClient.post("/users/fcm-token", { token });
  } catch {
    // Non-fatal — SOS still works via socket while app is foregrounded.
  }
  return token;
}
