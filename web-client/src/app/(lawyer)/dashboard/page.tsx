"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Suspense,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ComponentType,
} from "react";
import {
  Bell,
  BriefcaseBusiness,
  CalendarClock,
  Clock3,
  FolderLock,
  LayoutDashboard,
  LogOut,
  MapPin,
  MessageCircle,
  PhoneCall,
  Settings2,
  ShieldCheck,
  UserRound,
  Video,
  Wifi,
  WifiOff,
} from "lucide-react";
import {
  fetchProfile,
  updateLawyerAvailability,
  updateLawyerLocation,
  type UserProfile,
} from "@/api/userApi";
import { fetchLawyerCockpit, type LawyerCockpit } from "@/api/advancedApi";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { clearJwt, getJwt, getRoleFromJwt } from "@/lib/authToken";
import { useWebPush } from "@/hooks/useWebPush";
import { connectSocket, disconnectSocket, getSocket } from "@/lib/socketClient";
import { Button } from "@/components/ui/primitives/Button";
import { btnPrimaryDark, btnSecondaryGlass, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";
import { useLawyerStore, type LawyerActiveAlert } from "@/store/useLawyerStore";
import { useAgoraDevices } from "@/app/call/[channel]/_v2/hooks/useAgoraDevices";

type DashboardTab = "overview" | "calls" | "vault" | "chat" | "schedule" | "profile";

const tabs: Array<{
  id: DashboardTab;
  label: string;
  icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
}> = [
  { id: "overview", label: "דשבורד", icon: LayoutDashboard },
  { id: "calls", label: "ניהול קריאות", icon: PhoneCall },
  { id: "vault", label: "כספת", icon: FolderLock },
  { id: "chat", label: "צ׳אט", icon: MessageCircle },
  { id: "schedule", label: "ניהול תורים", icon: CalendarClock },
  { id: "profile", label: "זמינות ופרופיל", icon: Settings2 },
];

function parseEmergencyAlert(raw: unknown): LawyerActiveAlert | null {
  if (!raw || typeof raw !== "object") return null;
  const d = raw as Record<string, unknown>;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const loc = d.location;
  if (!eventId || !loc || typeof loc !== "object") return null;
  const lat = Number((loc as Record<string, unknown>).lat);
  const lng = Number((loc as Record<string, unknown>).lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;

  return {
    eventId,
    userId: typeof d.userId === "string" ? d.userId : d.userId != null ? String(d.userId) : null,
    userName: typeof d.userName === "string" ? d.userName : "",
    location: { lat, lng },
    language: typeof d.language === "string" ? d.language : "he",
    timestamp: typeof d.timestamp === "string" ? d.timestamp : new Date().toISOString(),
  };
}

function parseSessionReadyPayload(data: unknown): SessionReadyState | null {
  if (!data || typeof data !== "object") return null;
  const d = data as Record<string, unknown>;
  const roomId = typeof d.roomId === "string" ? d.roomId : null;
  const eventId = typeof d.eventId === "string" ? d.eventId : null;
  const agoraToken = typeof d.agoraToken === "string" ? d.agoraToken : "";
  const agoraUid = Number(d.agoraUid ?? 0);
  const callTypeRaw = d.callType;
  const callType: SessionCallType =
    callTypeRaw === "audio" || callTypeRaw === "chat" || callTypeRaw === "video"
      ? callTypeRaw
      : "video";
  const tokenExpiresAt = typeof d.tokenExpiresAt === "number" ? d.tokenExpiresAt : undefined;
  const e2eeSecret =
    typeof d.e2eeSecret === "string" && d.e2eeSecret.trim()
      ? d.e2eeSecret.trim()
      : undefined;

  if (!roomId || !eventId) return null;
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

function formatDateTime(raw?: string) {
  if (!raw) return "";
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return raw;
  return new Intl.DateTimeFormat("he-IL", { dateStyle: "short", timeStyle: "short" }).format(d);
}

function getUserIdFromJwt(): string | null {
  const token = getJwt();
  if (!token) return null;
  try {
    const payload = JSON.parse(
      atob(token.split(".")[1]?.replace(/-/g, "+").replace(/_/g, "/") ?? ""),
    ) as { userId?: string; id?: string; _id?: string; sub?: string };
    return payload.userId ?? payload.id ?? payload._id ?? payload.sub ?? null;
  } catch {
    return null;
  }
}

function getPersistedAvailabilityChoice(): boolean {
  if (typeof window === "undefined") return true;
  try {
    const raw = window.localStorage.getItem("veto-lawyer-availability");
    if (!raw) return true;
    const parsed = JSON.parse(raw) as { state?: { isAvailable?: unknown } };
    return typeof parsed.state?.isAvailable === "boolean" ? parsed.state.isAvailable : true;
  } catch {
    return true;
  }
}

export default function LawyerDashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center bg-surface-canvas text-muted">
          …
        </div>
      }
    >
      <LawyerDashboardInner />
    </Suspense>
  );
}

function LawyerDashboardInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useTranslation();
  const { subscribe: subscribeWebPush } = useWebPush();
  const [activeTab, setActiveTab] = useState<DashboardTab>("overview");
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [notifPermission, setNotifPermission] = useState<NotificationPermission | "unsupported">("unsupported");
  const [scheduleOpen, setScheduleOpen] = useState(true);
  const [autoAccept, setAutoAccept] = useState(false);
  const [currentLawyerId, setCurrentLawyerId] = useState<string | null>(null);
  const [availabilityLoaded, setAvailabilityLoaded] = useState(false);
  const [cockpit, setCockpit] = useState<LawyerCockpit | null>(null);

  const isAvailable = useLawyerStore((s) => s.isAvailable);
  const activeAlert = useLawyerStore((s) => s.activeAlert);
  const isAccepting = useLawyerStore((s) => s.isAccepting);
  const lastError = useLawyerStore((s) => s.lastError);
  const setAvailable = useLawyerStore((s) => s.setAvailable);
  const setActiveAlert = useLawyerStore((s) => s.setActiveAlert);
  const setAccepting = useLawyerStore((s) => s.setAccepting);
  const setLastError = useLawyerStore((s) => s.setLastError);
  const clearAlert = useLawyerStore((s) => s.clearAlert);
  const setSessionReady = useEmergencyStore((s) => s.setSessionReady);
  const { requestPermission } = useAgoraDevices();

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    if (getRoleFromJwt() !== "lawyer") router.replace("/hub");
  }, [router]);

  // Deep-link from SOS push / notification click:
  // /dashboard?eventId=…&tab=calls&lat=…&lng=…
  useEffect(() => {
    const eventId = searchParams.get("eventId");
    const tab = searchParams.get("tab");
    const lat = Number(searchParams.get("lat"));
    const lng = Number(searchParams.get("lng"));
    const userId = searchParams.get("userId");
    const userName = searchParams.get("userName") || "";
    const language = searchParams.get("language") || "he";
    const timestamp = searchParams.get("ts") || new Date().toISOString();

    queueMicrotask(() => {
      if (tab === "calls" || eventId) setActiveTab("calls");
      if (!eventId) return;
      const existing = useLawyerStore.getState().activeAlert;
      if (existing?.eventId === eventId) return;
      if (Number.isFinite(lat) && Number.isFinite(lng)) {
        setActiveAlert({
          eventId,
          userId,
          userName,
          location: { lat, lng },
          language,
          timestamp,
        });
      }
    });
  }, [searchParams, setActiveAlert]);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    queueMicrotask(() => {
      setCurrentLawyerId(getUserIdFromJwt());
      setNotifPermission(typeof Notification === "undefined" ? "unsupported" : Notification.permission);
    });
    void fetchProfile()
      .then((nextProfile) => {
        setProfile(nextProfile);
        const preferredAvailability = getPersistedAvailabilityChoice();
        setAvailable(preferredAvailability);
        void updateLawyerAvailability(preferredAvailability).catch((err) => {
          console.warn("[lawyer] initial availability sync failed", err);
        });
      })
      .catch(() => setProfile(null))
      .finally(() => setAvailabilityLoaded(true));
  }, [setAvailable]);

  // GPS heartbeat for SOS proximity sorting + last_seen
  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    if (typeof navigator === "undefined" || !navigator.geolocation) return;

    const publish = () => {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          void updateLawyerLocation(pos.coords.latitude, pos.coords.longitude).catch(() => {});
        },
        () => {},
        { enableHighAccuracy: false, maximumAge: 60_000, timeout: 15_000 },
      );
    };

    publish();
    const id = window.setInterval(publish, 3 * 60_000);
    return () => window.clearInterval(id);
  }, []);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    let cancelled = false;
    void fetchLawyerCockpit()
      .then((data) => {
        if (!cancelled) setCockpit(data);
      })
      .catch(() => {
        if (!cancelled) setCockpit(null);
      });
    return () => {
      cancelled = true;
    };
  }, [activeAlert?.eventId, isAvailable]);

  useEffect(() => {
    if (!availabilityLoaded || !getJwt() || getRoleFromJwt() !== "lawyer") return;
    const sock = connectSocket();

    const syncAvailability = () => {
      sock.emit("lawyer_availability", { available: useLawyerStore.getState().isAvailable });
    };
    if (sock.connected) syncAvailability();
    else sock.once("connect", syncAvailability);

    const onNewEmergency = (raw: unknown) => {
      const parsed = parseEmergencyAlert(raw);
      if (parsed) {
        setActiveAlert(parsed);
        setActiveTab("calls");
      }
    };
    const onCaseTaken = (raw: unknown) => {
      const assignedLawyerId =
        raw &&
        typeof raw === "object" &&
        "assignedLawyerId" in raw &&
        (raw as { assignedLawyerId?: unknown }).assignedLawyerId != null
          ? String((raw as { assignedLawyerId: unknown }).assignedLawyerId)
          : null;
      if (assignedLawyerId && currentLawyerId && assignedLawyerId === currentLawyerId) return;

      const eventId =
        raw && typeof raw === "object" && "eventId" in raw && typeof (raw as { eventId?: unknown }).eventId === "string"
          ? (raw as { eventId: string }).eventId
          : null;
      const state = useLawyerStore.getState().activeAlert;
      if (eventId && state?.eventId === eventId) {
        clearAlert();
        setLastError("הקריאה כבר נלקחה על ידי עורך דין אחר.");
      }
    };
    const onCaseAlreadyTaken = () => {
      setAccepting(false);
      setLastError("עורך דין אחר כבר קיבל את הקריאה.");
      clearAlert();
    };
    const onVetoError = (raw: unknown) => {
      setAccepting(false);
      const msg =
        raw && typeof raw === "object" && "message" in raw && typeof (raw as { message?: unknown }).message === "string"
          ? (raw as { message: string }).message
          : "הבקשה נכשלה. נסו שוב.";
      setLastError(msg);
    };
    const onSessionReady = (raw: unknown) => {
      const session = parseSessionReadyPayload(raw);
      if (!session) {
        setAccepting(false);
        setLastError("לא התקבלו פרטי שיחה תקינים.");
        return;
      }
      setSessionReady(session);
      setAccepting(false);
      clearAlert();
      router.push(`/call/${encodeURIComponent(session.channelId)}`);
    };

    sock.on("new_emergency_alert", onNewEmergency);
    sock.on("case_taken", onCaseTaken);
    sock.on("case_already_taken", onCaseAlreadyTaken);
    sock.on("veto_error", onVetoError);
    sock.on("session_ready", onSessionReady);

    return () => {
      sock.off("connect", syncAvailability);
      sock.off("new_emergency_alert", onNewEmergency);
      sock.off("case_taken", onCaseTaken);
      sock.off("case_already_taken", onCaseAlreadyTaken);
      sock.off("veto_error", onVetoError);
      sock.off("session_ready", onSessionReady);
    };
  }, [availabilityLoaded, clearAlert, currentLawyerId, router, setAccepting, setActiveAlert, setLastError, setSessionReady]);

  const handleAvailabilityChange = useCallback((next: boolean) => {
    setAvailable(next);
    setAvailabilityLoaded(true);
    void updateLawyerAvailability(next).catch((err) => {
      console.warn("[lawyer] availability update failed", err);
      setLastError("עדכון הזמינות בשרת נכשל. ננסה שוב כשהחיבור יתחדש.");
    });
    try {
      const sock = getSocket();
      if (!sock.connected) {
        sock.once("connect", () => sock.emit("lawyer_availability", { available: next }));
        sock.connect();
      } else {
        sock.emit("lawyer_availability", { available: next });
      }
    } catch {
      const sock = connectSocket();
      sock.once("connect", () => sock.emit("lawyer_availability", { available: next }));
      if (!sock.connected) sock.connect();
    }
    if (next) {
      void subscribeWebPush().then((result) => {
        if (typeof Notification !== "undefined") setNotifPermission(Notification.permission);
        if (!result.ok && result.reason !== "denied" && result.reason !== "unsupported") {
          console.warn("[push]", result.reason, result.message ?? "");
        }
      });
    }
  }, [setAvailable, setLastError, subscribeWebPush]);

  const handleAcceptCase = useCallback(() => {
    if (!activeAlert || isAccepting) return;
    setAccepting(true);
    setLastError(null);
    // Request mic/camera in the same click as accepting — the lawyer doesn't
    // know the citizen's chosen call type yet, so ask for both up front; an
    // unused camera track is simply never created if the citizen picks
    // audio/chat. This is the single user gesture that lets /call/[channel]
    // skip its own separate PreCallCheck screen on the happy path.
    useEmergencyStore.getState().setPreCallPermissionStatus("pending");
    void requestPermission({ mic: true, camera: true }).then((granted) => {
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
    });
    try {
      const sock = getSocket();
      if (!sock.connected) {
        sock.connect();
        sock.once("connect", () => sock.emit("accept_case", { eventId: activeAlert.eventId }));
      } else {
        sock.emit("accept_case", { eventId: activeAlert.eventId });
      }
    } catch {
      const sock = connectSocket();
      sock.once("connect", () => sock.emit("accept_case", { eventId: activeAlert.eventId }));
      sock.connect();
    }
  }, [activeAlert, isAccepting, setAccepting, setLastError, requestPermission]);

  const handleLogout = useCallback(() => {
    disconnectSocket();
    clearJwt();
    router.replace("/login");
  }, [router]);

  const formattedAlertTime = useMemo(() => formatDateTime(activeAlert?.timestamp), [activeAlert]);
  const displayName = profile?.full_name?.trim() || "עורך דין";

  return (
    <div className="min-h-full pb-12">
      <header className="border-b border-white/40 bg-white/70 shadow-sm backdrop-blur-xl">
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-4 md:flex-row md:items-center md:justify-between md:px-8">
          <div>
            <h1 className="font-frank text-2xl font-black text-primary">לוח עורך דין</h1>
            <p className="mt-1 text-sm text-secondary">
              קריאות, שיחות, כספת, תורים וזמינות במקום אחד.
            </p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className={`${glassPanelNested} flex items-center justify-between gap-4 px-4 py-3`}>
              <div className="flex items-center gap-2">
                {isAvailable ? <Wifi className="h-5 w-5 text-emerald-700" aria-hidden /> : <WifiOff className="h-5 w-5 text-muted" aria-hidden />}
                <div>
                  <p className="text-sm font-black text-primary">
                    {isAvailable ? "מחוברים וזמינים" : "לא מחוברים"}
                  </p>
                  <p className="text-xs text-secondary">
                    {notifPermission === "granted" ? "התראות דפדפן פעילות" : "הפעילו זמינות לקבלת SOS"}
                  </p>
                </div>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={isAvailable}
                aria-label={isAvailable ? "מחוברים וזמינים" : "לא מחוברים"}
                onClick={() => handleAvailabilityChange(!isAvailable)}
                className={`relative h-10 w-[4.5rem] rounded-full transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#C5A059] ${
                  isAvailable ? "bg-emerald-600" : "bg-zinc-300"
                }`}
              >
                <span className={`absolute top-1 h-8 w-8 rounded-full bg-surface-overlay shadow transition ${isAvailable ? "end-1" : "start-1"}`} />
              </button>
            </div>
            <Button
              variant="secondary"
              onClick={handleLogout}
              iconStart={<LogOut className="h-4 w-4" aria-hidden />}
            >
              התנתקות
            </Button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-3 py-5 sm:px-4 sm:py-6 md:px-8">
        {lastError && (
          <div className="mb-4 rounded-2xl border border-amber-200 bg-amber-50/90 px-4 py-3 text-sm font-semibold text-amber-950" role="alert">
            {lastError}
            <Button variant="link" size="sm" className="ms-3 h-auto p-0" onClick={() => setLastError(null)}>
              {t("lawyerDashboard.closeError")}
            </Button>
          </div>
        )}

        <nav
          className={`${glassPanelNested} grid grid-cols-2 gap-2 p-2 sm:grid-cols-3 md:grid-cols-6`}
          aria-label={t("lawyerDashboard.navAria")}
        >
          {tabs.map((tabItem) => {
            const Icon = tabItem.icon;
            const active = activeTab === tabItem.id;
            return (
              <button
                key={tabItem.id}
                type="button"
                onClick={() => setActiveTab(tabItem.id)}
                className={`flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl border px-2 py-2.5 text-center text-xs font-black transition sm:flex-row sm:gap-2 sm:px-3 sm:text-sm ${
                  active
                    ? "border-veto-gold/60 bg-veto-gold/20 text-primary shadow-md ring-1 ring-veto-gold/30" : "border-subtle bg-surface-raised text-primary hover:border-strong hover:bg-white"}`}
              >
                <Icon className="h-4 w-4 shrink-0" aria-hidden />
                <span className="leading-tight">{tabItem.label}</span>
              </button>
            );
          })}
        </nav>

        <div className="mt-5">
          {cockpit && (
            <section className={`${glassPanelNested} mb-5 grid gap-3 p-4 md:grid-cols-4`}>
              <MiniRow icon={ShieldCheck} title="Trust" value={cockpit.lawyer.trust?.license_verified ? t("lawyerDashboard.miniTrustVerified") : t("lawyerDashboard.miniTrustPending")} />
              <MiniRow icon={BriefcaseBusiness} title={t("lawyerDashboard.miniHandledCount")} value={String(cockpit.status.handledCount || 0)} />
              <MiniRow icon={Clock3} title={t("lawyerDashboard.miniAvgResponse")} value={cockpit.status.avgResponseSeconds ? `${cockpit.status.avgResponseSeconds}s` : t("lawyerDashboard.miniNoData")} />
              <MiniRow icon={Wifi} title={t("lawyerDashboard.miniWorkMode")} value={cockpit.status.busy ? t("lawyerDashboard.miniBusy") : t("lawyerDashboard.miniFree")} />
            </section>
          )}
          {activeTab === "overview" && (
            <OverviewPanel
              isAvailable={isAvailable}
              activeAlert={activeAlert}
              displayName={displayName}
              onOpenSchedule={() => setActiveTab("schedule")}
              t={t}
            />
          )}
          {activeTab === "calls" && (
            <CallsPanel
              activeAlert={activeAlert}
              formattedAlertTime={formattedAlertTime}
              isAvailable={isAvailable}
              isAccepting={isAccepting}
              onAccept={handleAcceptCase}
            />
          )}
          {activeTab === "vault" && <VaultPanel />}
          {activeTab === "chat" && <ChatPanel />}
          {activeTab === "schedule" && (
            <SchedulePanel
              scheduleOpen={scheduleOpen}
              setScheduleOpen={setScheduleOpen}
              autoAccept={autoAccept}
              setAutoAccept={setAutoAccept}
            />
          )}
          {activeTab === "profile" && (
            <ProfilePanel
              profile={profile}
              isAvailable={isAvailable}
              onAvailabilityChange={handleAvailabilityChange}
              notifPermission={notifPermission}
              onEnablePushNotifications={() => {
                void subscribeWebPush().then((result) => {
                  if (typeof Notification !== "undefined") {
                    setNotifPermission(Notification.permission);
                  }
                  if (!result.ok && result.reason !== "denied" && result.reason !== "unsupported") {
                    console.warn("[push]", result.reason, result.message ?? "");
                  }
                });
              }}
            />
          )}
        </div>
      </main>

      {activeAlert && (
        <IncomingCaseModal
          alert={activeAlert}
          formattedTime={formattedAlertTime}
          isAccepting={isAccepting}
          onAccept={handleAcceptCase}
        />
      )}
    </div>
  );
}

function OverviewPanel({
  isAvailable,
  activeAlert,
  displayName,
  onOpenSchedule,
  t,
}: {
  isAvailable: boolean;
  activeAlert: LawyerActiveAlert | null;
  displayName: string;
  onOpenSchedule: () => void;
  t: (key: string) => string;
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
        <div>
          <h2 className="font-frank text-2xl font-black text-primary">
            {t("lawyerDashboard.helloName").replace("{name}", displayName)}
          </h2>
          <p className="mt-1 text-sm leading-6 text-secondary">
            {t("lawyerDashboard.overviewIntro")}
          </p>
        </div>
        <span className={`w-fit rounded-full px-3 py-1 text-xs font-black ${isAvailable ? "bg-emerald-100 text-emerald-900" : "bg-zinc-200 text-secondary"}`}>
          {isAvailable ? t("lawyerDashboard.statusAvailable") : t("lawyerDashboard.statusUnavailable")}
        </span>
      </div>
      <div className="mt-6 grid gap-3 md:grid-cols-4">
        <StatCard title={t("lawyerDashboard.statActiveCase")} value={activeAlert ? "1" : "0"} icon={PhoneCall} />
        <StatCard title={t("lawyerDashboard.statAvailability")} value={isAvailable ? t("lawyerDashboard.statValueConnected") : t("lawyerDashboard.statValueDisconnected")} icon={Wifi} />
        <StatCard title={t("lawyerDashboard.statVault")} value={t("lawyerDashboard.statValueReady")} icon={FolderLock} />
        <StatCard title={t("lawyerDashboard.statQueueToday")} value={t("lawyerDashboard.statValueOpen")} icon={CalendarClock} />
      </div>
      <div className={`${glassPanelNested} mt-5 p-5`}>
        <h3 className="text-lg font-black text-primary">{t("lawyerDashboard.quickTasks")}</h3>
        <div className="mt-4 grid gap-2 md:grid-cols-3">
          <Link href="/chat" className={`px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>
            {t("lawyerDashboard.quickOpenChat")}
          </Link>
          <Link href="/vault" className={`px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>
            {t("lawyerDashboard.quickOpenVault")}
          </Link>
          <Button variant="secondary" onClick={onOpenSchedule}>
            {t("lawyerDashboard.quickEditSchedule")}
          </Button>
        </div>
      </div>
    </section>
  );
}

function CallsPanel({
  activeAlert,
  formattedAlertTime,
  isAvailable,
  isAccepting,
  onAccept,
}: {
  activeAlert: LawyerActiveAlert | null;
  formattedAlertTime: string;
  isAvailable: boolean;
  isAccepting: boolean;
  onAccept: () => void;
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <div>
        <h2 className="font-frank text-2xl font-black text-primary">ניהול קריאות</h2>
        <p className="mt-1 text-sm text-secondary">
          כאן מתקבלות קריאות SOS, פרטי מיקום, סוג התקשרות וקבלת התיק.
        </p>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <div className={`${glassPanelNested} min-h-72 p-5`}>
          {activeAlert ? (
            <CaseDetails alert={activeAlert} formattedAlertTime={formattedAlertTime} onAccept={onAccept} isAccepting={isAccepting} />
          ) : (
            <div className="flex min-h-64 flex-col items-center justify-center text-center">
              <Bell className="h-10 w-10 text-veto-gold-dark" aria-hidden />
              <p className="mt-4 text-lg font-black text-primary">אין קריאת חירום פעילה.</p>
              <p className="mt-2 max-w-md text-sm leading-6 text-secondary">
                {isAvailable ? "ממתינים לקריאת SOS. כשהיא תגיע, פרטי האזרח והמיקום יופיעו כאן." : "הפעילו זמינות כדי להתחיל לקבל קריאות."}
              </p>
            </div>
          )}
        </div>
        <div className={`${glassPanelNested} p-5`}>
          <h3 className="text-lg font-black text-primary">תור SOS חי</h3>
          <p className="mt-2 text-sm leading-6 text-secondary">
            קבלת תיק פותחת חדר שיחה מאובטח ומעבירה את האזרח למסך בחירת שיחה.
          </p>
          <div className="mt-5 space-y-3">
            <MiniRow icon={Clock3} title="עדיפות" value={activeAlert ? "גבוהה" : "אין פריטים"} />
            <MiniRow icon={Video} title="סוגים נתמכים" value="וידאו, אודיו, צ׳אט" />
            <MiniRow icon={ShieldCheck} title="אבטחה" value="חדר מאובטח לכל קריאה" />
          </div>
        </div>
      </div>
    </section>
  );
}

function VaultPanel() {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-primary">כספת משפטית</h2>
      <p className="mt-1 text-sm text-secondary">
        גישה למסמכים, ראיות וסיכומי שיחה שהאזרח משתף בתיק פעיל.
      </p>
      <div className="mt-5 grid gap-3 md:grid-cols-3">
        <FeatureCard icon={FolderLock} title="כספת תיק" body="פתחו את הכספת המלאה כדי לצפות במסמכים ובקבצים." href="/vault" action="פתח כספת" />
        <FeatureCard icon={BriefcaseBusiness} title="בקשות מסמכים" body="שלחו לאזרח בקשה להעלות תעודה, תמונה, חוזה או ראיה." href="/chat" action="בקש בצ׳אט" />
        <FeatureCard icon={ShieldCheck} title="שרשרת ראיות" body="בדקו מקור, זמן העלאה ושיתוף עם עורך הדין." href="/vault" action="בדוק הרשאות" />
      </div>
    </section>
  );
}

function ChatPanel() {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-primary">צ׳אט עם אזרחים</h2>
      <p className="mt-1 text-sm text-secondary">
        שיחות עם אזרחים מאושרים, כולל המשך שיחה לאחר SOS וצירוף מסמכים מהכספת.
      </p>
      <div className={`${glassPanelNested} mt-5 p-5`}>
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-lg font-black text-primary">חלון השיחה המלא</p>
            <p className="mt-1 text-sm text-secondary">רשימת שיחות, הודעות, שליחה ומחיקה לפי הרשאות השרת.</p>
          </div>
          <Link href="/chat" className={`px-5 py-3 text-center text-sm font-black ${btnPrimaryDark}`}>
            פתח צ׳אט
          </Link>
        </div>
      </div>
    </section>
  );
}

const LAWYER_HOURS_STORAGE_KEY = "veto-lawyer-schedule-hours";

function SchedulePanel({
  scheduleOpen,
  setScheduleOpen,
  autoAccept,
  setAutoAccept,
}: {
  scheduleOpen: boolean;
  setScheduleOpen: (value: boolean) => void;
  autoAccept: boolean;
  setAutoAccept: (value: boolean) => void;
}) {
  const [hourOpen, setHourOpen] = useState<boolean[]>(() =>
    Array.from({ length: 24 }, () => false),
  );
  const [hoursHydrated, setHoursHydrated] = useState(false);

  useEffect(() => {
    queueMicrotask(() => {
      try {
        const raw = window.localStorage.getItem(LAWYER_HOURS_STORAGE_KEY);
        if (raw) {
          const arr = JSON.parse(raw) as unknown;
          if (Array.isArray(arr) && arr.length === 24) {
            setHourOpen(arr.map((x) => Boolean(x)));
          }
        }
      } catch {
        /* ignore */
      }
      setHoursHydrated(true);
    });
  }, []);

  useEffect(() => {
    if (!hoursHydrated || typeof window === "undefined") return;
    try {
      window.localStorage.setItem(
        LAWYER_HOURS_STORAGE_KEY,
        JSON.stringify(hourOpen),
      );
    } catch {
      /* ignore */
    }
  }, [hourOpen, hoursHydrated]);

  const toggleHour = (h: number) => {
    setHourOpen((prev) => {
      const next = [...prev];
      next[h] = !next[h];
      return next;
    });
  };

  const applyPreset = (preset: "business" | "clear") => {
    if (preset === "clear") {
      setHourOpen(Array.from({ length: 24 }, () => false));
      return;
    }
    const next = Array.from({ length: 24 }, () => false);
    for (let h = 9; h <= 17; h += 1) next[h] = true;
    setHourOpen(next);
  };

  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-primary">ניהול תורים</h2>
      <p className="mt-1 text-sm text-secondary">הגדרת שעות פעילות, ייעוצים מתוכננים ותזכורות.</p>
      <div className="mt-5 grid gap-3 md:grid-cols-2">
        <ToggleLine title="יומן פתוח להזמנות" body="אזרחים יוכלו לבקש ייעוץ מתוכנן." checked={scheduleOpen} onChange={setScheduleOpen} />
        <ToggleLine title="קבלה מהירה של תיק מתאים" body="המערכת תבליט קריאות שתואמות את ההתמחות." checked={autoAccept} onChange={setAutoAccept} />
      </div>

      <div className="mt-6">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <h3 className="text-sm font-black text-primary">שעות זמינות ביממה (00–23)</h3>
          <div className="flex flex-wrap gap-2">
            <Button variant="secondary" size="sm" onClick={() => applyPreset("business")}>
              09:00–17:00
            </Button>
            <Button variant="secondary" size="sm" onClick={() => applyPreset("clear")}>
              נקה הכל
            </Button>
          </div>
        </div>
        <p className="mt-1 text-xs text-muted">
          סמנו כל שעה שבה אתם מוכנים לקבוע ייעוץ או להופיע ביומן. השמירה היא מקומית בדפדפן (לפני חיבור לשרת).
        </p>
        <div className="mt-3 grid grid-cols-4 gap-2 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-12">
          {hourOpen.map((on, h) => (
            <button
              key={h}
              type="button"
              onClick={() => toggleHour(h)}
              className={`rounded-lg border px-1 py-2 text-center text-[11px] font-black transition sm:text-xs ${
                on
                  ? "border-veto-gold/70 bg-veto-gold/25 text-primary shadow-sm" : "border-subtle bg-surface-raised-2 text-secondary hover:border-strong"}`}
              aria-pressed={on}
            >
              {`${String(h).padStart(2, "0")}`}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}

function ProfilePanel({
  profile,
  isAvailable,
  onAvailabilityChange,
  notifPermission,
  onEnablePushNotifications,
}: {
  profile: UserProfile | null;
  isAvailable: boolean;
  onAvailabilityChange: (value: boolean) => void;
  notifPermission: NotificationPermission | "unsupported";
  onEnablePushNotifications: () => void;
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-primary">זמינות ופרופיל</h2>
      <p className="mt-1 text-sm text-secondary">פרטי עורך הדין והסטטוס שמפעיל קבלת קריאות.</p>
      <div className="mt-5 grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
        <div className={`${glassPanelNested} p-5`}>
          <UserRound className="h-9 w-9 text-veto-gold-dark" aria-hidden />
          <p className="mt-4 text-lg font-black text-primary">{profile?.full_name || "עורך דין"}</p>
          <p className="mt-1 text-sm text-secondary">{profile?.email || "מייל לא מוגדר"}</p>
          <p className="mt-1 text-sm text-secondary">{profile?.phone || "טלפון לא מוגדר"}</p>
        </div>
        <div className={`${glassPanelNested} p-5`}>
          <ToggleLine title="מחובר לקבלת SOS" body="כשהמתג פעיל, קריאות חירום יכולות להגיע למסך הזה." checked={isAvailable} onChange={onAvailabilityChange} />
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            <MiniRow icon={Bell} title="התראות" value={notifPermission === "granted" ? "פעילות" : "לא פעילות"} />
            <MiniRow icon={ShieldCheck} title="הרשאה" value="עורך דין" />
          </div>
          {notifPermission !== "unsupported" && notifPermission !== "granted" ? (
            <Button variant="primary" fullWidth className="mt-4" onClick={onEnablePushNotifications}>
              הפעלת התראות דחיפה (SOS)
            </Button>
          ) : null}
        </div>
      </div>
    </section>
  );
}

function IncomingCaseModal({
  alert,
  formattedTime,
  isAccepting,
  onAccept,
}: {
  alert: LawyerActiveAlert;
  formattedTime: string;
  isAccepting: boolean;
  onAccept: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-surface-scrim p-4 backdrop-blur-sm sm:items-center" role="dialog" aria-modal="true">
      <div className={`${glassPanel} w-full max-w-xl overflow-hidden border-red-200/80 bg-surface-raised`}>
        <div className="bg-red-600 px-6 py-4 text-inverse">
          <p className="text-xs font-black uppercase tracking-widest text-red-100">SOS LIVE</p>
          <h2 className="mt-1 text-2xl font-black">קריאת חירום נכנסת</h2>
          <p className="mt-1 text-sm text-red-100">{formattedTime}</p>
        </div>
        <div className="space-y-4 p-6">
          <CaseDetails alert={alert} formattedAlertTime={formattedTime} onAccept={onAccept} isAccepting={isAccepting} compact />
        </div>
      </div>
    </div>
  );
}

function CaseDetails({
  alert,
  formattedAlertTime,
  onAccept,
  isAccepting,
  compact = false,
}: {
  alert: LawyerActiveAlert;
  formattedAlertTime: string;
  onAccept: () => void;
  isAccepting: boolean;
  compact?: boolean;
}) {
  return (
    <div>
      <div className="grid gap-3 sm:grid-cols-2">
        <MiniRow icon={UserRound} title="אזרח" value={alert.userName.trim() || "לא ידוע"} />
        <MiniRow icon={Clock3} title="זמן" value={formattedAlertTime || "עכשיו"} />
        <MiniRow icon={MapPin} title="מיקום" value={`${alert.location.lat.toFixed(5)}, ${alert.location.lng.toFixed(5)}`} />
        <MiniRow icon={MessageCircle} title="שפה" value={alert.language} />
      </div>
      <div className={`${glassPanelNested} mt-4 p-4`}>
        <p className="text-xs font-bold text-muted">מזהה אירוע</p>
        <p className="mt-1 break-all font-mono text-xs text-primary">{alert.eventId}</p>
      </div>
      <Button variant="primary" size="lg" fullWidth className="mt-4" disabled={isAccepting} loading={isAccepting} onClick={onAccept}>
        {isAccepting ? "מקבל את הקריאה..." : "קבל קריאה ופתח שיחה"}
      </Button>
      {!compact && (
        <p className="mt-3 text-center text-xs text-muted">
          לאחר הקבלה האזרח יבחר וידאו, אודיו או צ׳אט. בלחיצה על הכפתור תתבקשו לאשר גישה למצלמה ולמיקרופון.
        </p>
      )}
    </div>
  );
}

function StatCard({
  title,
  value,
  icon: Icon,
}: {
  title: string;
  value: string;
  icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
}) {
  return (
    <div className={`${glassPanelNested} p-4`}>
      <Icon className="h-5 w-5 text-veto-gold-dark" aria-hidden />
      <p className="mt-4 text-xs font-bold text-muted">{title}</p>
      <p className="mt-1 text-lg font-black text-primary">{value}</p>
    </div>
  );
}

function MiniRow({
  title,
  value,
  icon: Icon,
}: {
  title: string;
  value: string;
  icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
}) {
  return (
    <div className="rounded-2xl border border-subtle bg-surface-raised p-4">
      <div className="flex items-start gap-3">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-veto-gold-dark" aria-hidden />
        <div className="min-w-0">
          <p className="text-xs font-bold text-muted">{title}</p>
          <p className="mt-1 break-words text-sm font-black text-primary">{value}</p>
        </div>
      </div>
    </div>
  );
}

function FeatureCard({
  icon: Icon,
  title,
  body,
  action,
  href,
}: {
  icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }>;
  title: string;
  body: string;
  action: string;
  href: string;
}) {
  return (
    <div className={`${glassPanelNested} p-5`}>
      <Icon className="h-7 w-7 text-veto-gold-dark" aria-hidden />
      <h3 className="mt-4 text-lg font-black text-primary">{title}</h3>
      <p className="mt-2 min-h-16 text-sm leading-6 text-secondary">{body}</p>
      <Link href={href} className={`mt-4 block w-full px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>
        {action}
      </Link>
    </div>
  );
}

function ToggleLine({
  title,
  body,
  checked,
  onChange,
}: {
  title: string;
  body: string;
  checked: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className={`${glassPanelNested} flex items-center justify-between gap-4 p-4`}>
      <div>
        <p className="text-sm font-black text-primary">{title}</p>
        <p className="mt-1 text-xs leading-5 text-secondary">{body}</p>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={title}
        onClick={() => onChange(!checked)}
        className={`relative h-8 w-14 shrink-0 rounded-full transition ${checked ? "bg-veto-gold" : "bg-zinc-300"}`}
      >
        <span className={`absolute top-1 h-6 w-6 rounded-full bg-surface-overlay shadow transition ${checked ? "end-1" : "start-1"}`} />
      </button>
    </div>
  );
}
