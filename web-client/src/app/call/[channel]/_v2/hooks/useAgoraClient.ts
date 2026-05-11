"use client";

import { useEffect, useMemo, useState } from "react";
import type {
  IAgoraRTCClient,
  IAgoraRTC,
  ConnectionState,
  ConnectionDisconnectedReason,
  IAgoraRTCRemoteUser,
  NetworkQuality,
} from "agora-rtc-sdk-ng";
import { pickPreferredCodec } from "../lib/codec";
import { registerAgoraExtensions } from "../lib/agoraExtensions";

type ConnectionStatus = ConnectionState | "FAILED";

export type AgoraClientHandle = {
  client: IAgoraRTCClient | null;
  AgoraRTC: IAgoraRTC | null;
  remoteUsers: IAgoraRTCRemoteUser[];
  connectionState: ConnectionStatus;
  networkQuality: NetworkQuality | null;
  ready: boolean;
};

/**
 * Creates a single Agora RTC client per call session, registers the
 * extensions, and exposes reactive arrays for remote users + connection
 * state. Cleans up on unmount so HMR doesn't leak Agora clients.
 */
export function useAgoraClient(): AgoraClientHandle {
  const [client, setClient] = useState<IAgoraRTCClient | null>(null);
  const [AgoraRTC, setAgoraRTC] = useState<IAgoraRTC | null>(null);
  const [remoteUsers, setRemoteUsers] = useState<IAgoraRTCRemoteUser[]>([]);
  const [connectionState, setConnectionState] =
    useState<ConnectionStatus>("DISCONNECTED");
  const [networkQuality, setNetworkQuality] =
    useState<NetworkQuality | null>(null);
  const [extensionsReady, setExtensionsReady] = useState(false);

  // Step 1: Dynamically import the SDK + create one client.
  useEffect(() => {
    let cancelled = false;
    let createdClient: IAgoraRTCClient | null = null;

    void (async () => {
      const mod = await import("agora-rtc-sdk-ng");
      if (cancelled) return;
      const sdk = mod.default;
      const codec = pickPreferredCodec();
      const c = sdk.createClient({ mode: "rtc", codec });
      createdClient = c;

      try {
        await registerAgoraExtensions(sdk);
      } catch (err) {
        // Extensions can fail (WASM blocked, browser unsupported); we keep
        // the call working without them rather than blowing up.
        console.warn("[call/v2] extension registration failed:", err);
      }

      if (cancelled) return;
      setAgoraRTC(sdk);
      setClient(c);
      setExtensionsReady(true);
    })();

    return () => {
      cancelled = true;
      try {
        if (createdClient && createdClient.connectionState !== "DISCONNECTED") {
          void createdClient.leave();
        }
      } catch {
        /* ignore */
      }
    };
  }, []);

  // Step 2: Wire up the lifecycle events.
  useEffect(() => {
    if (!client) return;

    const onUserPublished = async (
      user: IAgoraRTCRemoteUser,
      mediaType: "audio" | "video",
    ) => {
      try {
        await client.subscribe(user, mediaType);
      } catch (err) {
        console.warn("[call/v2] subscribe failed:", err);
        return;
      }
      setRemoteUsers((prev) =>
        prev.some((u) => u.uid === user.uid)
          ? prev.map((u) => (u.uid === user.uid ? user : u))
          : [...prev, user],
      );
      if (mediaType === "audio") {
        try {
          user.audioTrack?.play();
        } catch {
          /* autoplay restrictions */
        }
      }
    };

    const onUserUnpublished = (user: IAgoraRTCRemoteUser) => {
      setRemoteUsers((prev) =>
        prev.map((u) => (u.uid === user.uid ? user : u)),
      );
    };

    const onUserLeft = (user: IAgoraRTCRemoteUser) => {
      setRemoteUsers((prev) => prev.filter((u) => u.uid !== user.uid));
    };

    const onConn = (
      cur: ConnectionState,
      _prev: ConnectionState,
      reason?: ConnectionDisconnectedReason,
    ) => {
      // Treat any "non-leave-on-purpose" disconnect as FAILED so the overlay
      // surfaces. The leaving-our-own-call cases set DISCONNECTED with reason
      // `LEAVE` or undefined.
      if (cur === "DISCONNECTED" && reason && reason !== "LEAVE") {
        setConnectionState("FAILED");
      } else {
        setConnectionState(cur);
      }
    };

    const onNetwork = (q: NetworkQuality) => setNetworkQuality(q);

    client.on("user-published", onUserPublished);
    client.on("user-unpublished", onUserUnpublished);
    client.on("user-left", onUserLeft);
    client.on("connection-state-change", onConn);
    client.on("network-quality", onNetwork);

    return () => {
      client.off("user-published", onUserPublished);
      client.off("user-unpublished", onUserUnpublished);
      client.off("user-left", onUserLeft);
      client.off("connection-state-change", onConn);
      client.off("network-quality", onNetwork);
    };
  }, [client]);

  return useMemo(
    () => ({
      client,
      AgoraRTC,
      remoteUsers,
      connectionState,
      networkQuality,
      ready: extensionsReady && !!client && !!AgoraRTC,
    }),
    [client, AgoraRTC, remoteUsers, connectionState, networkQuality, extensionsReady],
  );
}
