"use client";

import Link from "next/link";
import { useCallback, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Bell,
  Camera,
  CheckCircle2,
  CreditCard,
  Headphones,
  KeyRound,
  LockKeyhole,
  MessageCircle,
  RefreshCw,
  ShieldCheck,
  UserRound,
  Video,
  type LucideIcon,
} from "lucide-react";
import {
  createConsultationOrder,
  createSubscriptionOrder,
} from "@/api/paymentApi";
import { registerPasskey, passkeysSupported } from "@/api/passkeyApi";
import {
  btnSecondaryGlass,
  glassInput,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";
import { GoldSwitch } from "./_components/GoldSwitch";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useSettings } from "./_components/settings-context";
import { Button } from "@/components/ui/primitives/Button";

type SettingsTab = "profile" | "notifications" | "security" | "billing";
type SessionPreference = "video" | "audio" | "chat";

function splitName(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  return { first: parts[0] ?? "", last: parts.slice(1).join(" ") };
}

function formatDate(raw?: string | null): string {
  if (!raw) return "לא מוגדר";
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return "לא מוגדר";
  return new Intl.DateTimeFormat("he-IL", { dateStyle: "medium" }).format(d);
}

export default function SettingsIndexPage() {
  const searchParams = useSearchParams();
  const { t } = useTranslation();
  const {
    fullName,
    setFullName,
    email,
    setEmail,
    phone,
    setPhone,
    notifySms,
    setNotifySms,
    notifyPush,
    setNotifyPush,
    profile,
    loading,
    saving,
    message,
    error,
    save,
    refresh,
  } = useSettings();

  const tab = searchParams.get("tab") ?? "profile";
  const okTabs: SettingsTab[] = ["profile", "notifications", "security", "billing"];
  const safeTab = okTabs.includes(tab as SettingsTab) ? (tab as SettingsTab) : "profile";

  const [payBusy, setPayBusy] = useState(false);
  const [payErr, setPayErr] = useState<string | null>(null);
  const [securityNote, setSecurityNote] = useState<string | null>(null);
  const [passkeyBusy, setPasskeyBusy] = useState(false);
  const [vaultAccess, setVaultAccess] = useState(true);
  const [callRecording, setCallRecording] = useState(false);
  const [cameraAllowed, setCameraAllowed] = useState(true);
  const [micAllowed, setMicAllowed] = useState(true);
  const [sessionPreference, setSessionPreference] = useState<SessionPreference>("video");

  const names = useMemo(() => splitName(fullName), [fullName]);

  const startSubscribe = useCallback(async () => {
    setPayBusy(true);
    setPayErr(null);
    try {
      const { approveUrl } = await createSubscriptionOrder();
      window.location.href = approveUrl;
    } catch (e) {
      setPayErr(e instanceof Error ? e.message : "לא ניתן לפתוח תשלום כרגע");
    } finally {
      setPayBusy(false);
    }
  }, []);

  const startConsultation = useCallback(async () => {
    setPayBusy(true);
    setPayErr(null);
    try {
      const { approveUrl, exempt } = await createConsultationOrder();
      if (exempt) {
        await refresh();
        setPayErr(null);
        return;
      }
      window.location.href = approveUrl;
    } catch (e) {
      setPayErr(e instanceof Error ? e.message : "לא ניתן לפתוח תשלום ייעוץ כרגע");
    } finally {
      setPayBusy(false);
    }
  }, [refresh]);

  const saveSecurity = useCallback(() => {
    setSecurityNote("הגדרות האבטחה עודכנו במכשיר. הרשאות הדפדפן עצמן מנוהלות דרך Chrome.");
  }, []);

  const enablePasskey = useCallback(async () => {
    setPasskeyBusy(true);
    try {
      await registerPasskey("VETO Passkey");
      setSecurityNote("Passkey הופעל בהצלחה. בפעם הבאה ניתן להיכנס עם ביומטריה או PIN מכשיר.");
    } catch (e) {
      setSecurityNote(e instanceof Error ? e.message : "לא ניתן להפעיל Passkey כרגע.");
    } finally {
      setPasskeyBusy(false);
    }
  }, []);

  return (
    <section className={`${glassPanel} p-5`}>
      <StatusStrip loading={loading} saving={saving} message={message} error={error} />

      {safeTab === "profile" && (
        <>
          <SectionHeader icon={UserRound} title={t("settings.profileTitle")} subtitle={t("settings.profileSubtitle")} />
          <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
            <Field id="settings-first-name" label={t("settings.firstName")} value={names.first} onChange={(v) => setFullName([v, names.last].filter(Boolean).join(" ").trim())} autoComplete="given-name" />
            <Field id="settings-last-name" label={t("settings.lastName")} value={names.last} onChange={(v) => setFullName([names.first, v].filter(Boolean).join(" ").trim())} autoComplete="family-name" />
            <Field id="settings-email" label={t("settings.email")} value={email} onChange={setEmail} autoComplete="email" type="email" />
            <Field id="settings-phone" label={t("settings.phone")} value={phone} onChange={setPhone} autoComplete="tel" type="tel" />
          </div>
          <ActionRow onSave={save} onRefresh={refresh} saving={saving} />
        </>
      )}

      {safeTab === "notifications" && (
        <>
          <SectionHeader icon={Bell} title={t("settings.notificationsTitle")} subtitle={t("settings.notificationsSubtitle")} />
          <div className="mt-5 grid gap-3">
            <ToggleCard id="sms" label={t("settings.sms")} hint={t("settings.smsHint")} checked={notifySms} onChange={setNotifySms} />
            <ToggleCard id="push" label={t("settings.push")} hint={t("settings.pushHint")} checked={notifyPush} onChange={setNotifyPush} />
          </div>
          <ActionRow onSave={save} onRefresh={refresh} saving={saving} />
        </>
      )}

      {safeTab === "billing" && (
        <BillingPanel
          profile={profile}
          payBusy={payBusy}
          payErr={payErr}
          onSubscribe={startSubscribe}
          onConsult={startConsultation}
          onRefresh={refresh}
        />
      )}

      {safeTab === "security" && (
        <>
          <SectionHeader icon={ShieldCheck} title={t("settings.securityTitle")} subtitle={t("settings.securitySubtitle")} />
          {securityNote && (
            <p className="mt-4 rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm font-semibold text-emerald-200">
              {securityNote}
            </p>
          )}

          <div className="mt-5 grid gap-3">
            <div className={`${glassPanelNested} p-4`}>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex items-start gap-3">
                  <KeyRound className="mt-0.5 h-5 w-5 text-veto-gold-dark" aria-hidden />
                  <div>
                    <p className="text-sm font-black text-primary">כניסה עם Passkey</p>
                    <p className="mt-1 text-xs leading-5 text-muted">
                      הוספת כניסה ביומטרית או PIN מכשיר לצד OTP, בלי לבטל את דרך הכניסה הקיימת.
                    </p>
                  </div>
                </div>
                <Button
                  variant="primary"
                  onClick={() => void enablePasskey()}
                  disabled={passkeyBusy || !passkeysSupported()}
                  loading={passkeyBusy}
                >
                  {passkeyBusy ? "מפעיל..." : "הפעל Passkey"}
                </Button>
              </div>
            </div>
            <ToggleCard
              id="vault-access"
              icon={LockKeyhole}
              label={t("settings.vaultPermissions")}
              hint="אפשרות לצרף מסמכים וראיות מהכספת לשיחה עם עורך דין."
              checked={vaultAccess}
              onChange={setVaultAccess}
            />
            <ToggleCard
              id="call-recording"
              icon={MessageCircle}
              label="שמירת תקציר שיחה"
              hint="שמירת סיכום טקסטואלי בכספת לאחר שיחת חירום."
              checked={callRecording}
              onChange={setCallRecording}
            />
            <ToggleCard
              id="microphone"
              icon={Headphones}
              label="הרשאת מיקרופון"
              hint="נדרש לשיחות קוליות ושיחות וידאו."
              checked={micAllowed}
              onChange={setMicAllowed}
            />
            <ToggleCard
              id="camera"
              icon={Camera}
              label="הרשאת מצלמה"
              hint="נדרש רק כאשר בוחרים שיחת וידאו."
              checked={cameraAllowed}
              onChange={setCameraAllowed}
            />
          </div>

          <div className={`${glassPanelNested} mt-4 p-4`}>
            <div className="flex items-start gap-3">
              <Video className="mt-0.5 h-5 w-5 text-veto-gold-dark" aria-hidden />
              <div>
                <p className="text-sm font-black text-primary">{t("settings.sessionsTitle")}</p>
                <p className="mt-1 text-xs leading-5 text-muted">בחרו את סוג השיחה המועדף לפתיחת SOS.</p>
              </div>
            </div>
            <div className="mt-4 grid grid-cols-3 gap-2">
              {[
                ["video", t("settings.sessionVideo")],
                ["audio", t("settings.sessionAudio")],
                ["chat", t("settings.sessionChat")],
              ].map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setSessionPreference(value as SessionPreference)}
                  className={`rounded-xl px-3 py-3 text-sm font-black transition ${
                    sessionPreference === value
                      ? "bg-surface-inverse text-inverse shadow-lg" : "border border-subtle bg-white/[0.03] text-secondary hover:bg-white/[0.05]"}`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div className="mt-5 grid gap-2 sm:grid-cols-3">
            <Link href="/vault" className={`px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>
              כספת
            </Link>
            <Link href="/chat" className={`px-4 py-3 text-center text-sm font-bold ${btnSecondaryGlass}`}>
              צ׳אט
            </Link>
            <Button variant="primary" onClick={saveSecurity}>
              שמור אבטחה
            </Button>
          </div>
          <Button
            variant="secondary"
            fullWidth
            className="mt-3"
            iconStart={<KeyRound className="h-4 w-4" aria-hidden />}
            onClick={() => setSecurityNote("נשלחה בקשה לאיפוס סיסמה למייל המחובר, אם השרת תומך בכך.")}
          >
            {t("settings.changePassword")}
          </Button>
        </>
      )}
    </section>
  );
}

function BillingPanel({
  profile,
  payBusy,
  payErr,
  onSubscribe,
  onConsult,
  onRefresh,
}: {
  profile: ReturnType<typeof useSettings>["profile"];
  payBusy: boolean;
  payErr: string | null;
  onSubscribe: () => void;
  onConsult: () => void;
  onRefresh: () => Promise<void>;
}) {
  const { t } = useTranslation();
  const exempt = profile?.is_payment_exempt === true;
  const subscribed = profile?.is_subscribed === true;
  const active = exempt || subscribed;
  const status = exempt
    ? t("settings.billingExempt")
    : subscribed
      ? t("settings.billingSubscribed")
      : t("settings.billingNotSubscribed");

  return (
    <>
      <SectionHeader icon={CreditCard} title={t("settings.billingTitle")} subtitle={t("settings.billingSubtitle")} />
      {payErr && <p className="mt-4 rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">{payErr}</p>}
      <div className="mt-5 grid gap-3 sm:grid-cols-2">
        <div className={`${glassPanelNested} p-4`}>
          <p className="text-xs font-bold text-muted">{t("settings.billingPlan")}</p>
          <p className="mt-1 text-lg font-black text-primary">{status}</p>
        </div>
        <div className={`${glassPanelNested} p-4`}>
          <p className="text-xs font-bold text-muted">{t("settings.billingExpiry")}</p>
          <p className="mt-1 text-lg font-black text-primary">{exempt ? "פטור מתשלום" : formatDate(profile?.subscription_expiry)}</p>
        </div>
      </div>
      <div className={`${glassPanelNested} mt-4 p-4 text-sm leading-6 text-secondary`}>
        {t("settings.billingConsultHint")}
      </div>
      <div className="mt-5 grid gap-2 sm:grid-cols-2">
        <Button variant="primary" disabled={payBusy || active} loading={payBusy} onClick={onSubscribe}>
          {payBusy ? "פותח תשלום..." : t("settings.billingSubscribeCta")}
        </Button>
        <Button variant="secondary" disabled={payBusy} onClick={onConsult}>
          {t("settings.billingConsultCta")}
        </Button>
        <Button
          variant="secondary"
          iconStart={<RefreshCw className="h-4 w-4" aria-hidden />}
          onClick={() => void onRefresh()}
        >
          {t("settings.billingRefresh")}
        </Button>
        <Link
          href="/plans"
          className={`inline-flex items-center justify-center px-4 py-2.5 text-sm font-bold ${btnSecondaryGlass}`}
        >
          {t("settings.billingPlansLink")}
        </Link>
      </div>
    </>
  );
}

function SectionHeader({ icon: Icon, title, subtitle }: { icon: LucideIcon; title: string; subtitle: string }) {
  return (
    <div className="flex items-start gap-3">
      <Icon className="mt-1 h-5 w-5 text-veto-gold-dark" aria-hidden />
      <div>
        <h2 className="font-frank text-xl font-black text-primary">{title}</h2>
        <p className="mt-1 text-sm text-muted">{subtitle}</p>
      </div>
    </div>
  );
}

function StatusStrip({ loading, saving, message, error }: { loading: boolean; saving: boolean; message: string | null; error: string | null }) {
  if (!loading && !saving && !message && !error) return null;
  return (
    <div className="mb-4 rounded-2xl border border-subtle bg-white/[0.03] px-4 py-3 text-sm font-semibold text-secondary">
      {loading && "טוען הגדרות..."}
      {saving && "שומר..."}
      {!loading && !saving && message && <span className="text-emerald-200">{message}</span>}
      {!loading && !saving && error && <span className="text-red-200">{error}</span>}
    </div>
  );
}

function ToggleCard({
  id,
  label,
  hint,
  checked,
  onChange,
  icon: Icon = CheckCircle2,
}: {
  id: string;
  label: string;
  hint: string;
  checked: boolean;
  onChange: (value: boolean) => void;
  icon?: LucideIcon;
}) {
  return (
    <div className={`${glassPanelNested} flex items-center justify-between gap-4 p-4`}>
      <div className="flex min-w-0 items-start gap-3">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-veto-gold-dark" aria-hidden />
        <div className="min-w-0">
          <p id={`settings-label-${id}`} className="text-sm font-bold text-primary">{label}</p>
          <p className="mt-1 text-xs leading-5 text-muted">{hint}</p>
        </div>
      </div>
      <GoldSwitch checked={checked} onChange={onChange} aria-labelledby={`settings-label-${id}`} />
    </div>
  );
}

function ActionRow({ onSave, onRefresh, saving }: { onSave: () => Promise<void>; onRefresh: () => Promise<void>; saving: boolean }) {
  return (
    <div className="mt-5 grid gap-2 sm:grid-cols-2">
      <Button variant="primary" disabled={saving} loading={saving} onClick={() => void onSave()}>
        {saving ? "שומר..." : "שמור שינויים"}
      </Button>
      <Button variant="secondary" iconStart={<RefreshCw className="h-4 w-4" aria-hidden />} onClick={() => void onRefresh()}>
        רענן נתונים
      </Button>
    </div>
  );
}

function Field({
  id,
  label,
  value,
  onChange,
  type = "text",
  autoComplete,
}: {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  autoComplete?: string;
}) {
  return (
    <div>
      <label htmlFor={id} className="mb-1 block text-xs font-bold text-secondary">{label}</label>
      <input id={id} type={type} value={value} onChange={(e) => onChange(e.target.value)} className={glassInput} autoComplete={autoComplete} />
    </div>
  );
}
