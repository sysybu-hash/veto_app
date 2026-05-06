"use client";

import { glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { GoldSwitch } from "../_components/GoldSwitch";
import { useSettings } from "../_components/settings-context";

export default function SettingsNotificationsPage() {
  const { notifySms, setNotifySms, notifyPush, setNotifyPush } = useSettings();

  return (
    <div className="flex flex-col gap-5">
      <section className={`${glassPanel} p-5`}>
        <h2 className="font-frank text-lg font-bold text-slate-900">
          Notifications
        </h2>
        <p className="font-heebo mt-1 text-sm text-slate-600">
          Choose how VETO reaches you about your case and account.
        </p>

        <ul className="mt-5 list-none space-y-3 p-0">
          <li className={`${glassPanelNested} p-4`}>
            <div className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <p
                  id="label-sms"
                  className="font-heebo text-sm font-semibold text-slate-900"
                >
                  SMS
                </p>
                <p className="font-heebo text-xs text-slate-600">
                  Text messages for important updates
                </p>
              </div>
              <GoldSwitch
                checked={notifySms}
                onChange={setNotifySms}
                aria-labelledby="label-sms"
              />
            </div>
          </li>
          <li className={`${glassPanelNested} p-4`}>
            <div className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <p
                  id="label-push"
                  className="font-heebo text-sm font-semibold text-slate-900"
                >
                  Push notifications
                </p>
                <p className="font-heebo text-xs text-slate-600">
                  In-app and device alerts
                </p>
              </div>
              <GoldSwitch
                checked={notifyPush}
                onChange={setNotifyPush}
                aria-labelledby="label-push"
              />
            </div>
          </li>
        </ul>
      </section>
    </div>
  );
}
