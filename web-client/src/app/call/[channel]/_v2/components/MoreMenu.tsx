"use client";

import type { ReactNode } from "react";
import {
  Circle,
  Disc3,
  Languages,
  MonitorUp,
  Save,
  ScanFace,
  Subtitles,
  Waves,
} from "lucide-react";
import { useTrWithFallback } from "../lib/trWithFallback";

type Mode = "video" | "audio" | "chat";

export type MoreMenuProps = {
  open: boolean;
  onClose: () => void;
  mode: Mode;
  denoiserOn: boolean;
  bgBlurOn: boolean;
  isSharing: boolean;
  recording: "idle" | "starting" | "recording" | "stopping" | "stopped" | "error";
  captionsOn: boolean;
  translateOn: boolean;
  /** Citizen has approved recording (required to use the record control). */
  citizenConsented: boolean;
  /** Citizen can start/stop; lawyer never sees a record control here — their
   * status already shows in ConsentBanner's top overlay. */
  myRole: "user" | "lawyer";
  onToggleDenoiser: () => void;
  onToggleBgBlur: () => void;
  onToggleScreenShare: () => void;
  onToggleRecording: () => void;
  onToggleCaptions: () => void;
  onToggleTranslate: () => void;
  /** Document picture-in-picture toggle, rendered as-is (video mode only). */
  pipSlot?: ReactNode;
  onSaveToVault?: () => void;
  vaultStatus?: "idle" | "saving" | "saved" | "error";
};

/**
 * Secondary tray for less-frequent call controls — opens from the "more"
 * button in ControlBar's primary row. Keeps the always-visible row down to
 * 5-6 icons; everything here is one extra tap away instead of permanently
 * cluttering the screen.
 */
export function MoreMenu(p: MoreMenuProps) {
  const t = useTrWithFallback();
  if (!p.open) return null;

  const isVideo = p.mode === "video";
  const recBusy = p.recording === "starting" || p.recording === "stopping";
  const recOn = p.recording === "recording";
  const showRecord = p.myRole === "user";

  return (
    <div
      className="pointer-events-none absolute inset-0 z-30"
      role="presentation"
      onClick={p.onClose}
    >
      <div
        role="group"
        aria-label={t("call.v2.controls.moreAria", "More call controls")}
        onClick={(e) => e.stopPropagation()}
        className="pointer-events-auto absolute inset-x-2 bottom-[76px] mx-auto max-w-sm rounded-2xl border border-veto-gold/20 bg-zinc-950/90 p-3 shadow-[0_12px_40px_rgba(0,0,0,0.55)] backdrop-blur-xl @md:px-4"
      >
      <div className="grid grid-cols-4 gap-2">
        {showRecord && (
          <TrayBtn
            active={recOn}
            disabled={!p.citizenConsented || recBusy}
            onClick={p.onToggleRecording}
            icon={<Circle className="h-[19px] w-[19px]" aria-hidden />}
            label={
              recOn
                ? t("call.v2.controls.recordStop", "Stop rec")
                : recBusy
                  ? "…"
                  : t("call.v2.controls.recordStart", "Record")
            }
            activeClass="bg-red-600/20 border-red-500/40 text-red-300"
            title={
              !p.citizenConsented
                ? t(
                    "call.v2.controls.recordBlockedCitizen",
                    "Approve recording in the banner first.",
                  )
                : undefined
            }
          />
        )}
        {isVideo && (
          <TrayBtn
            active={p.bgBlurOn}
            onClick={p.onToggleBgBlur}
            icon={<ScanFace className="h-[19px] w-[19px]" aria-hidden />}
            label={
              p.bgBlurOn
                ? t("call.v2.controls.blurOn", "Blur on")
                : t("call.v2.controls.blurOff", "Blur off")
            }
          />
        )}
        <TrayBtn
          active={p.denoiserOn}
          onClick={p.onToggleDenoiser}
          icon={<Waves className="h-[19px] w-[19px]" aria-hidden />}
          label={
            p.denoiserOn
              ? t("call.v2.controls.denoiserOn", "AI noise: on")
              : t("call.v2.controls.denoiserOff", "AI noise: off")
          }
        />
        {isVideo && (
          <TrayBtn
            active={p.isSharing}
            onClick={p.onToggleScreenShare}
            icon={<MonitorUp className="h-[19px] w-[19px]" aria-hidden />}
            label={
              p.isSharing
                ? t("call.v2.controls.shareStop", "Stop share")
                : t("call.v2.controls.shareStart", "Share screen")
            }
          />
        )}
        <TrayBtn
          active={p.captionsOn}
          onClick={p.onToggleCaptions}
          icon={<Subtitles className="h-[19px] w-[19px]" aria-hidden />}
          label={
            p.captionsOn
              ? t("call.v2.controls.captionsOn", "Captions on")
              : t("call.v2.controls.captionsOff", "Captions off")
          }
        />
        {p.captionsOn && (
          <TrayBtn
            active={p.translateOn}
            onClick={p.onToggleTranslate}
            icon={<Languages className="h-[19px] w-[19px]" aria-hidden />}
            label={
              p.translateOn
                ? t("call.v2.controls.translateOn", "Translate on")
                : t("call.v2.controls.translateOff", "Translate off")
            }
            title={t(
              "call.v2.controls.translateTitle",
              "Translate captions to your language with Gemini",
            )}
          />
        )}
        {p.onSaveToVault && (
          <TrayBtn
            active={p.vaultStatus === "saved"}
            disabled={p.vaultStatus === "saving"}
            onClick={p.onSaveToVault}
            icon={<Save className="h-[19px] w-[19px]" aria-hidden />}
            label={
              p.vaultStatus === "saving"
                ? "…"
                : p.vaultStatus === "saved"
                  ? t("call.v2.controls.vaultSaved", "Saved")
                  : t("call.v2.controls.vaultSave", "Save to vault")
            }
          />
        )}
        {p.pipSlot && (
          <div className="flex flex-col items-center gap-1.5">
            <div className="flex h-[46px] w-[46px] items-center justify-center rounded-2xl bg-white/[0.08] text-inverse">
              <Disc3 className="h-[19px] w-[19px]" aria-hidden />
            </div>
            {p.pipSlot}
          </div>
        )}
      </div>
      </div>
    </div>
  );
}

function TrayBtn({
  active,
  disabled,
  onClick,
  icon,
  label,
  activeClass = "bg-emerald-600/20 border-emerald-500/40 text-emerald-300",
  title,
}: {
  active: boolean;
  disabled?: boolean;
  onClick: () => void;
  icon: ReactNode;
  label: string;
  activeClass?: string;
  title?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-pressed={active}
      aria-label={label}
      title={title ?? label}
      className="flex flex-col items-center gap-1.5 rounded-2xl p-1 outline-none transition focus-visible:ring-2 focus-visible:ring-veto-gold disabled:cursor-not-allowed disabled:opacity-50"
    >
      <span
        className={`flex h-[46px] w-[46px] items-center justify-center rounded-2xl border text-[19px] transition ${
          active
            ? activeClass
            : "border-transparent bg-white/[0.08] text-white hover:bg-white/[0.12]"
        }`}
      >
        {icon}
      </span>
      <span className="max-w-[64px] truncate text-[10px] font-medium text-secondary">
        {label}
      </span>
    </button>
  );
}
