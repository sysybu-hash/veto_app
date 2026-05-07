"use client";

import type {
  ErrorInfo,
  TokenDetails,
  TokenParams,
  TokenRequest,
} from "ably";
import { useCallback, useEffect, useMemo, useState } from "react";
import { fetchAblyLawyerToken } from "@/app/actions/ably-auth";
import { claimSosEvent, listOpenSosEvents } from "@/app/actions/sos-management";
import {
  SOS_ALERTS_CHANNEL,
  SOS_CLAIMED_EVENT_NAME,
  SOS_EVENT_NAME,
  createAblyRealtimeWithAuth,
} from "@/lib/ably";
import { getJwt, getRoleFromJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { btnPrimaryGold, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";

type AblyAuthProceed = (
  error: ErrorInfo | string | null,
  tokenRequestOrDetails: TokenDetails | TokenRequest | string | null,
) => void;

export type QueueItem = {
  eventId: string;
  citizenId: string;
  lat: number | null;
  lng: number | null;
  urgency: "SOS" | "INQUIRY";
  stressTest: boolean;
  timestamp: string;
};

function haversineKm(
  aLat: number,
  aLng: number,
  bLat: number,
  bLng: number,
): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(x)));
}

function parseSosAlertMessage(data: unknown): QueueItem | null {
  if (!data || typeof data !== "object") return null;
  const d = data as Record<string, unknown>;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const userId =
    typeof d.userId === "string"
      ? d.userId
      : d.userId != null
        ? String(d.userId)
        : null;
  if (!eventId || !userId) return null;
  const urgency: QueueItem["urgency"] =
    d.urgency === "INQUIRY" ? "INQUIRY" : "SOS";
  const stressTest = d.stress_test === true;
  const ts =
    typeof d.timestamp === "string" ? d.timestamp : new Date().toISOString();
  let lat: number | null = null;
  let lng: number | null = null;
  const loc = d.location;
  if (loc && typeof loc === "object") {
    const la = (loc as Record<string, unknown>).lat;
    const ln = (loc as Record<string, unknown>).lng;
    const laN = typeof la === "number" ? la : Number(la);
    const lnN = typeof ln === "number" ? ln : Number(ln);
    if (Number.isFinite(laN) && Number.isFinite(lnN)) {
      lat = laN;
      lng = lnN;
    }
  }
  return {
    eventId,
    citizenId: userId,
    lat,
    lng,
    urgency,
    stressTest,
    timestamp: ts,
  };
}

function parseClaimedMessage(data: unknown): string | null {
  if (!data || typeof data !== "object") return null;
  const id = (data as Record<string, unknown>).eventId;
  return typeof id === "string" ? id : null;
}

/**
 * Ably-driven glass queue: urgency + proximity sort, claim via server action.
 */
export function SosQueue() {
  const { t, locale } = useTranslation();
  const pushToast = useToastStore((s) => s.push);
  const [items, setItems] = useState<Record<string, QueueItem>>({});
  const [lawyerLatLng, setLawyerLatLng] = useState<{
    lat: number;
    lng: number;
  } | null>(null);
  const [showStress, setShowStress] = useState(false);
  const [claimingId, setClaimingId] = useState<string | null>(null);

  const upsert = useCallback((item: QueueItem) => {
    setItems((prev) => ({ ...prev, [item.eventId]: item }));
  }, []);

  const remove = useCallback((eventId: string) => {
    setItems((prev) => {
      const next = { ...prev };
      delete next[eventId];
      return next;
    });
  }, []);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    if (typeof navigator === "undefined" || !navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLawyerLatLng({
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        });
      },
      () => {},
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300_000 },
    );
  }, []);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;

    let cancelled = false;
    void listOpenSosEvents().then((res) => {
      if (cancelled || !res.success) {
        if (!cancelled && !res.success) {
          pushToast(res.error, "error");
        }
        return;
      }
      const next: Record<string, QueueItem> = {};
      for (const row of res.items) {
        next[row.eventId] = {
          eventId: row.eventId,
          citizenId: row.citizenId,
          lat: row.lat,
          lng: row.lng,
          urgency: row.urgency === "INQUIRY" ? "INQUIRY" : "SOS",
          stressTest: row.stressTest,
          timestamp: row.createdAt,
        };
      }
      setItems((prev) => ({ ...prev, ...next }));
    });

    return () => {
      cancelled = true;
    };
  }, [pushToast]);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;

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

    const onAlert = (message: { name?: string; data?: unknown }) => {
      if (message.name !== SOS_EVENT_NAME) return;
      const item = parseSosAlertMessage(message.data);
      if (item) upsert(item);
    };

    const onClaimed = (message: { name?: string; data?: unknown }) => {
      if (message.name !== SOS_CLAIMED_EVENT_NAME) return;
      const id = parseClaimedMessage(message.data);
      if (id) remove(id);
    };

    channel.subscribe(SOS_EVENT_NAME, onAlert);
    channel.subscribe(SOS_CLAIMED_EVENT_NAME, onClaimed);

    return () => {
      try {
        channel.unsubscribe(SOS_EVENT_NAME, onAlert);
        channel.unsubscribe(SOS_CLAIMED_EVENT_NAME, onClaimed);
        realtime.close();
      } catch {
        /* ignore */
      }
    };
  }, [remove, upsert]);

  const sorted = useMemo(() => {
    const list = Object.values(items).filter(
      (it) => showStress || !it.stressTest,
    );
    return list.sort((a, b) => {
      const urg = (u: QueueItem["urgency"]) => (u === "SOS" ? 0 : 1);
      const u = urg(a.urgency) - urg(b.urgency);
      if (u !== 0) return u;
      if (
        lawyerLatLng &&
        a.lat != null &&
        a.lng != null &&
        b.lat != null &&
        b.lng != null
      ) {
        const da = haversineKm(
          lawyerLatLng.lat,
          lawyerLatLng.lng,
          a.lat,
          a.lng,
        );
        const db = haversineKm(
          lawyerLatLng.lat,
          lawyerLatLng.lng,
          b.lat,
          b.lng,
        );
        if (da !== db) return da - db;
      }
      return (
        new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
      );
    });
  }, [items, lawyerLatLng, showStress]);

  const onClaim = async (eventId: string) => {
    if (claimingId) return;
    setClaimingId(eventId);
    try {
      const res = await claimSosEvent(eventId);
      if (res.success) {
        remove(eventId);
        pushToast(t("sosQueue.toastClaimOk"), "success");
      } else {
        pushToast(res.error, "error");
      }
    } finally {
      setClaimingId(null);
    }
  };

  return (
    <section
      className={`mt-8 p-6 md:p-8 ${glassPanel}`}
      dir={locale === "he" ? "rtl" : "ltr"}
    >
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="text-start">
          <h2 className="font-frank text-lg font-black text-slate-900 md:text-xl">
            {t("sosQueue.title")}
          </h2>
          <p className="mt-1 text-sm text-slate-600">{t("sosQueue.subtitle")}</p>
        </div>
        <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-700">
          <input
            type="checkbox"
            checked={showStress}
            onChange={(e) => setShowStress(e.target.checked)}
            className="rounded border-white/50"
          />
          {t("sosQueue.showStress")}
        </label>
      </div>

      {sorted.length === 0 ? (
        <div
          className={`rounded-2xl border border-dashed border-white/45 px-6 py-12 text-center text-slate-600 ${glassPanelNested}`}
        >
          {t("sosQueue.empty")}
        </div>
      ) : (
        <ul className="flex flex-col gap-3">
          {sorted.map((it) => (
            <li
              key={it.eventId}
              className={`flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between ${glassPanelNested} ${
                it.urgency === "SOS" ? "animate-pulse" : ""
              }`}
            >
              <div className="min-w-0 flex-1 text-start">
                <div className="flex flex-wrap items-center gap-2">
                  <span
                    className={`rounded-lg px-2 py-0.5 text-xs font-black ${
                      it.urgency === "SOS"
                        ? "bg-red-600/90 text-white"
                        : "bg-amber-200/90 text-slate-900"
                    }`}
                  >
                    {it.urgency}
                  </span>
                  {it.stressTest ? (
                    <span className="rounded-lg bg-slate-800/80 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-amber-200">
                      {t("sosQueue.stressQa")}
                    </span>
                  ) : null}
                </div>
                <p className="mt-2 font-mono text-xs text-slate-700">
                  {t("sosQueue.eventPrefix")} {it.eventId.slice(0, 13)}…
                </p>
                <p className="text-sm text-slate-800">
                  {t("sosQueue.callerLabel")} · {it.citizenId.slice(0, 12)}…
                </p>
                <p className="text-xs text-slate-600">
                  {it.lat != null && it.lng != null
                    ? `${t("sosQueue.locationPrefix")} ${it.lat.toFixed(4)}, ${it.lng.toFixed(4)}`
                    : t("sosQueue.noPreciseLocation")}
                  {" · "}
                  {new Date(it.timestamp).toLocaleString(
                    locale === "he" ? "he-IL" : locale === "ru" ? "ru-RU" : "en-US",
                    { hour12: false },
                  )}
                </p>
              </div>
              <button
                type="button"
                disabled={claimingId !== null}
                onClick={() => void onClaim(it.eventId)}
                className={`shrink-0 px-5 py-3 text-sm ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50`}
              >
                {claimingId === it.eventId ? t("sosQueue.claiming") : t("sosQueue.claim")}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
