"use client";

import { motion } from "framer-motion";
import { ScanLine } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { saveAiAnalysisAsFile } from "@/app/actions/ai-to-vault";
import { analyzeLegalDocument } from "@/app/actions/ai-vision";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useToastStore } from "@/store/useToastStore";
import { Button } from "@/components/ui/primitives/Button";

type Props = {
  /** When false, camera stream is stopped. */
  active: boolean;
  /** Optional: parent stores analysis in its own message list (e.g. bubble). */
  onAnalysis?: (analysis: string) => void;
  onSignInRequired?: () => void;
  className?: string;
};

export function AiDocumentDecodePanel({
  active,
  onAnalysis,
  onSignInRequired,
  className = "",
}: Props) {
  const { t } = useTranslation();
  const pushToast = useToastStore((s) => s.push);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [visionError, setVisionError] = useState<string | null>(null);
  const [visionBusy, setVisionBusy] = useState(false);
  const [vaultSaveBusy, setVaultSaveBusy] = useState(false);
  const [lastVisionAnalysis, setLastVisionAnalysis] = useState<string | null>(
    null,
  );

  useEffect(() => {
    if (!active) {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
      }
      if (videoRef.current) {
        videoRef.current.srcObject = null;
      }
      return;
    }

    let cancelled = false;
    let attachedVideo: HTMLVideoElement | null = null;

    (async () => {
      try {
        setVisionError(null);
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: { ideal: "environment" } },
          audio: false,
        });
        if (cancelled) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }
        streamRef.current = stream;
        const el = videoRef.current;
        if (el) {
          attachedVideo = el;
          el.srcObject = stream;
          await el.play().catch(() => {});
        }
      } catch (e) {
        if (!cancelled) {
          setVisionError(
            e instanceof Error ? e.message : t("ai.cameraStartFail"),
          );
        }
      }
    })();

    return () => {
      cancelled = true;
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
      }
      if (attachedVideo) {
        attachedVideo.srcObject = null;
      }
    };
  }, [active, t]);

  const captureAndAnalyze = useCallback(async () => {
    if (!getJwt()) {
      onSignInRequired?.();
      return;
    }
    const video = videoRef.current;
    if (!video || video.videoWidth === 0 || visionBusy) return;

    setVisionBusy(true);
    setLastVisionAnalysis(null);
    try {
      const maxW = 1280;
      const scale = Math.min(1, maxW / video.videoWidth);
      const w = Math.floor(video.videoWidth * scale);
      const h = Math.floor(video.videoHeight * scale);
      const canvas = document.createElement("canvas");
      canvas.width = w;
      canvas.height = h;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        pushToast(t("ai.errCannotCaptureFrame"), "error");
        return;
      }
      ctx.drawImage(video, 0, 0, w, h);
      const dataUrl = canvas.toDataURL("image/jpeg", 0.82);

      const result = await analyzeLegalDocument(dataUrl);
      if (result.success) {
        setLastVisionAnalysis(result.analysis);
        onAnalysis?.(result.analysis);
        pushToast(t("ai.toastVisionAnalyzed"), "success");
      } else {
        pushToast(result.error, "error");
      }
    } catch (e) {
      pushToast(
        e instanceof Error ? e.message : t("ai.errImageAnalyze"),
        "error",
      );
    } finally {
      setVisionBusy(false);
    }
  }, [onAnalysis, onSignInRequired, pushToast, t, visionBusy]);

  const saveVisionToVault = useCallback(async () => {
    if (!lastVisionAnalysis?.trim() || vaultSaveBusy) return;
    if (!getJwt()) {
      onSignInRequired?.();
      return;
    }
    setVaultSaveBusy(true);
    try {
      const res = await saveAiAnalysisAsFile(lastVisionAnalysis);
      if (res.success) {
        pushToast(t("ai.toastAnalysisSaved"), "success");
        setLastVisionAnalysis(null);
      } else {
        pushToast(res.error, "error");
      }
    } catch (e) {
      pushToast(
        e instanceof Error ? e.message : t("ai.errVaultSave"),
        "error",
      );
    } finally {
      setVaultSaveBusy(false);
    }
  }, [lastVisionAnalysis, onSignInRequired, pushToast, t, vaultSaveBusy]);

  return (
    <div
      className={`flex min-h-0 flex-col gap-3 overflow-y-auto p-3 ${className}`}
    >
      <div
        className="relative w-full overflow-hidden rounded-3xl border-2 border-veto-gold/50 bg-black/80 shadow-[0_0_24px_rgba(197,160,89,0.2)]"
        style={{ aspectRatio: "16 / 9" }}
      >
        <video
          ref={videoRef}
          className="h-full w-full object-cover"
          autoPlay
          playsInline
          muted
        />

        {visionError && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/70 p-4 text-center text-sm text-inverse">
            {visionError}
          </div>
        )}

        {!visionError && (
          <>
            <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
              <span className="text-[10px] font-bold tracking-widest text-white/25 sm:text-xs">
                {t("ai.cameraFeed")}
              </span>
            </div>

            <motion.div
              aria-hidden
              animate={{ top: ["0%", "100%", "0%"] }}
              transition={{
                repeat: Infinity,
                duration: 3,
                ease: "linear",
              }}
              className="pointer-events-none absolute inset-x-0 z-10 h-px bg-linear-to-r from-transparent via-veto-gold to-transparent shadow-[0_0_15px_rgba(197,160,89,0.9)]"
            />

            <div className="absolute bottom-3 end-3 flex items-center gap-2">
              <span className="h-2.5 w-2.5 shrink-0 animate-pulse rounded-full bg-red-500/100" />
              <span className="text-[10px] font-black tracking-widest text-inverse">
                {t("ai.visionAnalyzing")}
              </span>
            </div>
          </>
        )}
      </div>

      <p className="rounded-xl border border-subtle bg-surface-sunken px-3 py-2 text-center text-xs font-bold text-secondary backdrop-blur-md">
        {t("ai.visionHint")}
      </p>
      <Button
        variant="primary"
        size="lg"
        fullWidth
        disabled={!!visionError || visionBusy || !getJwt()}
        loading={visionBusy}
        onClick={() => void captureAndAnalyze()}
        iconStart={<ScanLine className="h-5 w-5 shrink-0" aria-hidden />}
      >
        {visionBusy ? t("ai.analyzingFrame") : t("ai.captureAnalyze")}
      </Button>
      {lastVisionAnalysis?.trim() ? (
        <>
          <div className="max-h-40 overflow-y-auto rounded-xl border border-subtle bg-surface-raised-2 px-3 py-2 text-xs leading-5 text-primary whitespace-pre-wrap">
            {lastVisionAnalysis}
          </div>
          <Button
            variant="secondary"
            size="lg"
            fullWidth
            disabled={vaultSaveBusy}
            loading={vaultSaveBusy}
            onClick={() => void saveVisionToVault()}
          >
            {vaultSaveBusy ? t("ai.savingVault") : t("ai.saveVault")}
          </Button>
        </>
      ) : null}
    </div>
  );
}
