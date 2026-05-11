import { create } from "zustand";

export type SessionCallType = "audio" | "video" | "chat";

export type SessionReadyState = {
  channelId: string;
  eventId: string;
  token: string;
  uid: number;
  callType: SessionCallType;
  tokenExpiresAt?: number;
  /** Per-event shared secret for Agora E2EE (from server, same for citizen & lawyer). */
  e2eeSecret?: string;
};

type EmergencyState = {
  isSearching: boolean;
  lawyerFound: boolean;
  lawyerName: string | null;
  currentEventId: string | null;
  currentRoomId: string | null;
  sessionReady: SessionReadyState | null;
  statusMessage: string | null;

  reset: () => void;
  startSearch: () => void;
  stopSearchUi: () => void;
  setLawyerFound: (payload: {
    eventId: string;
    roomId: string;
    lawyerName?: string;
  }) => void;
  setSessionReady: (payload: SessionReadyState) => void;
  setErrorMessage: (message: string | null) => void;
  clearCallSession: () => void;
};

const initial = {
  isSearching: false,
  lawyerFound: false,
  lawyerName: null as string | null,
  currentEventId: null as string | null,
  currentRoomId: null as string | null,
  sessionReady: null as SessionReadyState | null,
  statusMessage: null as string | null,
};

export const useEmergencyStore = create<EmergencyState>((set) => ({
  ...initial,

  reset: () => set({ ...initial }),

  startSearch: () =>
    set({
      isSearching: true,
      lawyerFound: false,
      lawyerName: null,
      currentEventId: null,
      currentRoomId: null,
      sessionReady: null,
      statusMessage: null,
    }),

  stopSearchUi: () => set({ isSearching: false }),

  setLawyerFound: ({ eventId, roomId, lawyerName }) =>
    set({
      lawyerFound: true,
      currentEventId: eventId,
      currentRoomId: roomId,
      lawyerName: lawyerName ?? null,
      statusMessage: null,
    }),

  setSessionReady: (payload) =>
    set({
      sessionReady: payload,
      isSearching: false,
      statusMessage: null,
    }),

  setErrorMessage: (message) =>
    set({
      statusMessage: message,
      isSearching: false,
      lawyerFound: false,
    }),

  clearCallSession: () => set({ sessionReady: null }),
}));
