"use client";

import type { ReactNode } from "react";
import { useTrWithFallback } from "../lib/trWithFallback";

type Mode = "video" | "audio" | "chat";

export type ControlBarProps = {
  mode: Mode;
  micOn: boolean;
  cameraOn: boolean;
  denoiserOn: boolean;
  bgBlurOn: boolean;
  isSharing: boolean;
  recording: "idle" | "starting" | "recording" | "stopping" | "stopped" | "error";
  captionsOn: boolean;
  translateOn: boolean;
  chatOpen: boolean;
  /** Citizen has approved recording (required to use the record control). */
  citizenConsented: boolean;
  /** Citizen can start/stop; lawyer only sees recording status. */
  myRole: "user" | "lawyer";
  onToggleMic: () => void;
  onToggleCamera: () => void;
  onToggleDenoiser: () => void;
  onToggleBgBlur: () => void;
  onToggleScreenShare: () => void;
  onToggleRecording: () => void;
  onToggleCaptions: () => void;
  onToggleTranslate: () => void;
  onToggleChat: () => void;
  onEndCall: () => void;
  pipSlot?: ReactNode;
};

/**
 * Control bar — horizontally scrollable on narrow viewports so every action
 * stays reachable without a hidden menu. Container queries hide labels at
 * tight widths but keep large 44px hit targets for touch.
 */
export function ControlBar(p: ControlBarProps) {
  const t = useTrWithFallback();
  const isVideo = p.mode === "video";
  const recBusy = p.recording === "starting" || p.recording === "stopping";
  const recOn = p.recording === "recording";
  const lawyerView = p.myRole === "lawyer";

  return (
    <div className="@container/cb pointer-events-none absolute inset-x-0 bottom-0 z-30 px-3 pb-3">
      <div
        className="pointer-events-auto mx-auto flex max-w-3xl items-center justify-center gap-2 overflow-x-auto rounded-2xl border border-white/10 bg-black/65 px-3 py-2 shadow-2xl backdrop-blur-md
                   @md/cb:gap-3 @md/cb:px-4 @md/cb:py-3"
        role="toolbar"
        aria-label={t("call.v2.controls.aria", "Call controls")}
      >
        <CtrlBtn
          active={!p.micOn}
          onClick={p.onToggleMic}
          activeClass="bg-amber-600 text-white"
          label={p.micOn ? t("call.mute", "Mute") : t("call.unmute", "Unmute")}
          shortcut="M"
        />
        {isVideo && (
          <CtrlBtn
            active={!p.cameraOn}
            onClick={p.onToggleCamera}
            activeClass="bg-amber-600 text-white"
            label={
              p.cameraOn
                ? t("call.cameraOff", "Camera off")
                : t("call.cameraOn", "Camera on")
            }
            shortcut="V"
          />
        )}
        {isVideo && (
          <CtrlBtn
            active={p.bgBlurOn}
            onClick={p.onToggleBgBlur}
            activeClass="bg-emerald-600 text-white"
            label={
              p.bgBlurOn
                ? t("call.v2.controls.blurOn", "Blur on")
                : t("call.v2.controls.blurOff", "Blur off")
            }
          />
        )}
        <CtrlBtn
          active={p.denoiserOn}
          onClick={p.onToggleDenoiser}
          activeClass="bg-emerald-600 text-white"
          label={
            p.denoiserOn
              ? t("call.v2.controls.denoiserOn", "AI noise: on")
              : t("call.v2.controls.denoiserOff", "AI noise: off")
          }
        />
        {isVideo && (
          <CtrlBtn
            active={p.isSharing}
            onClick={p.onToggleScreenShare}
            activeClass="bg-emerald-600 text-white"
            label={
              p.isSharing
                ? t("call.v2.controls.shareStop", "Stop share")
                : t("call.v2.controls.shareStart", "Share screen")
            }
          />
        )}
        <CtrlBtn
          active={p.captionsOn}
          onClick={p.onToggleCaptions}
          activeClass="bg-emerald-600 text-white"
          label={
            p.captionsOn
              ? t("call.v2.controls.captionsOn", "Captions on")
              : t("call.v2.controls.captionsOff", "Captions off")
          }
        />
        {p.captionsOn && (
          <CtrlBtn
            active={p.translateOn}
            onClick={p.onToggleTranslate}
            activeClass="bg-emerald-600 text-white"
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
        {lawyerView ? (
          <div
            role="status"
            aria-label={t("call.v2.controls.recordLawyerAria", "Recording status")}
            title={t(
              "call.v2.controls.recordLawyerTitle",
              "Only the citizen can start or stop cloud recording.",
            )}
            className={`whitespace-nowrap rounded-full px-3 py-2 text-xs font-semibold ${
              recOn || recBusy
                ? "bg-red-600 text-white"
                : "bg-white/10 text-slate-300"
            }`}
          >
            {recOn || recBusy
              ? t("call.v2.controls.recordLawyerOn", "Recording on")
              : t("call.v2.controls.recordLawyerOff", "Not recording")}
          </div>
        ) : (
          <CtrlBtn
            active={recOn}
            disabled={!p.citizenConsented || recBusy}
            onClick={p.onToggleRecording}
            activeClass="bg-red-600 text-white"
            label={
              recOn
                ? t("call.v2.controls.recordStop", "Stop rec")
                : recBusy
                  ? "…"
                  : t("call.v2.controls.recordStart", "Record")
            }
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
        <CtrlBtn
          active={p.chatOpen}
          onClick={p.onToggleChat}
          activeClass="bg-white/30 text-white"
          label={t("call.v2.controls.chat", "Chat")}
          shortcut="/"
        />
        {p.pipSlot}
        <button
          type="button"
          onClick={p.onEndCall}
          aria-label={t("call.end", "End call")}
          className="ms-auto whitespace-nowrap rounded-full bg-red-600 px-4 py-2 text-sm font-bold text-white hover:bg-red-500 focus-visible:ring-2 focus-visible:ring-red-300"
        >
          {t("call.end", "End call")}
        </button>
      </div>
    </div>
  );
}

function CtrlBtn({
  active,
  disabled,
  onClick,
  label,
  shortcut,
  activeClass,
  title,
}: {
  active: boolean;
  disabled?: boolean;
  onClick: () => void;
  label: string;
  shortcut?: string;
  activeClass: string;
  title?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-pressed={active}
      title={title ?? (shortcut ? `${label} (${shortcut})` : label)}
      className={`whitespace-nowrap rounded-full px-3 py-2 text-xs font-semibold transition focus-visible:ring-2 focus-visible:ring-amber-300 disabled:cursor-not-allowed disabled:opacity-50 ${
        active ? activeClass : "bg-white/15 text-white hover:bg-white/20"
      }`}
    >
      {label}
    </button>
  );
}
