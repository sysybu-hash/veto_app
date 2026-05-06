"use server";

import { randomUUID } from "node:crypto";

import {
  SOS_ALERTS_CHANNEL,
  SOS_EVENT_NAME,
  getAblyRest,
  isAblyConfigured,
} from "@/lib/ably";
import { prisma } from "@/lib/prisma";
import {
  getVetoRoleFromCookies,
  getVetoUserIdFromCookies,
} from "@/lib/jwtCookie";

export type SosAlertLocation = {
  lat: number;
  lng: number;
  accuracy?: number;
};

export type SosUrgency = "SOS" | "INQUIRY";

export type TriggerSosOptions = {
  location?: SosAlertLocation;
  stress_test?: boolean;
  urgency?: SosUrgency;
};

export type TriggerSosResult =
  | { success: true; eventId: string }
  | { success: false; error: string };

/**
 * Create DB queue row + publish SOS metadata to Ably (lawyer dashboards).
 */
export async function triggerSosAlert(
  options?: TriggerSosOptions,
): Promise<TriggerSosResult> {
  if (!isAblyConfigured()) {
    return { success: false, error: "Ably אינו מוגדר (ABLY_API_KEY)" };
  }

  const userId = await getVetoUserIdFromCookies();
  if (!userId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const role = await getVetoRoleFromCookies();
  const stress_test = options?.stress_test === true;
  const urgency: SosUrgency =
    options?.urgency === "INQUIRY" ? "INQUIRY" : "SOS";

  const loc = options?.location;
  const lat =
    loc != null && Number.isFinite(loc.lat) ? loc.lat : null;
  const lng =
    loc != null && Number.isFinite(loc.lng) ? loc.lng : null;
  const accuracy =
    loc != null && typeof loc.accuracy === "number" && Number.isFinite(loc.accuracy)
      ? loc.accuracy
      : null;

  const eventId = randomUUID();

  try {
    await prisma.sosEvent.create({
      data: {
        eventId,
        citizenId: userId,
        lat,
        lng,
        accuracy,
        urgency,
        stressTest: stress_test,
        status: "OPEN",
      },
    });

    try {
      const rest = getAblyRest();
      const channel = rest.channels.get(SOS_ALERTS_CHANNEL);
      await channel.publish(SOS_EVENT_NAME, {
        eventId,
        userId,
        role: role ?? "user",
        timestamp: new Date().toISOString(),
        stress_test,
        urgency,
        location:
          lat != null && lng != null
            ? {
                lat,
                lng,
                ...(accuracy != null ? { accuracy } : {}),
              }
            : null,
      });
    } catch (pubErr) {
      await prisma.sosEvent.deleteMany({ where: { eventId } }).catch(() => {});
      throw pubErr;
    }
    return { success: true, eventId };
  } catch (e) {
    console.error("[SOS] create/publish failed:", e);
    return { success: false, error: "פרסום התראת SOS נכשל" };
  }
}
