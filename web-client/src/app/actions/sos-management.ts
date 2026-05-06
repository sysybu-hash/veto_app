"use server";

import {
  SOS_ALERTS_CHANNEL,
  SOS_CLAIMED_EVENT_NAME,
  getAblyRest,
  isAblyConfigured,
} from "@/lib/ably";
import { prisma } from "@/lib/prisma";
import {
  getVetoRoleFromCookies,
  getVetoUserIdFromCookies,
} from "@/lib/jwtCookie";

export type SosQueueItemDTO = {
  eventId: string;
  citizenId: string;
  lat: number | null;
  lng: number | null;
  accuracy: number | null;
  urgency: string;
  stressTest: boolean;
  status: string;
  createdAt: string;
};

export type ListSosQueueResult =
  | { success: true; items: SosQueueItemDTO[] }
  | { success: false; error: string };

export async function listOpenSosEvents(): Promise<ListSosQueueResult> {
  const role = await getVetoRoleFromCookies();
  if (role !== "lawyer" && role !== "admin") {
    return { success: false, error: "הרשאה: עו״ד או מנהל בלבד" };
  }

  try {
    const rows = await prisma.sosEvent.findMany({
      where: { status: "OPEN" },
      orderBy: { createdAt: "desc" },
      take: 100,
    });
    return {
      success: true,
      items: rows.map((r) => ({
        eventId: r.eventId,
        citizenId: r.citizenId,
        lat: r.lat,
        lng: r.lng,
        accuracy: r.accuracy,
        urgency: r.urgency,
        stressTest: r.stressTest,
        status: r.status,
        createdAt: r.createdAt.toISOString(),
      })),
    };
  } catch (e) {
    console.error("[sos-management] list:", e);
    return { success: false, error: "טעינת תור נכשלה" };
  }
}

export type ClaimSosResult =
  | { success: true }
  | { success: false; error: string };

/**
 * Mark SOS as claimed in Neon and broadcast on Ably so other lawyers drop it from the live queue.
 */
export async function claimSosEvent(eventId: string): Promise<ClaimSosResult> {
  const trimmed = eventId.trim();
  if (!trimmed) {
    return { success: false, error: "חסר מזהה אירוע" };
  }

  const lawyerId = await getVetoUserIdFromCookies();
  if (!lawyerId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const role = await getVetoRoleFromCookies();
  if (role !== "lawyer" && role !== "admin") {
    return { success: false, error: "הרשאה: עו״ד בלבד" };
  }

  if (!isAblyConfigured()) {
    return { success: false, error: "Ably אינו מוגדר" };
  }

  try {
    const updated = await prisma.sosEvent.updateMany({
      where: { eventId: trimmed, status: "OPEN" },
      data: {
        status: "CLAIMED",
        claimedById: lawyerId,
        claimedAt: new Date(),
      },
    });

    if (updated.count === 0) {
      return {
        success: false,
        error: "האירוע כבר לא זמין או נתפס על ידי עו״ד אחר",
      };
    }

    const rest = getAblyRest();
    const channel = rest.channels.get(SOS_ALERTS_CHANNEL);
    await channel.publish(SOS_CLAIMED_EVENT_NAME, {
      eventId: trimmed,
      lawyerId,
      timestamp: new Date().toISOString(),
    });

    return { success: true };
  } catch (e) {
    console.error("[sos-management] claim:", e);
    return { success: false, error: "תפיסת אירוע נכשלה" };
  }
}
