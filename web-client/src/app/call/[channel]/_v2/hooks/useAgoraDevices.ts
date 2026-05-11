"use client";

import { useCallback, useEffect, useState } from "react";

export type DeviceList = {
  microphones: MediaDeviceInfo[];
  cameras: MediaDeviceInfo[];
  speakers: MediaDeviceInfo[];
};

const STORAGE_KEYS = {
  mic: "veto.call.v2.deviceId.mic",
  camera: "veto.call.v2.deviceId.camera",
  speaker: "veto.call.v2.deviceId.speaker",
};

function readStored(key: string): string | null {
  if (typeof localStorage === "undefined") return null;
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function writeStored(key: string, value: string | null) {
  if (typeof localStorage === "undefined") return;
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch {
    /* ignore quota / private mode */
  }
}

/**
 * Lists available input/output devices and persists the user's last
 * selection across sessions. Empty selectedXxxxId means "browser default".
 */
export function useAgoraDevices() {
  const [devices, setDevices] = useState<DeviceList>({
    microphones: [],
    cameras: [],
    speakers: [],
  });
  const [selectedMicId, setSelectedMicId] = useState<string | null>(() =>
    readStored(STORAGE_KEYS.mic),
  );
  const [selectedCameraId, setSelectedCameraId] = useState<string | null>(() =>
    readStored(STORAGE_KEYS.camera),
  );
  const [selectedSpeakerId, setSelectedSpeakerId] = useState<string | null>(() =>
    readStored(STORAGE_KEYS.speaker),
  );
  const [permission, setPermission] = useState<
    "unknown" | "granted" | "denied"
  >("unknown");

  const refresh = useCallback(async () => {
    if (typeof navigator === "undefined" || !navigator.mediaDevices) return;
    try {
      const all = await navigator.mediaDevices.enumerateDevices();
      setDevices({
        microphones: all.filter((d) => d.kind === "audioinput"),
        cameras: all.filter((d) => d.kind === "videoinput"),
        speakers: all.filter((d) => d.kind === "audiooutput"),
      });
    } catch (err) {
      console.warn("[call/v2] enumerateDevices failed:", err);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(() => {
      void refresh();
    });
    const onChange = () => void refresh();
    if (navigator.mediaDevices?.addEventListener) {
      navigator.mediaDevices.addEventListener("devicechange", onChange);
      return () => {
        navigator.mediaDevices.removeEventListener("devicechange", onChange);
      };
    }
    return undefined;
  }, [refresh]);

  /** Asks the browser for mic+camera, then refreshes the list (labels become visible). */
  const requestPermission = useCallback(
    async (need: { mic: boolean; camera: boolean }) => {
      if (typeof navigator === "undefined" || !navigator.mediaDevices) {
        setPermission("denied");
        return false;
      }
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: need.mic,
          video: need.camera,
        });
        // Immediately stop — we only wanted the labels and consent.
        stream.getTracks().forEach((t) => t.stop());
        setPermission("granted");
        await refresh();
        return true;
      } catch (err) {
        console.warn("[call/v2] permission request failed:", err);
        setPermission("denied");
        return false;
      }
    },
    [refresh],
  );

  const chooseMic = useCallback((id: string | null) => {
    setSelectedMicId(id);
    writeStored(STORAGE_KEYS.mic, id);
  }, []);

  const chooseCamera = useCallback((id: string | null) => {
    setSelectedCameraId(id);
    writeStored(STORAGE_KEYS.camera, id);
  }, []);

  const chooseSpeaker = useCallback((id: string | null) => {
    setSelectedSpeakerId(id);
    writeStored(STORAGE_KEYS.speaker, id);
  }, []);

  return {
    devices,
    selectedMicId,
    selectedCameraId,
    selectedSpeakerId,
    permission,
    refresh,
    requestPermission,
    chooseMic,
    chooseCamera,
    chooseSpeaker,
  };
}
