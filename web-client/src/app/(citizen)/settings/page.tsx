"use client";

import { useCallback, useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";
import { createSubscriptionOrder } from "@/api/paymentApi";
import { btnPrimaryGold, btnSecondaryGlass, glassInput, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { GoldSwitch } from "./_components/GoldSwitch";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useSettings } from "./_components/settings-context";

function splitName(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  return {
    first: parts[0] ?? "",
    last: parts.slice(1).join(" "),
  };
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
    refresh,
  } = useSettings();

  const tab = searchParams.get("tab") ?? "profile";
  const okTabs = ["profile", "notifications", "security", "billing"] as const;
  const safeTab = okTabs.includes(tab as (typeof okTabs)[number])
    ? (tab as (typeof okTabs)[number])
    : "profile";

  const [payBusy, setPayBusy] = useState(false);
  const [payErr, setPayErr] = useState<string | null>(null);

  const startSubscribe = useCallback(async () => {
    setPayBusy(true);
    setPayErr(null);
    try {
      const { approveUrl } = await createSubscriptionOrder();
      window.location.href = approveUrl;
    } catch (e) {
      setPayErr(e instanceof Error ? e.message : "PayPal");
    } finally {
      setPayBusy(false);
    }
  }, []);

  const names = useMemo(() => splitName(fullName), [fullName]);

  if (safeTab === "notifications") {
    return (
      <div className="flex flex-col gap-5">
        <section className={`${glassPanel} p-5`}>
          <h2 className="font-frank text-lg font-bold text-slate-900">
            {t("settings.notificationsTitle")}
          </h2>
          <p className="font-heebo mt-1 text-sm text-slate-600">
            {t("settings.notificationsSubtitle")}
          </p>

          <ul className="mt-5 list-none space-y-3 p-0">
            <li className={`${glassPanelNested} p-4`}>
              <div className="flex items-center justify-between gap-4">
                <div className="min-w-0">
                  <p
                    id="settings-label-sms"
                    className="font-heebo text-sm font-semibold text-slate-900"
                  >
                    {t("settings.sms")}
                  </p>
                  <p className="font-heebo text-xs text-slate-600">
                    {t("settings.smsHint")}
                  </p>
                </div>
                <GoldSwitch
                  checked={notifySms}
                  onChange={setNotifySms}
                  aria-labelledby="settings-label-sms"
                />
              </div>
            </li>
            <li className={`${glassPanelNested} p-4`}>
              <div className="flex items-center justify-between gap-4">
                <div className="min-w-0">
                  <p
                    id="settings-label-push"
                    className="font-heebo text-sm font-semibold text-slate-900"
                  >
                    {t("settings.push")}
                  </p>
                  <p className="font-heebo text-xs text-slate-600">
                    {t("settings.pushHint")}
                  </p>
                </div>
                <GoldSwitch
                  checked={notifyPush}
                  onChange={setNotifyPush}
                  aria-labelledby="settings-label-push"
                />
              </div>
            </li>
          </ul>
        </section>
      </div>
    );
  }

  if (safeTab === "billing") {
    const exempt = profile?.is_payment_exempt === true;
    const sub = profile?.is_subscribed === true;
    const exp =
      profile?.subscription_expiry &&
      !Number.isNaN(Date.parse(String(profile.subscription_expiry)))
        ? new Date(String(profile.subscription_expiry)).toLocaleDateString()
        : "—";

    return (
      <div className="flex flex-col gap-5">
        <section className={`${glassPanel} p-5`}>
          <h2 className="font-frank text-lg font-bold text-slate-900">
            {t("settings.billingTitle")}
          </h2>
          <p className="font-heebo mt-1 text-sm text-slate-600">
            {t("settings.billingSubtitle")}
          </p>

          {payErr && (
            <p className="mt-4 rounded-xl border border-red-300/80 bg-red-50/90 px-3 py-2 text-sm text-red-900">
              {payErr}
            </p>
          )}

          <div className={`${glassPanelNested} mt-5 space-y-2 p-4 text-sm text-slate-800`}>
            <p>
              <span className="font-semibold">{t("settings.billingPlan")}:</span>{" "}
              {exempt
                ? t("settings.billingExempt")
                : sub
                  ? t("settings.billingSubscribed")
                  : t("settings.billingNotSubscribed")}
            </p>
            <p>
              <span className="font-semibold">{t("settings.billingExpiry")}:</span>{" "}
              {exempt ? "—" : exp}
            </p>
          </div>

          <p className="font-heebo mt-3 text-xs text-slate-600">
            {t("settings.billingConsultHint")}
          </p>

          <div className="mt-5 flex flex-wrap gap-2">
            <button
              type="button"
              disabled={payBusy || exempt || sub}
              onClick={() => void startSubscribe()}
              className={`px-4 py-2.5 text-sm font-semibold ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50`}
            >
              {payBusy ? "…" : t("settings.billingSubscribeCta")}
            </button>
            <button
              type="button"
              onClick={() => void refresh()}
              className={`px-4 py-2.5 text-sm ${btnSecondaryGlass}`}
            >
              {t("settings.billingRefresh")}
            </button>
          </div>
        </section>
      </div>
    );
  }

  if (safeTab === "security") {
    return (
      <div className="flex flex-col gap-5">
        <section className={`${glassPanel} p-5`}>
          <h2 className="font-frank text-lg font-bold text-slate-900">
            {t("settings.securityTitle")}
          </h2>
          <p className="font-heebo mt-1 text-sm text-slate-600">
            {t("settings.securitySubtitle")}
          </p>

          <div className="mt-5 grid gap-3">
            <div className={`${glassPanelNested} p-4 text-sm text-slate-700`}>
              <p className="font-heebo font-semibold text-slate-900">
                {t("settings.vaultPermissions")}
              </p>
            </div>
            <div className={`${glassPanelNested} p-4 text-sm text-slate-700`}>
              <p className="font-heebo font-semibold text-slate-900">
                {t("settings.callPermissions")}
              </p>
            </div>
          </div>

          <div className="mt-4">
            <p className="font-heebo mb-2 text-xs font-semibold text-slate-700">
              {t("settings.sessionsTitle")}
            </p>
            <div className="flex flex-wrap gap-2">
              <span className="rounded-full border border-white/45 bg-white/35 px-3 py-1 text-xs text-slate-800">
                {t("settings.sessionVideo")}
              </span>
              <span className="rounded-full border border-white/45 bg-white/35 px-3 py-1 text-xs text-slate-800">
                {t("settings.sessionAudio")}
              </span>
              <span className="rounded-full border border-white/45 bg-white/35 px-3 py-1 text-xs text-slate-800">
                {t("settings.sessionChat")}
              </span>
            </div>
          </div>

          <button
            type="button"
            className="font-heebo mt-5 rounded-xl border border-white/45 bg-white/35 px-4 py-2 text-sm font-semibold text-slate-900 backdrop-blur-sm"
          >
            {t("settings.changePassword")}
          </button>
        </section>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <section className={`${glassPanel} p-5`}>
        <h2 className="font-frank text-lg font-bold text-slate-900">
          {t("settings.profileTitle")}
        </h2>
        <p className="font-heebo mt-1 text-sm text-slate-600">
          {t("settings.profileSubtitle")}
        </p>

        <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <label
              htmlFor="settings-first-name"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              {t("settings.firstName")}
            </label>
            <input
              id="settings-first-name"
              value={names.first}
              onChange={(e) => {
                const nextFirst = e.target.value;
                const nextFull = [nextFirst, names.last].filter(Boolean).join(" ").trim();
                setFullName(nextFull);
              }}
              className={glassInput}
              autoComplete="given-name"
            />
          </div>
          <div>
            <label
              htmlFor="settings-last-name"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              {t("settings.lastName")}
            </label>
            <input
              id="settings-last-name"
              value={names.last}
              onChange={(e) => {
                const nextLast = e.target.value;
                const nextFull = [names.first, nextLast].filter(Boolean).join(" ").trim();
                setFullName(nextFull);
              }}
              className={glassInput}
              autoComplete="family-name"
            />
          </div>
          <div>
            <label
              htmlFor="settings-email"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              {t("settings.email")}
            </label>
            <input
              id="settings-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={glassInput}
              autoComplete="email"
            />
          </div>
          <div>
            <label
              htmlFor="settings-phone"
              className="font-heebo mb-1 block text-xs font-semibold text-slate-700"
            >
              {t("settings.phone")}
            </label>
            <input
              id="settings-phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className={glassInput}
              autoComplete="tel"
            />
          </div>
        </div>
      </section>
    </div>
  );
}
