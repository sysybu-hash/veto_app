"use client";

import type { ReactNode } from "react";
import { useState } from "react";
import {
  MessageCircle,
  Mic,
  MicOff,
  MoreHorizontal,
  PhoneOff,
  Video,
  VideoOff,
} from "lucide-react";
import { useTrWithFallback } from "../lib/trWithFallback";
import { MoreMenu } from "./MoreMenu";

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
  /** New messages have arrived while the chat panel is closed. */
  chatUnread?: boolean;
  /** Citizen has approved recording (required to use the record control). */
  citizenConsented: boolean;
  /** Citizen can start/stop; lawyer only sees recording status (in ConsentBanner). */
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
  onSaveToVault?: () => void;
  vaultStatus?: "idle" | "saving" | "saved" | "error";
};

/**
 * Primary row: mic, camera, end-call, "more", chat — large icon-only
 * circular buttons, always visible. Everything else (blur, noise, share,
 * captions, translate, PiP, vault save, citizen-only record) lives in
 * `MoreMenu`, opened on demand, so the main screen stays uncluttered —
 * important in an emergency-call context.
 */
export function ControlBar(p: ControlBarProps) {
  const t = useTrWithFallback();
  const isVideo = p.mode === "video";
  const [moreOpen, setMoreOpen] = useState(false);

  const closeMore = () => setMoreOpen(false);

  return (
    <div className="@container/cb pointer-events-none absolute inset-x-0 bottom-0 z-30 px-2 pb-3 @md:px-4">
      <MoreMenu
        open={moreOpen}
        onClose={closeMore}
        mode={p.mode}
        denoiserOn={p.denoiserOn}
        bgBlurOn={p.bgBlurOn}
        isSharing={p.isSharing}
        recording={p.recording}
        captionsOn={p.captionsOn}
        translateOn={p.translateOn}
        citizenConsented={p.citizenConsented}
        myRole={p.myRole}
        onToggleDenoiser={p.onToggleDenoiser}
        onToggleBgBlur={p.onToggleBgBlur}
        onToggleScreenShare={p.onToggleScreenShare}
        onToggleRecording={p.onToggleRecording}
        onToggleCaptions={p.onToggleCaptions}
        onToggleTranslate={p.onToggleTranslate}
        pipSlot={p.pipSlot}
        onSaveToVault={p.onSaveToVault}
        vaultStatus={p.vaultStatus}
      />

      <div
        className="pointer-events-auto mx-auto flex max-w-md items-center justify-center gap-3 rounded-full border border-[#C5A059]/20 bg-zinc-950/80 px-3 py-2.5 shadow-[0_12px_40px_rgba(0,0,0,0.55)] backdrop-blur-xl"
        role="toolbar"
        aria-label={t("call.v2.controls.aria", "Call controls")}
      >
        <IconBtn
          active={!p.micOn}
          onClick={p.onToggleMic}
          activeClass="bg-amber-600 text-white"
          label={p.micOn ? t("call.mute", "Mute") : t("call.unmute", "Unmute")}
          icon={p.micOn ? <Mic className="h-[22px] w-[22px]" aria-hidden /> : <MicOff className="h-[22px] w-[22px]" aria-hidden />}
          shortcut="M"
        />
        {isVideo && (
          <IconBtn
            active={!p.cameraOn}
            onClick={p.onToggleCamera}
            activeClass="bg-amber-600 text-white"
            label={
              p.cameraOn
                ? t("call.cameraOff", "Camera off")
                : t("call.cameraOn", "Camera on")
            }
            icon={p.cameraOn ? <Video className="h-[22px] w-[22px]" aria-hidden /> : <VideoOff className="h-[22px] w-[22px]" aria-hidden />}
            shortcut="V"
          />
        )}

        <button
          type="button"
          onClick={p.onEndCall}
          aria-label={t("call.end", "End call")}
          title={t("call.end", "End call")}
          className="flex h-[62px] w-[62px] items-center justify-center rounded-full bg-red-600 text-white shadow-lg shadow-red-900/40 outline-none transition hover:bg-red-500 focus-visible:ring-2 focus-visible:ring-red-300"
        >
          <PhoneOff className="h-[26px] w-[26px]" aria-hidden />
        </button>

        <IconBtn
          active={moreOpen}
          onClick={() => setMoreOpen((v) => !v)}
          activeClass="bg-white/30 text-white"
          label={t("call.v2.controls.more", "More")}
          icon={<MoreHorizontal className="h-[22px] w-[22px]" aria-hidden />}
        />
        <IconBtn
          active={p.chatOpen}
          onClick={p.onToggleChat}
          activeClass="bg-white/30 text-white"
          label={t("call.v2.controls.chat", "Chat")}
          icon={<MessageCircle className="h-[22px] w-[22px]" aria-hidden />}
          shortcut="/"
          badge={p.chatUnread}
        />
      </div>
    </div>
  );
}

function IconBtn({
  active,
  disabled,
  onClick,
  icon,
  label,
  shortcut,
  activeClass,
  badge,
}: {
  active: boolean;
  disabled?: boolean;
  onClick: () => void;
  icon: ReactNode;
  label: string;
  shortcut?: string;
  activeClass: string;
  badge?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-pressed={active}
      aria-label={label}
      title={shortcut ? `${label} (${shortcut})` : label}
      className={`relative flex h-[52px] w-[52px] items-center justify-center rounded-full text-[22px] outline-none transition focus-visible:ring-2 focus-visible:ring-[#C5A059] disabled:cursor-not-allowed disabled:opacity-50 ${
        active ? activeClass : "bg-white/12 text-white hover:bg-white/18"
      }`}
    >
      {icon}
      {badge && (
        <span
          aria-hidden
          className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-[#C5A059]"
        />
      )}
    </button>
  );
}
