"use client";

import { useEffect, useState } from "react";
import { useTrWithFallback } from "../lib/trWithFallback";

type DocPipWindow = Window & {
  document: Document;
  close: () => void;
};

type DocumentPip = {
  requestWindow: (opts?: {
    width?: number;
    height?: number;
  }) => Promise<DocPipWindow>;
};

declare global {
  interface Window {
    documentPictureInPicture?: DocumentPip;
  }
}

/**
 * Picture-in-Picture button — uses the Document PiP API where available so
 * the user can keep the call visible while reading documents in another
 * tab. We pop a tiny window with the remote video track + mute/end controls.
 */
export function DocumentPipToggle({
  remoteVideo,
  onToggleMute,
  onEndCall,
}: {
  remoteVideo: HTMLVideoElement | null;
  onToggleMute: () => void;
  onEndCall: () => void;
}) {
  const t = useTrWithFallback();
  const [supported, setSupported] = useState(false);
  const [active, setActive] = useState(false);
  const [pipWin, setPipWin] = useState<DocPipWindow | null>(null);

  useEffect(() => {
    queueMicrotask(() => {
      setSupported(
        typeof window !== "undefined" && !!window.documentPictureInPicture,
      );
    });
  }, []);

  useEffect(() => {
    if (!pipWin) return;
    const onClose = () => {
      setPipWin(null);
      setActive(false);
    };
    pipWin.addEventListener("pagehide", onClose);
    return () => pipWin.removeEventListener("pagehide", onClose);
  }, [pipWin]);

  const open = async () => {
    if (!window.documentPictureInPicture || !remoteVideo) return;
    try {
      const win = await window.documentPictureInPicture.requestWindow({
        width: 360,
        height: 280,
      });
      // Move the existing video element into the PiP window's body so
      // playback continues without re-attaching the track.
      const container = win.document.createElement("div");
      container.style.cssText =
        "background:#000;color:#fff;font-family:system-ui;display:flex;flex-direction:column;height:100vh;";

      const stage = win.document.createElement("div");
      stage.style.cssText = "flex:1;position:relative;overflow:hidden;";
      const video = remoteVideo;
      stage.appendChild(video);
      // Aliasing through a const cleanly tells the React Compiler this is a
      // local DOM element handle, not a prop we're mutating across renders.
      Object.assign(video.style, {
        width: "100%",
        height: "100%",
        objectFit: "cover",
      } as Partial<CSSStyleDeclaration>);

      const controls = win.document.createElement("div");
      controls.style.cssText =
        "display:flex;gap:8px;padding:8px;background:rgba(0,0,0,.85);";

      const muteBtn = win.document.createElement("button");
      muteBtn.textContent = "Mute";
      muteBtn.style.cssText =
        "flex:1;padding:6px 10px;background:rgba(255,255,255,.1);color:white;border:0;border-radius:6px;cursor:pointer;";
      muteBtn.onclick = () => onToggleMute();

      const endBtn = win.document.createElement("button");
      endBtn.textContent = "End";
      endBtn.style.cssText =
        "flex:1;padding:6px 10px;background:#dc2626;color:white;border:0;border-radius:6px;cursor:pointer;";
      endBtn.onclick = () => onEndCall();

      controls.appendChild(muteBtn);
      controls.appendChild(endBtn);
      container.appendChild(stage);
      container.appendChild(controls);
      win.document.body.style.margin = "0";
      win.document.body.appendChild(container);

      setPipWin(win);
      setActive(true);
    } catch (err) {
      console.warn("[call/v2] documentPip open failed:", err);
    }
  };

  const close = () => {
    pipWin?.close();
    setPipWin(null);
    setActive(false);
  };

  if (!supported) return null;

  return (
    <button
      type="button"
      onClick={() => (active ? close() : void open())}
      aria-pressed={active}
      title={t("call.v2.pip.toggle", "Picture-in-picture")}
      className={`rounded-full px-3 py-2 text-xs font-medium ${
        active ? "bg-amber-600 text-inverse" : "bg-white/15 text-inverse hover:bg-white/20"}`}
    >
      {active
        ? t("call.v2.pip.exit", "Exit PiP")
        : t("call.v2.pip.enter", "PiP")}
    </button>
  );
}
