import { create } from "zustand";

export type CallSessionPayload = {
  roomId: string;
  channelId: string;
  agoraToken: string;
  /** Numeric UID from Agora builder */
  agoraUid: number;
  tokenExpiresAt?: number;
  callType: "video" | "audio" | "chat";
};

type CallSessionState = {
  session: CallSessionPayload | null;
  setSession: (s: CallSessionPayload | null) => void;
};

export const useCallSessionStore = create<CallSessionState>((set) => ({
  session: null,
  setSession: (session) => set({ session }),
}));
