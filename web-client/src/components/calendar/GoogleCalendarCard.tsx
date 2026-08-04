"use client";

import { useCallback, useEffect, useState } from "react";
import {
  disconnectGoogle,
  getGoogleAuthUrl,
  getGoogleStatus,
  type GoogleCalendarStatus,
} from "@/api/calendarApi";
import { Button } from "@/components/ui/primitives/Button";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";

export function GoogleCalendarCard() {
  const { t } = useTranslation();
  const [status, setStatus] = useState<GoogleCalendarStatus | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      setStatus(await getGoogleStatus());
      setError(null);
    } catch (e) {
      setStatus({ enabled: false, connected: false });
      setError(e instanceof Error ? e.message : t("calendar.syncFailed"));
    }
  }, [t]);

  useEffect(() => {
    queueMicrotask(() => {
      void refresh();
    });
  }, [refresh]);

  const connect = async () => {
    setBusy(true);
    setError(null);
    try {
      const { url } = await getGoogleAuthUrl();
      window.location.assign(url);
    } catch (e) {
      setError(e instanceof Error ? e.message : t("calendar.syncFailed"));
      setBusy(false);
    }
  };

  const disconnect = async () => {
    setBusy(true);
    try {
      await disconnectGoogle();
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : t("calendar.syncFailed"));
    } finally {
      setBusy(false);
    }
  };

  const connected = status?.connected === true;

  return (
    <div className={`${glassPanelNested} p-4`}>
      <p className="text-xs font-bold uppercase tracking-wide text-veto-gold">
        Google Calendar
      </p>
      <p className="mt-1 text-sm text-secondary">
        {connected
          ? t("calendar.gcalConnected")
          : status?.enabled === false
            ? t("calendar.gcalDisabled")
            : t("calendar.gcalDisconnected")}
      </p>
      {connected && status?.lastSyncAt ? (
        <p className="mt-1 text-xs text-muted">
          {t("calendar.gcalLastSync")}:{" "}
          {new Date(status.lastSyncAt).toLocaleString()}
        </p>
      ) : null}
      {error ? <p className="mt-2 text-xs text-red-300">{error}</p> : null}
      <div className="mt-3">
        {connected ? (
          <Button variant="secondary" size="sm" loading={busy} onClick={() => void disconnect()}>
            {t("calendar.gcalDisconnect")}
          </Button>
        ) : (
          <Button variant="primary" size="sm" loading={busy} onClick={() => void connect()}>
            {busy ? t("calendar.openingGoogle") : t("calendar.syncGoogle")}
          </Button>
        )}
      </div>
    </div>
  );
}
