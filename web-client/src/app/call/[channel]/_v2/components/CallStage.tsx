"use client";

import { useEffect, useRef } from "react";
import type {
  IAgoraRTCRemoteUser,
  ILocalVideoTrack,
} from "agora-rtc-sdk-ng";
import { useTrWithFallback } from "../lib/trWithFallback";

/**
 * Renders the local + remote video tracks. We use Agora's `play()` directly
 * because we need plain HTMLVideoElement refs (so PiP and screen-readers
 * work) — Agora's React helpers wrap them in extra divs we don't want.
 *
 * Container queries scale the local PiP / control padding instead of media
 * queries so the call works in both fullscreen and any side-panel layout.
 */
export function CallStage({
  localCameraTrack,
  remoteUsers,
  videoEnabled,
  cameraOn,
  isScreenSharing,
  setRemoteVideoEl,
}: {
  localCameraTrack: ILocalVideoTrack | null;
  remoteUsers: IAgoraRTCRemoteUser[];
  videoEnabled: boolean;
  cameraOn: boolean;
  isScreenSharing: boolean;
  setRemoteVideoEl: (el: HTMLVideoElement | null) => void;
}) {
  const t = useTrWithFallback();
  const localRef = useRef<HTMLDivElement | null>(null);
  const remoteRef = useRef<HTMLDivElement | null>(null);

  // Play / re-play the local camera track whenever it changes.
  useEffect(() => {
    if (!localCameraTrack || !localRef.current) return;
    try {
      localCameraTrack.play(localRef.current, {
        fit: "cover",
        mirror: true,
      });
    } catch {
      /* track might already be playing elsewhere */
    }
    return () => {
      try {
        localCameraTrack.stop();
      } catch {
        /* ignore */
      }
    };
  }, [localCameraTrack]);

  // Play remote users' video into the same big stage tile.
  const remote = remoteUsers[0];
  useEffect(() => {
    if (!remote || !remoteRef.current) {
      setRemoteVideoEl(null);
      return;
    }
    try {
      remote.videoTrack?.play(remoteRef.current, { fit: "cover" });
    } catch {
      /* ignore */
    }
    // Find the actual <video> created by Agora so PiP can host it.
    const v = remoteRef.current.querySelector("video");
    setRemoteVideoEl(v as HTMLVideoElement | null);
    return () => {
      try {
        remote.videoTrack?.stop();
      } catch {
        /* ignore */
      }
      setRemoteVideoEl(null);
    };
  }, [remote, remote?.videoTrack, setRemoteVideoEl]);

  const showLocalSelf = videoEnabled && cameraOn && localCameraTrack;

  return (
    <div className="@container relative h-full w-full min-h-0">
      <div
        ref={remoteRef}
        className="h-full w-full min-h-0 bg-zinc-950 [&_video]:h-full [&_video]:w-full [&_video]:object-cover"
      />
      {!remote && (
        <div className="absolute inset-0 flex items-center justify-center text-sm text-muted">
          {t("call.v2.stage.waiting", "Waiting for the other side…")}
        </div>
      )}

      {showLocalSelf && (
        <div
          className="absolute end-3 top-3 z-10 overflow-hidden rounded-xl border border-subtle shadow-xl @sm:end-4 @sm:top-4 w-24 h-32 @md:w-28 @md:h-36 @lg:w-36 @lg:h-44 [&_video]:h-full [&_video]:w-full [&_video]:object-cover"
        >
          <div ref={localRef} className="h-full w-full" />
        </div>
      )}

      {isScreenSharing && (
        <div className="absolute start-3 top-3 z-10 rounded-full border border-emerald-500/40 bg-emerald-950/80 px-3 py-1 text-[11px] font-bold text-emerald-200 backdrop-blur">
          {t("call.v2.stage.screenSharing", "You are sharing your screen")}
        </div>
      )}
    </div>
  );
}
