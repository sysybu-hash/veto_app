"use client";

import type {
  ErrorInfo,
  TokenDetails,
  TokenParams,
  TokenRequest,
} from "ably";
import { useEffect } from "react";
import { fetchAblyLawyerToken } from "@/app/actions/ably-auth";
import {
  SOS_ALERTS_CHANNEL,
  SOS_EVENT_NAME,
  createAblyRealtimeWithAuth,
} from "@/lib/ably";
import { getJwt, getRoleFromJwt } from "@/lib/authToken";
import { useToastStore } from "@/store/useToastStore";

type AblyAuthProceed = (
  error: ErrorInfo | string | null,
  tokenRequestOrDetails: TokenDetails | TokenRequest | string | null,
) => void;

function formatSosToast(data: unknown): string {
  if (!data || typeof data !== "object") {
    return "התראת SOS חדשה (ללא פרטים)";
  }
  const d = data as Record<string, unknown>;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const stress = d.stress_test === true ? " · QA" : "";
  const userId = d.userId != null ? String(d.userId) : "?";
  const loc = d.location;
  let locPart = "";
  if (loc && typeof loc === "object") {
    const lat = (loc as Record<string, unknown>).lat;
    const lng = (loc as Record<string, unknown>).lng;
    if (typeof lat === "number" && typeof lng === "number") {
      locPart = ` · מיקום ${lat.toFixed(4)}, ${lng.toFixed(4)}`;
    }
  }
  const ts = typeof d.timestamp === "string" ? d.timestamp : "";
  const idPart = eventId ? ` · ${eventId.slice(0, 8)}…` : "";
  return `SOS — משתמש ${userId.slice(0, 8)}…${locPart}${stress}${idPart}${ts ? ` · ${ts}` : ""}`;
}

/**
 * Lawyer dashboard: subscribe to Ably `sos-alerts` and surface red/gold pulse toasts.
 */
export function useSosListener() {
  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") {
      return;
    }

    const push = useToastStore.getState().push;

    const realtime = createAblyRealtimeWithAuth(
      (_tokenParams: TokenParams, callback: AblyAuthProceed) => {
        void fetchAblyLawyerToken().then((res) => {
          if (!res.success) {
            callback(res.error, null);
            return;
          }
          callback(null, res.tokenRequest);
        });
      },
    );

    const channel = realtime.channels.get(SOS_ALERTS_CHANNEL);

    const handler = (message: { name?: string; data?: unknown }) => {
      if (message.name !== SOS_EVENT_NAME) return;
      push(formatSosToast(message.data), "alert");
    };

    channel.subscribe(SOS_EVENT_NAME, handler);

    return () => {
      try {
        channel.unsubscribe(SOS_EVENT_NAME, handler);
        realtime.close();
      } catch {
        /* ignore */
      }
    };
  }, []);
}
