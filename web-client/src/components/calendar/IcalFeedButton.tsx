"use client";

import { useState } from "react";
import { getFeedInfo } from "@/api/calendarApi";
import { Button } from "@/components/ui/primitives/Button";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { glassPanelNested } from "@/lib/vetoGlass";

export function IcalFeedButton() {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const copy = async () => {
    setBusy(true);
    setError(null);
    try {
      const feed = await getFeedInfo();
      await navigator.clipboard.writeText(feed.webcalUrl);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2500);
    } catch (e) {
      setError(e instanceof Error ? e.message : t("calendar.icalFailed"));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className={`${glassPanelNested} p-4`}>
      <p className="text-xs font-bold uppercase tracking-wide text-brand-text">
        iCal
      </p>
      <p className="mt-1 text-sm text-secondary">{t("calendar.icalHint")}</p>
      {error ? <p className="mt-2 text-xs text-red-300">{error}</p> : null}
      <Button
        variant="secondary"
        size="sm"
        className="mt-3"
        loading={busy}
        onClick={() => void copy()}
      >
        {copied ? t("calendar.icalCopied") : t("calendar.icalCopy")}
      </Button>
    </div>
  );
}
