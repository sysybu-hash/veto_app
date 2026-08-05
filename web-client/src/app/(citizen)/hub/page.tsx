"use client";

import { useRouter } from "next/navigation";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { triggerSosAlert } from "@/app/actions/sos";
import { fetchProfile, type UserProfile } from "@/api/userApi";
import { fetchEntitlement, type Entitlement } from "@/api/advancedApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { SearchingLawyerOverlay } from "@/components/citizen/SearchingLawyerOverlay";
import { useCookieConsentPending } from "@/components/privacy/CookieConsent";
import { SpecializationDialog } from "@/components/dialogs/SpecializationDialog";
import { btnSecondaryGlass, citizenBottomSafe, glassPanelNested } from "@/lib/vetoGlass";
import { Button } from "@/components/ui/primitives/Button";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { type SpecializationId } from "@/lib/specializations";
import { connectSocket, getSocket } from "@/lib/socketClient";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";
import { useAgoraDevices } from "@/app/call/[channel]/_v2/hooks/useAgoraDevices";

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
  const e2eeSecret =
    typeof d.e2eeSecret === "string" && d.e2eeSecret.trim()
      ? d.e2eeSecret.trim()
      : undefined;

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
    ...(e2eeSecret ? { e2eeSecret } : {}),
  };
}

export default function CitizenHubPage() {
  const router = useRouter();
  const { t, locale } = useTranslation();
  const cookieConsentPending = useCookieConsentPending();
  const [sosDialogOpen, setSosDialogOpen] = useState(false);
  const [specializationDialogOpen, setSpecializationDialogOpen] = useState(false);
  const [callTypeDialogOpen, setCallTypeDialogOpen] = useState(false);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [entitlement, setEntitlement] = useState<Entitlement | null>(null);

  const isSearching = useEmergencyStore((s) => s.isSearching);
  const lawyerFound = useEmergencyStore((s) => s.lawyerFound);
  const lawyerName = useEmergencyStore((s) => s.lawyerName);
  const currentEventId = useEmergencyStore((s) => s.currentEventId);
  const sessionReady = useEmergencyStore((s) => s.sessionReady);
  const statusMessage = useEmergencyStore((s) => s.statusMessage);
  const { requestPermission } = useAgoraDevices();

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
    void fetchEntitlement()
      .then((next) => {
        if (!cancelled) setEntitlement(next);
      })
      .catch(() => {
        if (!cancelled) setEntitlement(null);
      });
    return () => {
      cancelled = true;
    };
  }, []);

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
      const msg =
        raw &&
        typeof raw === "object" &&
        "message" in raw &&
        typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : t("hub.errGeneric");
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
  }, [router, setErrorMessage, setLawyerFound, setSessionReady, t]);

  const handleSos = useCallback((specializationId: SpecializationId) => {
    if (!getJwt()) {
      router.push("/login");
      return;
    }
    if (entitlement && !entitlement.allowed) {
      if (entitlement.nextAction === "pricing" || entitlement.status === "payment_required") {
        router.push("/plans");
      } else {
        setErrorMessage(entitlement.reason);
      }
      return;
    }

    // startSearch() already clears statusMessage — do not call
    // setErrorMessage(null) here (that used to flip isSearching back off).
    startSearch();

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
      // Send the canonical English id; the backend resolves it to match terms.
      // For "general" we send undefined so the backend skips the spec filter.
      sock.emit("start_veto", {
        location: { lat, lng },
        preferredLanguage: locale,
        specialization: specializationId === "general" ? undefined : specializationId,
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
  }, [entitlement, locale, router, setErrorMessage, startSearch]);

  const confirmSos = useCallback(() => {
    setSosDialogOpen(false);
    // Show waiting UI immediately — specialization is chosen on top of it.
    startSearch();
    setSpecializationDialogOpen(true);
  }, [startSearch]);

  const selectSpecialization = useCallback(
    (specializationId: SpecializationId) => {
      setSpecializationDialogOpen(false);
      handleSos(specializationId);
    },
    [handleSos],
  );

  const cancelLawyerSearch = useCallback(() => {
    const eventId = useEmergencyStore.getState().currentEventId;
    try {
      const sock = getSocket();
      if (eventId) sock.emit("cancel_veto", { eventId });
    } catch {
      /* socket may not be ready — still clear local UI */
    }
    setCallTypeDialogOpen(false);
    reset();
  }, [reset]);

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
    setCallTypeDialogOpen(false);
  }, []);

  /**
   * Video/audio buttons: grant mic/camera permission in the SAME click as
   * picking the call type, so the /call/[channel] route can skip its own
   * PreCallCheck screen on the happy path. requestPermission() must be the
   * first statement (before chooseCallType's socket round trip) so the
   * getUserMedia() call still counts as user-gesture-triggered.
   */
  const chooseCallTypeWithPermission = useCallback(
    (callType: "video" | "audio") => {
      const needsCamera = callType === "video";
      useEmergencyStore.getState().setPreCallPermissionStatus("pending");
      void requestPermission({ mic: true, camera: needsCamera }).then(
        (granted) => {
          const store = useEmergencyStore.getState();
          if (granted) {
            store.setPreCallReadiness({
              micId: null,
              cameraId: null,
              speakerId: null,
              ready: true,
            });
            store.setPreCallPermissionStatus("granted");
          } else {
            store.setPreCallPermissionStatus("denied");
          }
        },
      );
      chooseCallType(callType);
    },
    [requestPermission, chooseCallType],
  );

  return (
    <>
      {/* Not <main> — the citizen layout already provides that landmark. */}
      <div
        className={`mx-auto flex w-full max-w-lg flex-1 flex-col items-center justify-center gap-8 px-6 py-12 ${
          cookieConsentPending
            ? "pb-[calc(20rem+env(safe-area-inset-bottom))]"
            : citizenBottomSafe
        }`}
      >
        <div className="w-full rounded-2xl border border-subtle bg-surface-raised px-5 py-6 text-center shadow-sm backdrop-blur-xl">
          <h1 className="font-frank text-2xl font-bold text-primary">
            {t("hub.title")}
          </h1>
          <p className="mt-2 text-sm text-secondary">{t("hub.subtitle")}</p>
        </div>

        <div className="w-full rounded-2xl border border-veto-gold/35 bg-veto-gold/10 px-4 py-3 text-sm shadow-sm backdrop-blur-xl">
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0 text-start">
              <p className="font-bold text-primary">
                {t("hub.subscriptionLabel")}
              </p>
              <p className="mt-0.5 truncate text-xs text-secondary">
                {profile?.full_name || profile?.phone || t("hub.defaultUserName")}
              </p>
            </div>
            <span className={`shrink-0 rounded-full px-3 py-1 text-xs font-black ${
              profile?.is_payment_exempt || profile?.is_subscribed
                ? "bg-emerald-100 text-emerald-900 dark:bg-emerald-950/60 dark:text-emerald-100"
                : "bg-amber-100 text-amber-950 dark:bg-amber-950/50 dark:text-amber-100"
            }`}>
              {profile?.is_payment_exempt
                ? t("hub.statusExempt")
                : profile?.is_subscribed
                  ? t("hub.statusActive")
                  : t("hub.statusInactive")}
            </span>
          </div>
          <p className="mt-2 text-start text-xs leading-5 text-secondary">
            {entitlement?.status === "exempt"
              ? t("hub.entitlementExempt")
              : entitlement?.status === "overtime_pending"
                ? t("hub.entitlementOvertime")
                : entitlement?.status === "consultation_paid"
                  ? t("hub.entitlementConsultation")
                  : entitlement?.status === "subscription_active" ||
                      entitlement?.status === "family_active"
                    ? t("hub.entitlementActive")
                    : t("hub.entitlementNone")}
          </p>
          {entitlement?.status === "overtime_pending" ? (
            <Link
              href="/plans"
              className="mt-3 inline-flex text-sm font-black text-brand-text underline-offset-2 transition hover:underline"
            >
              {t("hub.payOvertimeCta")}
            </Link>
          ) : entitlement?.status === "payment_required" ||
            (!profile?.is_payment_exempt && !profile?.is_subscribed) ? (
            <Link
              href="/plans"
              className="mt-3 inline-flex text-sm font-black text-brand-text underline-offset-2 transition hover:underline"
            >
              {t("hub.buyPlanCta")}
            </Link>
          ) : null}
        </div>

        <button
          type="button"
          onClick={() => setSosDialogOpen(true)}
          disabled={isSearching}
          className="sos-btn relative flex h-44 w-44 items-center justify-center rounded-full border-4 border-red-950 bg-red-700 text-lg font-bold text-white shadow-2xl shadow-red-900/50 transition enabled:cursor-pointer enabled:hover:bg-red-600 enabled:active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-70"
        >
          <span className="relative z-10">{t("hub.sos")}</span>
        </button>

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
      </div>

      <CitizenBottomNav active="hub" />

      {isSearching && !lawyerFound && !statusMessage ? (
        <SearchingLawyerOverlay
          phase="searching"
          onCancel={cancelLawyerSearch}
        />
      ) : null}

      {lawyerFound &&
      !callTypeDialogOpen &&
      !sessionReady &&
      !statusMessage ? (
        <SearchingLawyerOverlay
          phase="connecting"
          lawyerName={lawyerName}
        />
      ) : null}

      {statusMessage ? (
        <div
          className="fixed inset-0 z-[90] flex items-center justify-center bg-surface-scrim/90 p-4 backdrop-blur-md"
          role="alertdialog"
          aria-modal="true"
          aria-labelledby="hub-status-title"
        >
          <div className="w-full max-w-md rounded-2xl border border-red-400/40 bg-surface-raised px-6 py-8 text-center shadow-2xl">
            <h2
              id="hub-status-title"
              className="font-frank text-xl font-black text-primary"
            >
              {t("hub.statusAlertTitle")}
            </h2>
            <p className="mt-3 text-sm leading-6 text-secondary">{statusMessage}</p>
            <div className="mt-6">
              <Button variant="secondary" onClick={() => reset()}>
                {t("hub.dismiss")}
              </Button>
            </div>
          </div>
        </div>
      ) : null}

      {sosDialogOpen && (
        <div
          className="fixed inset-0 z-[80] flex items-center justify-center bg-surface-scrim p-4 backdrop-blur-sm"
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
              className="font-frank text-lg font-bold text-primary"
            >
              {t("hub.dialogTitle")}
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-secondary">
              {t("hub.dialogBody")}
            </p>
            <div className="mt-6 flex flex-wrap justify-end gap-2">
              <Button variant="secondary" onClick={() => setSosDialogOpen(false)}>
                {t("hub.dialogCancel")}
              </Button>
              <Button variant="danger" onClick={() => void confirmSos()}>
                {t("hub.dialogConfirm")}
              </Button>
            </div>
          </div>
        </div>
      )}

      <SpecializationDialog
        isOpen={specializationDialogOpen}
        onClose={() => {
          setSpecializationDialogOpen(false);
          // User backed out before picking a specialty — stop the waiting UI.
          if (!lawyerFound) reset();
        }}
        onSelect={selectSpecialization}
      />

      {callTypeDialogOpen && lawyerFound && currentEventId && (
        <div
          className="fixed inset-0 z-[95] flex items-center justify-center bg-surface-scrim p-4 backdrop-blur-sm"
          role="presentation"
          onClick={() => setCallTypeDialogOpen(false)}
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
              className="font-frank text-lg font-bold text-primary"
            >
              {t("dialog.chooseCallType")}
            </h2>
            <p className="mt-2 text-sm text-secondary">{t("hub.callTypeHint")}</p>
            <p className="mt-1 text-xs text-muted">
              {t("hub.callTypePermissionHint")}
            </p>

            <div className="mt-5 grid gap-2">
              <Button variant="secondary" onClick={() => chooseCallTypeWithPermission("video")}>
                {t("hub.callTypeVideo")}
              </Button>
              <Button variant="secondary" onClick={() => chooseCallTypeWithPermission("audio")}>
                {t("hub.callTypeAudio")}
              </Button>
              <Button variant="secondary" onClick={() => chooseCallType("chat")}>
                {t("hub.callTypeChat")}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
