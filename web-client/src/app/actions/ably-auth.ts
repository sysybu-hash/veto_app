"use server";

import type { TokenRequest } from "ably";
import {
  SOS_ALERTS_CHANNEL,
  getAblyRest,
  isAblyConfigured,
} from "@/lib/ably";
import { getVetoRoleFromCookies, getVetoUserIdFromCookies } from "@/lib/jwtCookie";

export type AblyTokenResult =
  | { success: true; tokenRequest: TokenRequest }
  | { success: false; error: string };

/**
 * Short-lived token so the lawyer SPA can subscribe to `sos-alerts` without exposing the API key.
 */
export async function fetchAblyLawyerToken(): Promise<AblyTokenResult> {
  if (!isAblyConfigured()) {
    return { success: false, error: "Ably אינו מוגדר" };
  }

  const userId = await getVetoUserIdFromCookies();
  if (!userId) {
    return { success: false, error: "נדרשת התחברות" };
  }

  const role = await getVetoRoleFromCookies();
  if (role !== "lawyer") {
    return { success: false, error: "הרשאה: עו״ד בלבד" };
  }

  try {
    const rest = getAblyRest();
    const tokenRequest = await rest.auth.createTokenRequest({
      clientId: `lawyer:${userId}`,
      capability: { [SOS_ALERTS_CHANNEL]: ["subscribe"] },
    });
    return { success: true, tokenRequest };
  } catch (e) {
    console.error("[Ably] token request failed:", e);
    return { success: false, error: "נכשל אימות Ably" };
  }
}
