"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { triggerSosAlert } from "@/app/actions/sos";
import { fetchProfile, type UserProfile } from "@/api/userApi";
import {
  createConsultationOrder,
  fetchMyPlan,
  PRICING,
  type MyPlan,
} from "@/api/paymentApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { SpecializationDialog } from "@/components/dialogs/SpecializationDialog";
import { btnPrimaryDark, btnSecondaryGlass, glassPanelNested } from "@/lib/vetoGlass";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  type SpecializationId,
  UI_TO_BACKEND_SPECIALIZATION,
} from "@/lib/specializations";
import { connectSocket, getSocket } from "@/lib/socketClient";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";

const DEFAULT_LOCATION = { lat: 32.0853, lng: 34.7818 };

function readSessionPayload(data: unknown): SessionReadyState | null {
  if (!data || typeof data !== "object") return null;
  const d = data as Record<string, unknown>;
  const roomId = typeof d.roomId === "string" ? d.roomId : null;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const agoraToken = typeof d.agoraToken === "string" ? d.agoraToken : "";
  const agoraUidRaw = d.agoraUid;
  const agoraUid =
    typeof agoraUidRaw === "number"
      ? agoraUidRaw
      : typeof agoraUidRaw === "string" && agoraUidRaw !== ""
        ? Number(agoraUidRaw)
        : NaN;
  const callTypeRaw = d.callType;
  const callType: SessionCallType =
    callTypeRaw === "audio" || callTypeRaw === "chat" || callTypeRaw === "video"
      ? callTypeRaw
      : "video";
  const tokenExpiresAt =
    typeof d.tokenExpiresAt === "number" ? d.tokenExpiresAt : undefined;

  if (!roomId || !eventId || !Number.isFinite(agoraUid)) {
    return null;
  }

  return {
    channelId: roomId,
    eventId,
    token: agoraToken,
    uid: agoraUid,
    callType,
    tokenExpiresAt,
  };
}

export default function CitizenHubPage() {
  const router = useRouter();
  const { t, locale } = useTranslation();
  const [sosDialogOpen, setSosDialogOpen] = useState(false);
  const [specializationDialogOpen, setSpecializationDialogOpen] = useState(false);
  const [callTypeDialogOpen, setCallTypeDialogOpen] = useState(false);
  const [chosenCallType, setChosenCallType] = useState<SessionCallType | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [myPlan, setMyPlan] = useState<MyPlan | null>(null);

  const isSearching = useEmergencyStore((s) => s.isSearching);
  const lawyerFound = useEmergencyStore((s) => s.lawyerFound);
  const lawyerName = useEmergencyStore((s) => s.lawyerName);
  const currentEventId = useEmergencyStore((s) => s.currentEventId);
  const statusMessage = useEmergencyStore((s) => s.statusMessage);

  const reset = useEmergencyStore((s) => s.reset);
  const startSearch = useEmergencyStore((s) => s.startSearch);
  const setLawyerFound = useEmergencyStore((s) => s.setLawyerFound);
  const setSessionReady = useEmergencyStore((s) => s.setSessionReady);
  const setErrorMessage = useEmergencyStore((s) => s.setErrorMessage);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
    }
  }, [router]);

  useEffect(() => {
    if (!getJwt()) return;
    let cancelled = false;
    void fetchProfile()
      .then((u) => {
        if (!cancelled) setProfile(u);
      })
      .catch(() => {
        if (!cancelled) setProfile(null);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!getJwt()) return;
    let cancelled = false;
    void fetchMyPlan()
      .then((p) => { if (!cancelled) setMyPlan(p); })
      .catch(() => { if (!cancelled) setMyPlan(null); });
    return () => { cancelled = true; };
  }, []);

  const startConsultationCheckout = useCallback(async () => {
    try {
      const r = await createConsultationOrder();
      window.location.assign(r.approveUrl);
    } catch (e) {
      setErrorMessage(e instanceof Error ? e.message : t("hub.errGeneric"));
    }
  }, [setErrorMessage, t]);

  useEffect(() => {
    if (!getJwt()) return;

    let cancelled = false;
    const sock = connectSocket();

    const onConnect = () => {
      if (cancelled) return;
      console.info("[hub] socket connected");
    };

    const onLawyerFound = (raw: unknown) => {
      if (cancelled) return;
      const payload =
        raw && typeof raw === "object" ? (raw as Record<string, unknown>) : null;
      const eventId = typeof payload?.eventId === "string" ? payload.eventId : null;
      const roomId = typeof payload?.roomId === "string" ? payload.roomId : null;
      const name =
        typeof payload?.lawyerName === "string" ? payload.lawyerName : undefined;
      if (!eventId || !roomId) {
        useEmergencyStore.getState().setErrorMessage(t("hub.errInvalidLawyerPayload"));
        return;
      }
      setLawyerFound({ eventId, roomId, lawyerName: name });
      setCallTypeDialogOpen(true);
    };

    const onSessionReady = (raw: unknown) => {
      if (cancelled) return;
      const parsed = readSessionPayload(raw);
      if (!parsed) {
        setErrorMessage(t("hub.errSessionData"));
        return;
      }
      setSessionReady(parsed);
      router.push(`/call/${encodeURIComponent(parsed.channelId)}`);
    };

    const onNoLawyers = () => {
      if (cancelled) return;
      setErrorMessage(t("hub.errNoLawyers"));
    };

    const onVetoError = (raw: unknown) => {
      if (cancelled) return;
      const obj = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : null;
      const code = typeof obj?.code === "string" ? obj.code : null;
      const msg =
        typeof obj?.message === "string" ? (obj.message as string) : t("hub.errGeneric");

      if (code === "NO_PLAN" || code === "DEMO_BLOCKED") {
        setErrorMessage(
          code === "DEMO_BLOCKED" ? t("hub.errDemoBlocked") : t("hub.errNoPlan"),
        );
        router.push("/plans");
        return;
      }
      if (code === "PAYMENT_REQUIRED") {
        setErrorMessage(t("hub.errPaymentRequired"));
        void startConsultationCheckout();
        return;
      }
      setErrorMessage(msg);
    };

    const onCaseTaken = (raw: unknown) => {
      if (cancelled) return;
      const incomingEventId =
        raw &&
        typeof raw === "object" &&
        "eventId" in raw &&
        typeof (raw as { eventId?: unknown }).eventId === "string"
          ? (raw as { eventId: string }).eventId
          : null;
      const {
        isSearching: searching,
        lawyerFound: found,
        currentEventId,
      } = useEmergencyStore.getState();
      // If a lawyer already accepted OUR case, ignore the broadcast — it is
      // the backend telling other lawyers the case is gone, not an error
      // for us. Without this guard the citizen sees an English "case taken"
      // popup right after the lawyer accepts.
      if (found) return;
      // Not actively searching → nothing to surface.
      if (!searching) return;
      // Ignore broadcasts about other citizens' events.
      if (incomingEventId && currentEventId && incomingEventId !== currentEventId) {
        return;
      }
      setErrorMessage(t("hub.errCaseTaken"));
    };

    sock.on("connect", onConnect);
    sock.on("lawyer_found", onLawyerFound);
    sock.on("session_ready", onSessionReady);
    sock.on("no_lawyers_available", onNoLawyers);
    sock.on("veto_error", onVetoError);
    sock.on("case_taken", onCaseTaken);

    return () => {
      cancelled = true;
      sock.off("connect", onConnect);
      sock.off("lawyer_found", onLawyerFound);
      sock.off("session_ready", onSessionReady);
      sock.off("no_lawyers_available", onNoLawyers);
      sock.off("veto_error", onVetoError);
      sock.off("case_taken", onCaseTaken);
    };
  }, [router, setErrorMessage, setLawyerFound, setSessionReady, startConsultationCheckout, t]);

  const handleSos = useCallback((specializationId: SpecializationId) => {
    if (!getJwt()) {
      router.push("/login");
      return;
    }

    startSearch();
    setErrorMessage(null);

    const sock = (() => {
      try {
        return getSocket();
      } catch {
        return connectSocket();
      }
    })();

    if (!sock.connected) {
      sock.connect();
    }

    const emitStart = (lat: number, lng: number, accuracy?: number) => {
      const onCreated = (raw: unknown) => {
        sock.off("emergency_created", onCreated);
        const payload =
          raw && typeof raw === "object" ? (raw as Record<string, unknown>) : null;
        const eid =
          typeof payload?.eventId === "string" ? payload.eventId.trim() : "";
        const loc =
          typeof accuracy === "number" && Number.isFinite(accuracy)
            ? { lat, lng, accuracy }
            : { lat, lng };
        if (!eid) {
          console.warn("[hub] emergency_created without eventId");
          return;
        }
        void triggerSosAlert({
          eventId: eid,
          location: loc,
          stress_test: false,
          urgency: "SOS",
        }).then((r) => {
          if (!r.success) {
            console.warn("[hub] Ably SOS:", r.error);
          }
        });
      };

      sock.once("emergency_created", onCreated);
      sock.emit("start_veto", {
        location: { lat, lng },
        preferredLanguage: locale,
        specialization: UI_TO_BACKEND_SPECIALIZATION[specializationId],
      });
    };

    if (typeof navigator === "undefined" || !navigator.geolocation) {
      emitStart(DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        emitStart(
          pos.coords.latitude,
          pos.coords.longitude,
          pos.coords.accuracy,
        );
      },
      () => {
        emitStart(DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng);
      },
      { enableHighAccuracy: true, timeout: 12_000, maximumAge: 60_000 },
    );
  }, [locale, router, setErrorMessage, startSearch]);

  const planBlocksSos =
    myPlan !== null &&
    !myPlan.paymentExempt &&
    (myPlan.planId === null || myPlan.planId === "demo");

  const onSosPress = useCallback(() => {
    if (planBlocksSos) {
      router.push("/plans");
      return;
    }
    setSosDialogOpen(true);
  }, [planBlocksSos, router]);

  const confirmSos = useCallback(() => {
    setSosDialogOpen(false);
    setSpecializationDialogOpen(true);
  }, []);

  const selectSpecialization = useCallback(
    (specializationId: SpecializationId) => {
      setSpecializationDialogOpen(false);
      handleSos(specializationId);
    },
    [handleSos],
  );

  const chooseCallType = useCallback((callType: SessionCallType) => {
    const eventId = useEmergencyStore.getState().currentEventId;
    if (!eventId) return;
    const sock = (() => {
      try {
        return getSocket();
      } catch {
        return connectSocket();
      }
    })();
    if (!sock.connected) sock.connect();
    sock.emit("citizen_chose_session", { eventId, callType });
    setChosenCallType(callType);
    setCallTypeDialogOpen(false);
  }, []);

  // Derived: only meaningful while there's an active SOS session.
  const effectiveChosenCallType =
    isSearching || lawyerFound ? chosenCallType : null;

  useEffect(() => {
    if (!isSearching || lawyerFound) return;
    const id = window.setTimeout(() => {
      if (
        useEmergencyStore.getState().isSearching &&
        !useEmergencyStore.getState().lawyerFound
      ) {
        setErrorMessage(t("hub.errSearchTimeout"));
      }
    }, 90_000);
    return () => window.clearTimeout(id);
  }, [isSearching, lawyerFound, setErrorMessage, t]);

  useEffect(() => {
    if (!chosenCallType) return;
    const id = window.setTimeout(() => {
      if (!useEmergencyStore.getState().sessionReady) {
        setChosenCallType(null);
        setErrorMessage(t("hub.errConnectTimeout"));
      }
    }, 30_000);
    return () => window.clearTimeout(id);
  }, [chosenCallType, setErrorMessage, t]);

  return (
    <>
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col items-center justify-center gap-8 px-6 py-12 pb-28">
        <div className="w-full rounded-2xl border border-white/50 bg-white/55 px-5 py-6 text-center shadow-sm backdrop-blur-xl">
          <h1 className="font-frank text-2xl font-bold text-slate-900">
            {t("hub.title")}
          </h1>
          <p className="mt-2 text-sm text-slate-600">{t("hub.subtitle")}</p>
        </div>

        <Link
          href="/plans"
          className="block w-full rounded-2xl border border-[#C5A059]/35 bg-[#C5A059]/10 px-4 py-3 text-sm shadow-sm backdrop-blur-xl transition hover:border-[#C5A059]/60"
        >
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0 text-right">
              <p className="font-bold text-slate-100">
                {myPlan?.paymentExempt
                  ? "חשבון פטור"
                  : myPlan?.planId === "family"
                    ? "מנוי משפחתי"
                    : myPlan?.planId === "standard"
                      ? "מנוי רגיל"
                      : myPlan?.planId === "demo"
                        ? "מנוי דמו · 30 יום"
                        : "אין מנוי פעיל"}
              </p>
              <p className="mt-0.5 truncate text-xs text-slate-400">
                {profile?.full_name || profile?.phone || "משתמש VETO"}
                {myPlan && myPlan.consultationsIncluded > 0 && (
                  <span className="ms-2 text-amber-300">
                    · {myPlan.consultationsRemaining}/{myPlan.consultationsIncluded} שיחות
                  </span>
                )}
              </p>
            </div>
            <span
              className={`shrink-0 rounded-full px-3 py-1 text-xs font-black ${
                myPlan?.paymentExempt || (myPlan?.planId && myPlan.planId !== "demo")
                  ? "border border-emerald-500/30 bg-emerald-500/15 text-emerald-300"
                  : myPlan?.planId === "demo"
                    ? "border border-sky-500/30 bg-sky-500/15 text-sky-300"
                    : "border border-amber-500/30 bg-amber-500/15 text-amber-300"
              }`}
            >
              {myPlan?.paymentExempt
                ? "פטור"
                : myPlan?.planId === "demo"
                  ? "דמו"
                  : myPlan?.planId
                    ? "פעיל"
                    : "שדרוג"}
            </span>
          </div>
          {planBlocksSos && (
            <p className="mt-2 text-xs text-amber-200">
              לחיצה על SOS תוביל לדף הצטרפות. שדרגו למנוי כדי להפעיל שיחה עם עורך דין.
            </p>
          )}
          {myPlan?.planId === "standard" && (
            <p className="mt-2 text-xs text-slate-400">
              כל שיחה מחויבת ב-₪{PRICING.consultationIls.toFixed(2)}; {PRICING.freeCallMinutes} דקות ראשונות כלולות.
            </p>
          )}
        </Link>

        <button
          type="button"
          onClick={onSosPress}
          disabled={isSearching}
          className="sos-btn relative flex h-44 w-44 items-center justify-center rounded-full border-4 border-red-950 bg-red-700 text-lg font-bold text-white shadow-2xl shadow-red-900/50 transition enabled:cursor-pointer enabled:hover:bg-red-600 enabled:active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-70"
        >
          <span className="relative z-10">{t("hub.sos")}</span>
        </button>

        {isSearching && !lawyerFound && (
          <div
            role="status"
            aria-live="polite"
            className="w-full rounded-2xl border border-[#C5A059]/35 bg-[#C5A059]/10 p-5 text-right shadow-lg backdrop-blur-xl"
          >
            <div className="flex items-center gap-3">
              <span
                aria-hidden="true"
                className="inline-block h-5 w-5 animate-spin rounded-full border-2 border-[#C5A059] border-t-transparent"
              />
              <p className="font-frank text-base font-bold text-amber-200">
                {t("hub.searchingTitle")}
              </p>
            </div>
            <p className="mt-2 text-sm text-slate-200">
              {t("hub.searchingSubtitle")}
            </p>
            <ol className="mt-4 space-y-2 text-sm text-slate-300">
              <li className="flex items-start gap-2">
                <span aria-hidden="true" className="mt-1 inline-block h-2 w-2 shrink-0 rounded-full bg-emerald-400" />
                <span>{t("hub.searchingStep1")}</span>
              </li>
              <li className="flex items-start gap-2">
                <span aria-hidden="true" className="mt-1 inline-block h-2 w-2 shrink-0 animate-pulse rounded-full bg-amber-300" />
                <span className="text-amber-100">{t("hub.searchingStep2")}</span>
              </li>
              <li className="flex items-start gap-2 opacity-60">
                <span aria-hidden="true" className="mt-1 inline-block h-2 w-2 shrink-0 rounded-full bg-slate-500" />
                <span>{t("hub.searchingStep3")}</span>
              </li>
            </ol>
            <p className="mt-3 text-xs text-slate-400">{t("hub.searchingHint")}</p>
            <div className="mt-4 flex justify-start">
              <button
                type="button"
                onClick={() => reset()}
                className={`${btnSecondaryGlass} px-3 py-1.5 text-xs`}
              >
                {t("hub.cancelSearch")}
              </button>
            </div>
          </div>
        )}

        {lawyerFound && lawyerName && !effectiveChosenCallType && (
          <p className="text-center text-sm font-medium text-emerald-300">
            {t("hub.lawyerAccepted").replace("{name}", lawyerName)}
          </p>
        )}

        {lawyerFound && effectiveChosenCallType && (
          <div
            role="status"
            aria-live="polite"
            className="w-full rounded-2xl border border-emerald-500/30 bg-emerald-500/10 p-5 text-right shadow-lg backdrop-blur-xl"
          >
            <div className="flex items-center gap-3">
              <span
                aria-hidden="true"
                className="inline-block h-5 w-5 animate-spin rounded-full border-2 border-emerald-300 border-t-transparent"
              />
              <p className="font-frank text-base font-bold text-emerald-200">
                {t("hub.connectingTitle")}
              </p>
            </div>
            <p className="mt-2 text-sm text-slate-200">
              {t("hub.connectingSubtitle")}
            </p>
          </div>
        )}

        {statusMessage && (
          <div
            role="alert"
            className="w-full rounded-xl border border-red-300/80 bg-red-50/90 px-4 py-3 text-center text-sm text-red-900 backdrop-blur-md"
          >
            {statusMessage}
            <div className="mt-3">
              <button
                type="button"
                onClick={() => reset()}
                className={`${btnSecondaryGlass} px-3 py-1.5 text-xs`}
              >
                {t("hub.dismiss")}
              </button>
            </div>
          </div>
        )}

        <div className="grid w-full grid-cols-2 gap-3">
          <Link
            href="/vault/generator"
            className={`${btnSecondaryGlass} px-4 py-3 text-center text-sm font-semibold`}
          >
            מחולל מסמכים
          </Link>
          <Link
            href="/productivity"
            className={`${btnSecondaryGlass} px-4 py-3 text-center text-sm font-semibold`}
          >
            {t("hub.quickProductivity")}
          </Link>
        </div>
      </main>

      <CitizenBottomNav active="hub" />

      {sosDialogOpen && (
        <div
          className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm"
          role="presentation"
          onClick={() => setSosDialogOpen(false)}
        >
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="sos-dialog-title"
            className={`w-full max-w-md p-6 shadow-xl ${glassPanelNested}`}
            onClick={(e) => e.stopPropagation()}
          >
            <h2
              id="sos-dialog-title"
              className="font-frank text-lg font-bold text-slate-900"
            >
              {t("hub.dialogTitle")}
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-slate-700">
              {t("hub.dialogBody")}
            </p>
            <div className="mt-6 flex flex-wrap justify-end gap-2">
              <button
                type="button"
                onClick={() => setSosDialogOpen(false)}
                className={`px-4 py-2.5 text-sm font-semibold ${btnSecondaryGlass}`}
              >
                {t("hub.dialogCancel")}
              </button>
              <button
                type="button"
                onClick={() => void confirmSos()}
                className={`px-4 py-2.5 text-sm font-bold text-white ${btnPrimaryDark}`}
              >
                {t("hub.dialogConfirm")}
              </button>
            </div>
          </div>
        </div>
      )}

      <SpecializationDialog
        isOpen={specializationDialogOpen}
        onClose={() => setSpecializationDialogOpen(false)}
        onSelect={selectSpecialization}
      />

      {callTypeDialogOpen && lawyerFound && currentEventId && (
        <div
          className="fixed inset-0 z-[95] flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm"
          role="presentation"
        >
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="call-type-dialog-title"
            className={`w-full max-w-md p-6 shadow-xl ${glassPanelNested}`}
            onClick={(e) => e.stopPropagation()}
          >
            <h2
              id="call-type-dialog-title"
              className="font-frank text-lg font-bold text-slate-900"
            >
              {t("dialog.chooseCallType")}
            </h2>
            <p className="mt-2 text-sm text-slate-700">{t("hub.callTypeHint")}</p>

            <div className="mt-5 grid gap-2">
              <button
                type="button"
                onClick={() => chooseCallType("video")}
                className={`px-4 py-2.5 text-sm font-semibold ${btnSecondaryGlass}`}
              >
                {t("hub.callTypeVideo")}
              </button>
              <button
                type="button"
                onClick={() => chooseCallType("audio")}
                className={`px-4 py-2.5 text-sm font-semibold ${btnSecondaryGlass}`}
              >
                {t("hub.callTypeAudio")}
              </button>
              <button
                type="button"
                onClick={() => chooseCallType("chat")}
                className={`px-4 py-2.5 text-sm font-semibold ${btnSecondaryGlass}`}
              >
                {t("hub.callTypeChat")}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
