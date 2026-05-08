"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useState, type ComponentType } from "react";
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
import { fetchProfile, type UserProfile } from "@/api/userApi";
import { clearJwt, getJwt, getRoleFromJwt } from "@/lib/authToken";
import { subscribeToPush } from "@/lib/pushClient";
import { connectSocket, disconnectSocket, getSocket } from "@/lib/socketClient";
import {
  btnPrimaryDark,
  btnPrimaryGold,
  btnSecondaryGlass,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";
import {
  useEmergencyStore,
  type SessionCallType,
  type SessionReadyState,
} from "@/store/useEmergencyStore";
import {
  useLawyerStore,
  type LawyerActiveAlert,
} from "@/store/useLawyerStore";

type DashboardTab = "overview" | "calls" | "vault" | "chat" | "schedule" | "profile";

const tabs: Array<{ id: DashboardTab; label: string; icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }> }> = [
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
  const lat = (loc as Record<string, unknown>).lat;
  const lng = (loc as Record<string, unknown>).lng;
  const latN = typeof lat === "number" ? lat : Number(lat);
  const lngN = typeof lng === "number" ? lng : Number(lng);
  if (!Number.isFinite(latN) || !Number.isFinite(lngN)) return null;

  return {
    eventId,
    userId: typeof d.userId === "string" ? d.userId : d.userId != null ? String(d.userId) : null,
    userName: typeof d.userName === "string" ? d.userName : "",
    location: { lat: latN, lng: lngN },
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
  const agoraUidRaw = d.agoraUid;
  const agoraUid =
    typeof agoraUidRaw === "number"
      ? agoraUidRaw
      : typeof agoraUidRaw === "string" && agoraUidRaw !== ""
        ? Number(agoraUidRaw)
        : 0;
  const callTypeRaw = d.callType;
  const callType: SessionCallType =
    callTypeRaw === "audio" || callTypeRaw === "chat" || callTypeRaw === "video"
      ? callTypeRaw
      : "video";
  const tokenExpiresAt = typeof d.tokenExpiresAt === "number" ? d.tokenExpiresAt : undefined;

  if (!roomId || !eventId) return null;
  return { channelId: roomId, eventId, token: agoraToken, uid: agoraUid, callType, tokenExpiresAt };
}

function formatDateTime(raw?: string) {
  if (!raw) return "";
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return raw;
  return new Intl.DateTimeFormat("he-IL", { dateStyle: "short", timeStyle: "short" }).format(d);
}

export default function LawyerDashboardPage() {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<DashboardTab>("overview");
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [notifPermission, setNotifPermission] = useState<NotificationPermission | "unsupported">("unsupported");
  const [scheduleOpen, setScheduleOpen] = useState(true);
  const [autoAccept, setAutoAccept] = useState(false);
  const [showStress, setShowStress] = useState(false);

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

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    if (getRoleFromJwt() !== "lawyer") {
      router.replace("/hub");
    }
  }, [router]);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    queueMicrotask(() => {
      setNotifPermission(typeof Notification === "undefined" ? "unsupported" : Notification.permission);
    });
    void fetchProfile().then(setProfile).catch(() => setProfile(null));
  }, []);

  useEffect(() => {
    if (!getJwt() || getRoleFromJwt() !== "lawyer") return;
    const sock = connectSocket();

    const syncLawyerAvailability = () => {
      sock.emit("lawyer_availability", { available: useLawyerStore.getState().isAvailable });
    };
    if (sock.connected) syncLawyerAvailability();
    else sock.once("connect", syncLawyerAvailability);

    const onNewEmergency = (raw: unknown) => {
      const parsed = parseEmergencyAlert(raw);
      if (parsed) {
        setActiveAlert(parsed);
        setActiveTab("calls");
      }
    };
    const onCaseTaken = (raw: unknown) => {
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
      setLastError("עורך דין אחר קיבל את הקריאה.");
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
      sock.off("connect", syncLawyerAvailability);
      sock.off("new_emergency_alert", onNewEmergency);
      sock.off("case_taken", onCaseTaken);
      sock.off("case_already_taken", onCaseAlreadyTaken);
      sock.off("veto_error", onVetoError);
      sock.off("session_ready", onSessionReady);
    };
  }, [clearAlert, router, setAccepting, setActiveAlert, setLastError, setSessionReady]);

  const handleAvailabilityChange = useCallback((next: boolean) => {
    setAvailable(next);
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
      void subscribeToPush().then((result) => {
        if (typeof Notification !== "undefined") setNotifPermission(Notification.permission);
        if (!result.ok && result.reason !== "denied" && result.reason !== "unsupported") {
          console.warn("[push]", result.reason, result.message ?? "");
        }
      });
    }
  }, [setAvailable]);

  const handleAcceptCase = useCallback(() => {
    if (!activeAlert || isAccepting) return;
    setAccepting(true);
    setLastError(null);
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
  }, [activeAlert, isAccepting, setAccepting, setLastError]);

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
            <p className="text-xs font-black uppercase tracking-widest text-blue-600">VETO LEGAL</p>
            <h1 className="font-frank text-2xl font-black text-slate-950">לוח עורך דין</h1>
            <p className="mt-1 text-sm text-slate-600">קריאות, שיחות, כספת, תורים וזמינות במקום אחד.</p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className={`${glassPanelNested} flex items-center justify-between gap-4 px-4 py-3`}>
            <div className="flex items-center gap-2">
              {isAvailable ? <Wifi className="h-5 w-5 text-emerald-700" aria-hidden /> : <WifiOff className="h-5 w-5 text-slate-500" aria-hidden />}
              <div>
                <p className="text-sm font-black text-slate-900">{isAvailable ? "מחוברים וזמינים" : "לא מחוברים"}</p>
                <p className="text-xs text-slate-600">{notifPermission === "granted" ? "התראות דפדפן פעילות" : "הפעילו זמינות לקבלת SOS"}</p>
              </div>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={isAvailable}
              onClick={() => handleAvailabilityChange(!isAvailable)}
              className={`relative h-10 w-[4.5rem] rounded-full transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#C5A059] ${
                isAvailable ? "bg-emerald-600" : "bg-slate-300"
              }`}
            >
              <span className={`absolute top-1 h-8 w-8 rounded-full bg-white shadow transition ${isAvailable ? "end-1" : "start-1"}`} />
            </button>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className={`flex items-center justify-center gap-2 px-4 py-3 text-sm font-black ${btnSecondaryGlass}`}
          >
            <LogOut className="h-4 w-4" aria-hidden />
            התנתקות
          </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-6 md:px-8">
        {lastError && (
          <div className="mb-4 rounded-2xl border border-amber-200 bg-amber-50/90 px-4 py-3 text-sm font-semibold text-amber-950" role="alert">
            {lastError}
            <button type="button" onClick={() => setLastError(null)} className="ms-3 underline">
              סגור
            </button>
          </div>
        )}

        <nav className={`${glassPanelNested} grid grid-cols-2 gap-2 p-2 md:grid-cols-6`} aria-label="ניווט עורך דין">
          {tabs.map((tabItem) => {
            const Icon = tabItem.icon;
            const active = activeTab === tabItem.id;
            return (
              <button
                key={tabItem.id}
                type="button"
                onClick={() => setActiveTab(tabItem.id)}
                className={`flex min-h-14 items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-black transition ${
                  active ? "bg-slate-900 text-white shadow-lg" : "text-slate-700 hover:bg-white/55"
                }`}
              >
                <Icon className="h-4 w-4" aria-hidden />
                {tabItem.label}
              </button>
            );
          })}
        </nav>

        <div className="mt-5">
          {activeTab === "overview" && <OverviewPanel isAvailable={isAvailable} activeAlert={activeAlert} displayName={displayName} onOpenSchedule={() => setActiveTab("schedule")} />}
          {activeTab === "calls" && (
            <CallsPanel
              activeAlert={activeAlert}
              formattedAlertTime={formattedAlertTime}
              isAvailable={isAvailable}
              isAccepting={isAccepting}
              showStress={showStress}
              setShowStress={setShowStress}
              onAccept={handleAcceptCase}
            />
          )}
          {activeTab === "vault" && <VaultPanel />}
          {activeTab === "chat" && <ChatPanel />}
          {activeTab === "schedule" && (
            <SchedulePanel scheduleOpen={scheduleOpen} setScheduleOpen={setScheduleOpen} autoAccept={autoAccept} setAutoAccept={setAutoAccept} />
          )}
          {activeTab === "profile" && (
            <ProfilePanel profile={profile} isAvailable={isAvailable} onAvailabilityChange={handleAvailabilityChange} notifPermission={notifPermission} />
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
}: {
  isAvailable: boolean;
  activeAlert: LawyerActiveAlert | null;
  displayName: string;
  onOpenSchedule: () => void;
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
        <div>
          <h2 className="font-frank text-2xl font-black text-slate-950">שלום, {displayName}</h2>
          <p className="mt-1 text-sm leading-6 text-slate-600">המערכת מאזינה לקריאות SOS בזמן אמת ומכינה שיחה מאובטחת ברגע שאתם מקבלים תיק.</p>
        </div>
        <span className={`w-fit rounded-full px-3 py-1 text-xs font-black ${isAvailable ? "bg-emerald-100 text-emerald-900" : "bg-slate-200 text-slate-700"}`}>
          {isAvailable ? "זמין לקריאות" : "לא זמין"}
        </span>
      </div>
      <div className="mt-6 grid gap-3 md:grid-cols-4">
        <StatCard title="קריאה פעילה" value={activeAlert ? "1" : "0"} icon={PhoneCall} />
        <StatCard title="מצב זמינות" value={isAvailable ? "מחובר" : "מנותק"} icon={Wifi} />
        <StatCard title="תיקים בכספת" value="מוכן" icon={FolderLock} />
        <StatCard title="תור היום" value="פתוח" icon={CalendarClock} />
      </div>
      <div className={`${glassPanelNested} mt-5 p-5`}>
        <h3 className="text-lg font-black text-slate-950">משימות מהירות</h3>
        <div className="mt-4 grid gap-2 md:grid-cols-3">
          <Link href="/chat" className={`px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>פתח צ׳אט</Link>
          <button type="button" className={`px-4 py-3 text-sm font-bold ${btnSecondaryGlass}`}>צפה בכספת תיק</button>
          <button type="button" onClick={onOpenSchedule} className={`px-4 py-3 text-sm font-bold ${btnSecondaryGlass}`}>עדכן שעות זמינות</button>
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
  showStress,
  setShowStress,
  onAccept,
}: {
  activeAlert: LawyerActiveAlert | null;
  formattedAlertTime: string;
  isAvailable: boolean;
  isAccepting: boolean;
  showStress: boolean;
  setShowStress: (value: boolean) => void;
  onAccept: () => void;
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="font-frank text-2xl font-black text-slate-950">ניהול קריאות</h2>
          <p className="mt-1 text-sm text-slate-600">כאן מתקבלות קריאות SOS, פרטי המיקום, סוג התקשורת והפעולה לקבלת התיק.</p>
        </div>
        <label className="flex w-fit items-center gap-2 rounded-xl border border-white/40 bg-white/35 px-3 py-2 text-sm font-semibold text-slate-700">
          <input type="checkbox" checked={showStress} onChange={(e) => setShowStress(e.target.checked)} />
          הצג אירועי QA / stress
        </label>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <div className={`${glassPanelNested} min-h-72 p-5`}>
          {activeAlert ? (
            <CaseDetails alert={activeAlert} formattedAlertTime={formattedAlertTime} onAccept={onAccept} isAccepting={isAccepting} />
          ) : (
            <div className="flex min-h-64 flex-col items-center justify-center text-center">
              <Bell className="h-10 w-10 text-[#9b7430]" aria-hidden />
              <p className="mt-4 text-lg font-black text-slate-900">אין קריאת חירום פעילה.</p>
              <p className="mt-2 max-w-md text-sm leading-6 text-slate-600">
                {isAvailable ? "מחכים לקריאת SOS. כשהיא תגיע, פרטי האזרח והמיקום יופיעו כאן." : "הפעילו זמינות כדי להתחיל לקבל קריאות."}
              </p>
            </div>
          )}
        </div>
        <div className={`${glassPanelNested} p-5`}>
          <h3 className="text-lg font-black text-slate-950">תור SOS חי</h3>
          <p className="mt-2 text-sm leading-6 text-slate-600">ממויין לפי דחיפות וזמן. קבלת תיק פותחת חדר שיחה מאובטח ומעבירה את האזרח למסך בחירת שיחה.</p>
          <div className="mt-5 space-y-3">
            <MiniRow icon={Clock3} title="עדיפות" value={activeAlert ? "גבוהה" : "אין פריטים"} />
            <MiniRow icon={Video} title="סוגים נתמכים" value="וידאו, אודיו, צ׳אט" />
            <MiniRow icon={ShieldCheck} title="אבטחה" value="חדר מוצפן לכל קריאה" />
          </div>
        </div>
      </div>
    </section>
  );
}

function VaultPanel() {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-slate-950">כספת משפטית</h2>
      <p className="mt-1 text-sm text-slate-600">גישה למסמכים, ראיות וסיכומי שיחה שהאזרח משתף בתיק פעיל.</p>
      <div className="mt-5 grid gap-3 md:grid-cols-3">
        <FeatureCard icon={FolderLock} title="כספת תיק" body="לאחר קבלת קריאה, המסמכים המשויכים לתיק יוצגו כאן." action="פתח תיק פעיל" />
        <FeatureCard icon={BriefcaseBusiness} title="בקשות מסמכים" body="שלחו בקשה לאזרח להעלות תעודה, תמונה, חוזה או ראיה." action="צור בקשה" />
        <FeatureCard icon={ShieldCheck} title="שרשרת ראיות" body="שמירה על מקור, זמן העלאה ושיתוף עם עורך הדין." action="בדוק הרשאות" />
      </div>
    </section>
  );
}

function ChatPanel() {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-slate-950">צ׳אט עם אזרחים</h2>
      <p className="mt-1 text-sm text-slate-600">שיחות עם אזרחים מאושרים, כולל המשך שיחה לאחר SOS וצירוף מסמכים מהכספת.</p>
      <div className={`${glassPanelNested} mt-5 p-5`}>
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-lg font-black text-slate-900">חלון השיחה המלא</p>
            <p className="mt-1 text-sm text-slate-600">כולל רשימת שיחות, טעינת הודעות, שליחה ומחיקה לפי הרשאות השרת.</p>
          </div>
          <Link href="/chat" className={`px-5 py-3 text-center text-sm font-black ${btnPrimaryDark}`}>
            פתח צ׳אט
          </Link>
        </div>
      </div>
    </section>
  );
}

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
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-slate-950">ניהול תורים</h2>
      <p className="mt-1 text-sm text-slate-600">הגדרת שעות פעילות, ייעוצים מתוכננים ותזכורות.</p>
      <div className="mt-5 grid gap-3 md:grid-cols-2">
        <ToggleLine title="יומן פתוח להזמנות" body="אזרחים יוכלו לבקש ייעוץ מתוכנן." checked={scheduleOpen} onChange={setScheduleOpen} />
        <ToggleLine title="קבלה מהירה של תיק מתאים" body="המערכת תבליט קריאות שתואמות את ההתמחות." checked={autoAccept} onChange={setAutoAccept} />
      </div>
      <div className="mt-5 grid gap-3 md:grid-cols-3">
        {["09:00-12:00", "13:00-16:00", "18:00-21:00"].map((slot) => (
          <button key={slot} type="button" className={`px-4 py-4 text-sm font-black ${btnSecondaryGlass}`}>
            {slot}
          </button>
        ))}
      </div>
    </section>
  );
}

function ProfilePanel({
  profile,
  isAvailable,
  onAvailabilityChange,
  notifPermission,
}: {
  profile: UserProfile | null;
  isAvailable: boolean;
  onAvailabilityChange: (value: boolean) => void;
  notifPermission: NotificationPermission | "unsupported";
}) {
  return (
    <section className={`${glassPanel} p-5 md:p-7`}>
      <h2 className="font-frank text-2xl font-black text-slate-950">זמינות ופרופיל</h2>
      <p className="mt-1 text-sm text-slate-600">פרטי עורך הדין והסטטוס שמפעיל קבלת קריאות.</p>
      <div className="mt-5 grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
        <div className={`${glassPanelNested} p-5`}>
          <UserRound className="h-9 w-9 text-[#9b7430]" aria-hidden />
          <p className="mt-4 text-lg font-black text-slate-900">{profile?.full_name || "עורך דין"}</p>
          <p className="mt-1 text-sm text-slate-600">{profile?.email || "מייל לא מוגדר"}</p>
          <p className="mt-1 text-sm text-slate-600">{profile?.phone || "טלפון לא מוגדר"}</p>
        </div>
        <div className={`${glassPanelNested} p-5`}>
          <ToggleLine title="מחובר לקבלת SOS" body="כשהמתג פעיל, קריאות חירום יכולות להגיע למסך הזה." checked={isAvailable} onChange={onAvailabilityChange} />
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            <MiniRow icon={Bell} title="התראות" value={notifPermission === "granted" ? "פעילות" : "לא פעילות"} />
            <MiniRow icon={ShieldCheck} title="הרשאה" value="עורך דין" />
          </div>
        </div>
      </div>
    </section>
  );
}

function IncomingCaseModal({ alert, formattedTime, isAccepting, onAccept }: { alert: LawyerActiveAlert; formattedTime: string; isAccepting: boolean; onAccept: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/60 p-4 backdrop-blur-sm sm:items-center" role="dialog" aria-modal="true">
      <div className={`${glassPanel} w-full max-w-xl overflow-hidden border-red-200/80 bg-white/85`}>
        <div className="bg-red-600 px-6 py-4 text-white">
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

function CaseDetails({ alert, formattedAlertTime, onAccept, isAccepting, compact = false }: { alert: LawyerActiveAlert; formattedAlertTime: string; onAccept: () => void; isAccepting: boolean; compact?: boolean }) {
  return (
    <div>
      <div className="grid gap-3 sm:grid-cols-2">
        <MiniRow icon={UserRound} title="אזרח" value={alert.userName.trim() || "לא ידוע"} />
        <MiniRow icon={Clock3} title="זמן" value={formattedAlertTime || "עכשיו"} />
        <MiniRow icon={MapPin} title="מיקום" value={`${alert.location.lat.toFixed(5)}, ${alert.location.lng.toFixed(5)}`} />
        <MiniRow icon={MessageCircle} title="שפה" value={alert.language} />
      </div>
      <div className={`${glassPanelNested} mt-4 p-4`}>
        <p className="text-xs font-bold text-slate-500">מזהה אירוע</p>
        <p className="mt-1 break-all font-mono text-xs text-slate-800">{alert.eventId}</p>
      </div>
      <button type="button" disabled={isAccepting} onClick={onAccept} className={`mt-4 w-full px-5 py-4 text-base font-black ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-60`}>
        {isAccepting ? "מקבל את הקריאה..." : "קבל קריאה ופתח שיחה"}
      </button>
      {!compact && <p className="mt-3 text-center text-xs text-slate-500">לאחר הקבלה האזרח יבחר וידאו, אודיו או צ׳אט.</p>}
    </div>
  );
}

function StatCard({ title, value, icon: Icon }: { title: string; value: string; icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }> }) {
  return (
    <div className={`${glassPanelNested} p-4`}>
      <Icon className="h-5 w-5 text-[#9b7430]" aria-hidden />
      <p className="mt-4 text-xs font-bold text-slate-500">{title}</p>
      <p className="mt-1 text-lg font-black text-slate-950">{value}</p>
    </div>
  );
}

function MiniRow({ title, value, icon: Icon }: { title: string; value: string; icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }> }) {
  return (
    <div className="rounded-2xl border border-white/35 bg-white/35 p-4">
      <div className="flex items-start gap-3">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-[#9b7430]" aria-hidden />
        <div className="min-w-0">
          <p className="text-xs font-bold text-slate-500">{title}</p>
          <p className="mt-1 break-words text-sm font-black text-slate-900">{value}</p>
        </div>
      </div>
    </div>
  );
}

function FeatureCard({ icon: Icon, title, body, action }: { icon: ComponentType<{ className?: string; "aria-hidden"?: boolean }>; title: string; body: string; action: string }) {
  return (
    <div className={`${glassPanelNested} p-5`}>
      <Icon className="h-7 w-7 text-[#9b7430]" aria-hidden />
      <h3 className="mt-4 text-lg font-black text-slate-950">{title}</h3>
      <p className="mt-2 min-h-16 text-sm leading-6 text-slate-600">{body}</p>
      <button type="button" className={`mt-4 w-full px-4 py-3 text-sm font-bold ${btnSecondaryGlass}`}>
        {action}
      </button>
    </div>
  );
}

function ToggleLine({ title, body, checked, onChange }: { title: string; body: string; checked: boolean; onChange: (value: boolean) => void }) {
  return (
    <div className={`${glassPanelNested} flex items-center justify-between gap-4 p-4`}>
      <div>
        <p className="text-sm font-black text-slate-900">{title}</p>
        <p className="mt-1 text-xs leading-5 text-slate-600">{body}</p>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative h-8 w-14 shrink-0 rounded-full transition ${checked ? "bg-[#C5A059]" : "bg-slate-300"}`}
      >
        <span className={`absolute top-1 h-6 w-6 rounded-full bg-white shadow transition ${checked ? "end-1" : "start-1"}`} />
      </button>
    </div>
  );
}
