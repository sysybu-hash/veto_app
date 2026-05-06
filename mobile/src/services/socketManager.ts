import { io, type Socket } from "socket.io-client";

import { socketOrigin } from "@/constants/config";
import type { AuthUser } from "@/store/authStore";
import { useAuthStore } from "@/store/authStore";
import { useCallSessionStore } from "@/store/callSessionStore";
import { useEmergencyFeedStore } from "@/store/emergencyFeedStore";

let socket: Socket | null = null;

let callNavigate: ((roomId: string) => void) | null = null;

export function setCallNavigateHandler(fn: (roomId: string) => void) {
  callNavigate = fn;
}

function tunnelHeaders(): Record<string, string> {
  if (socketOrigin.toLowerCase().includes("loca.lt")) {
    return { "bypass-tunnel-reminder": "true" };
  }
  return {};
}

export function getSocket() {
  return socket;
}

export function disconnectSocket() {
  socket?.removeAllListeners();
  socket?.disconnect();
  socket = null;
}

export function connectSocket() {
  const token = useAuthStore.getState().token;
  if (!token) return;

  disconnectSocket();

  const uri = socketOrigin.replace(/\/$/, "");
  socket = io(uri, {
    auth: { token },
    extraHeaders: tunnelHeaders(),
    transports: ["websocket", "polling"],
  });

  socket.on("connect", () => {
    console.log("[socket] connected");
  });
  socket.on("disconnect", (reason) => {
    console.log("[socket] disconnect", reason);
  });
  socket.on("connect_error", (err) => {
    console.warn("[socket] connect_error", err.message);
  });

  socket.on("new_emergency_alert", (payload: unknown) => {
    const p = payload as {
      eventId?: string;
      userId?: string;
      userName?: string;
      location?: { lat: number; lng: number };
      language?: string;
      timestamp?: string;
    };
    if (p.eventId && p.userId && p.location) {
      useEmergencyFeedStore.getState().push({
        eventId: p.eventId,
        userId: p.userId,
        userName: p.userName ?? "User",
        location: p.location,
        language: p.language ?? "he",
        timestamp: p.timestamp ?? new Date().toISOString(),
      });
    }
  });

  socket.on("case_taken", (payload: unknown) => {
    const p = payload as { eventId?: string };
    if (p.eventId) useEmergencyFeedStore.getState().removeByEventId(p.eventId);
  });

  socket.on("session_ready", (payload: unknown) => {
    const p = payload as {
      roomId?: string;
      eventId?: string;
      callType?: string;
      agoraToken?: string;
      agoraUid?: number;
      tokenExpiresAt?: number;
    };
    const roomId = p.roomId ?? p.eventId;
    if (!roomId || !p.agoraToken || p.agoraUid === undefined) return;
    const callType =
      p.callType === "audio" || p.callType === "chat" ? p.callType : "video";
    useCallSessionStore.getState().setSession({
      roomId,
      channelId: roomId,
      agoraToken: p.agoraToken,
      agoraUid: Number(p.agoraUid),
      tokenExpiresAt: p.tokenExpiresAt,
      callType,
    });
    callNavigate?.(roomId);
  });
}

export type StartVetoPayload = {
  location: { lat: number; lng: number };
  preferredLanguage?: string;
  specialization?: string;
};

export function emitStartVeto(payload: StartVetoPayload) {
  socket?.emit("start_veto", payload);
}

export function emitCitizenChoseSession(eventId: string, callType: "video" | "audio" | "chat") {
  socket?.emit("citizen_chose_session", { eventId, callType });
}

export function emitLawyerAvailability(available: boolean) {
  socket?.emit("lawyer_availability", { available });
}

export function emitAcceptCase(eventId: string) {
  socket?.emit("accept_case", { eventId });
}

export function emitJoinCallRoom(roomId: string, callType: "video" | "audio" | "chat") {
  socket?.emit("join-call-room", { roomId, callType });
}

export function emitCallRenewToken(roomId: string) {
  socket?.emit("call-renew-token", { roomId });
}

export function subscribeCallTokenRenewed(cb: (data: {
  roomId: string;
  channelId: string;
  agoraToken: string;
  agoraUid: number;
  tokenExpiresAt?: number;
}) => void): () => void {
  socket?.on("call-token-renewed", cb);
  return () => {
    socket?.off("call-token-renewed", cb);
  };
}

export function ensureSocketForRole(user: AuthUser | null) {
  if (!user) {
    disconnectSocket();
    return;
  }
  const { appRole } = user;
  if (appRole === "citizen" || appRole === "lawyer" || appRole === "admin") {
    connectSocket();
  }
}
