"use client";

import { useEffect } from "react";

export function PwaRegistrar() {
  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;

    const register = async () => {
      try {
        const registration = await navigator.serviceWorker.register("/custom-sw.js", {
          scope: "/",
          updateViaCache: "none",
        });
        await registration.update().catch(() => undefined);
      } catch (error) {
        console.warn("[pwa] service worker registration failed:", error);
      }
    };

    if (document.readyState === "complete") {
      void register();
      return;
    }

    window.addEventListener("load", register, { once: true });
    return () => window.removeEventListener("load", register);
  }, []);

  return null;
}
