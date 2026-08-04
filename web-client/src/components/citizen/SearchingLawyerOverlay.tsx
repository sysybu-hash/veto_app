"use client";

import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/primitives/Button";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

type Props = {
  phase: "searching" | "connecting";
  lawyerName?: string | null;
  onCancel?: () => void;
};

/**
 * Full-screen status while the citizen waits for a lawyer after SOS.
 * Must be unmistakable — a one-line hint under the SOS button was easy to miss.
 */
export function SearchingLawyerOverlay({ phase, lawyerName, onCancel }: Props) {
  const { t } = useTranslation();
  const isConnecting = phase === "connecting";

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-surface-scrim/90 p-4 backdrop-blur-md"
      role="status"
      aria-live="polite"
      aria-busy="true"
    >
      <div className="w-full max-w-md rounded-2xl border border-veto-gold/40 bg-surface-raised px-6 py-8 text-center shadow-2xl">
        <div className="relative mx-auto flex h-20 w-20 items-center justify-center">
          <span
            className="absolute inset-0 animate-ping rounded-full bg-veto-gold/25"
            aria-hidden
          />
          <span
            className="absolute inset-2 animate-pulse rounded-full border-2 border-veto-gold/50"
            aria-hidden
          />
          <Loader2
            className="relative h-9 w-9 animate-spin text-veto-gold"
            aria-hidden
          />
        </div>

        <h2 className="mt-6 font-frank text-2xl font-black text-primary">
          {isConnecting
            ? t("hub.connectingTitle")
            : t("hub.searchingTitle")}
        </h2>
        <p className="mt-3 text-sm leading-6 text-secondary">
          {isConnecting
            ? t("hub.connectingSubtitle")
            : lawyerName
              ? t("hub.lawyerAccepted").replace("{name}", lawyerName)
              : t("hub.searchingSubtitle")}
        </p>

        {!isConnecting ? (
          <ol className="mt-6 space-y-3 text-start text-sm text-secondary">
            <li className="flex items-start gap-3">
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-veto-gold/20 text-xs font-black text-veto-gold">
                1
              </span>
              <span>{t("hub.searchingStep1")}</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-veto-gold/20 text-xs font-black text-veto-gold">
                2
              </span>
              <span>{t("hub.searchingStep2")}</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-veto-gold/20 text-xs font-black text-veto-gold">
                3
              </span>
              <span>{t("hub.searchingStep3")}</span>
            </li>
          </ol>
        ) : null}

        <p className="mt-5 text-xs text-muted">{t("hub.searchingHint")}</p>

        {!isConnecting && onCancel ? (
          <div className="mt-6">
            <Button variant="secondary" size="md" onClick={onCancel}>
              {t("hub.cancelSearch")}
            </Button>
          </div>
        ) : null}
      </div>
    </div>
  );
}
