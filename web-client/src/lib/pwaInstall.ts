/**
 * iOS only delivers Web Push to a site the user has added to the Home Screen
 * (Safari 16.4+). In a normal Safari tab `PushManager` is simply absent, so a
 * subscription attempt fails with "unsupported" and there is nothing to log —
 * which is how a lawyer could switch themselves to available and never learn
 * that no SOS alert would ever reach them.
 *
 * These helpers let the UI tell the difference between "this browser will
 * never support push" and "this browser will, once you install the app".
 */

/** iPhone/iPad, including iPadOS which reports itself as a Mac with touch. */
export function isIos(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent || "";
  if (/iPad|iPhone|iPod/.test(ua)) return true;
  return (
    ua.includes("Macintosh") &&
    typeof document !== "undefined" &&
    navigator.maxTouchPoints > 1
  );
}

/** True when running as an installed PWA rather than a browser tab. */
export function isStandalone(): boolean {
  if (typeof window === "undefined") return false;
  const iosStandalone = (
    window.navigator as Navigator & { standalone?: boolean }
  ).standalone;
  return (
    iosStandalone === true ||
    window.matchMedia?.("(display-mode: standalone)").matches === true
  );
}

export function pushApiAvailable(): boolean {
  return (
    typeof window !== "undefined" &&
    "serviceWorker" in navigator &&
    "PushManager" in window &&
    "Notification" in window
  );
}

/**
 * The actionable case: an iPhone user who only has to install the app. Any
 * other unsupported browser gets a plain "not supported" instead, because
 * telling them to install would be a dead end.
 */
export function needsIosInstallForPush(): boolean {
  return isIos() && !isStandalone() && !pushApiAvailable();
}
