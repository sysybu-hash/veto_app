"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type {
  IAgoraRTCClient,
  IAgoraRTC,
  ILocalVideoTrack,
} from "agora-rtc-sdk-ng";

/**
 * Toggle screen sharing. While active, replaces the published camera track
 * with the screen track and exposes both for the UI (we keep the camera
 * track around so we can flip back without re-prompting for permission).
 */
export function useScreenShare(opts: {
  client: IAgoraRTCClient | null;
  AgoraRTC: IAgoraRTC | null;
  cameraTrack: ILocalVideoTrack | null;
}) {
  const { client, AgoraRTC, cameraTrack } = opts;
  const [screenTrack, setScreenTrack] = useState<ILocalVideoTrack | null>(null);
  const [error, setError] = useState<string | null>(null);
  const wasPublishedRef = useRef<boolean>(false);

  const stop = useCallback(async () => {
    if (!screenTrack) return;
    try {
      if (client && client.localTracks.includes(screenTrack)) {
        await client.unpublish(screenTrack);
      }
      screenTrack.close();
    } catch {
      /* ignore */
    }
    setScreenTrack(null);

    if (client && cameraTrack && wasPublishedRef.current) {
      try {
        await client.publish(cameraTrack);
      } catch (err) {
        console.warn("[call/v2] re-publish camera after screenshare failed:", err);
      }
      wasPublishedRef.current = false;
    }
  }, [client, cameraTrack, screenTrack]);

  // We capture `stop` in a ref so the `track-ended` callback inside `start`
  // can call it without a forward reference (which the React Compiler would
  // flag) and without listing `stop` in `start`'s deps (which would re-create
  // `start` after every screenshare cycle).
  const stopRef = useRef(stop);
  useEffect(() => {
    stopRef.current = stop;
  }, [stop]);

  const start = useCallback(async () => {
    if (!client || !AgoraRTC) return;
    if (screenTrack) return;
    setError(null);
    try {
      const track = await AgoraRTC.createScreenVideoTrack(
        { encoderConfig: "1080p_1" },
        "disable",
      );
      const video = Array.isArray(track) ? track[0] : track;

      // If a camera track is currently published, swap it out.
      if (cameraTrack && client.localTracks.includes(cameraTrack)) {
        await client.unpublish(cameraTrack);
        wasPublishedRef.current = true;
      }
      await client.publish(video);
      setScreenTrack(video);

      // The user can hit "Stop sharing" in the browser UI — close cleanly.
      video.on("track-ended", () => {
        void stopRef.current?.();
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }, [client, AgoraRTC, cameraTrack, screenTrack]);

  return {
    isSharing: !!screenTrack,
    screenTrack,
    error,
    start,
    stop,
  };
}
