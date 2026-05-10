/**
 * Agora extensions singleton — register exactly once per app lifetime.
 *
 *  - AI Denoiser: ML-based noise suppression. Loads a WASM blob (~2 MB).
 *  - Virtual Background: blur / image / colour replacement.
 *
 * Both extensions are static; the dynamic per-track processors are spun
 * up by the call hooks below. We import lazily so the extensions' WASM
 * doesn't bloat any non-call route bundle.
 */

import type { IAgoraRTC } from "agora-rtc-sdk-ng";
import type { AIDenoiserExtension } from "agora-extension-ai-denoiser";
import type VirtualBackgroundExtensionType from "agora-extension-virtual-background";

type RegisterableExt = { checkCompatibility?: () => boolean };

type ExtensionsHandle = {
  denoiser: AIDenoiserExtension | null;
  virtualBg: VirtualBackgroundExtensionType | null;
};

let registered = false;
let cachedDenoiser: AIDenoiserExtension | null = null;
let cachedVirtualBg: VirtualBackgroundExtensionType | null = null;

export async function registerAgoraExtensions(
  AgoraRTC: IAgoraRTC,
): Promise<ExtensionsHandle> {
  if (registered) return getCachedExtensions();

  const [denoiserMod, vbMod] = await Promise.all([
    import("agora-extension-ai-denoiser"),
    import("agora-extension-virtual-background"),
  ]);

  const denoiser = new denoiserMod.AIDenoiserExtension({
    assetsPath: "/agora-ai-denoiser",
  });
  const virtualBg = new vbMod.default();

  if ((denoiser as RegisterableExt).checkCompatibility?.()) {
    AgoraRTC.registerExtensions([denoiser]);
  }
  if ((virtualBg as RegisterableExt).checkCompatibility?.()) {
    AgoraRTC.registerExtensions([virtualBg]);
  }

  registered = true;
  cachedDenoiser = denoiser;
  cachedVirtualBg = virtualBg;
  return { denoiser, virtualBg };
}

function getCachedExtensions(): ExtensionsHandle {
  return { denoiser: cachedDenoiser, virtualBg: cachedVirtualBg };
}
