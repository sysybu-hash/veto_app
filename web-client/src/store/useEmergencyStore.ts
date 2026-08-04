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

/**
 * Shared with `PreCallCheck.tsx` — moved here so the call-type / accept-case
 * buttons (on `hub`/`dashboard`, a different route than `/call/[channel]`)
 * can write a readiness result that `CallShell.tsx` later reads.
 */
export type PreCallReadiness = {
  micId: string | null;
  cameraId: string | null;
  speakerId: string | null;
  ready: boolean;
};

export type PreCallPermissionStatus = "idle" | "pending" | "granted" | "denied";

type EmergencyState = {
  isSearching: boolean;
  lawyerFound: boolean;
  lawyerName: string | null;
  currentEventId: string | null;
  currentRoomId: string | null;
  sessionReady: SessionReadyState | null;
  statusMessage: string | null;
  /**
   * Result of the mic/camera permission request fired from the call-type
   * (citizen) or accept-case (lawyer) button — a single user gesture that
   * both picks the call and grants device access, so `CallShell.tsx` no
   * longer has to show a separate PreCallCheck step on the happy path.
   */
  preCallReadiness: PreCallReadiness | null;
  preCallPermissionStatus: PreCallPermissionStatus;

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
  setPreCallReadiness: (r: PreCallReadiness) => void;
  setPreCallPermissionStatus: (s: PreCallPermissionStatus) => void;
};

const initial = {
  isSearching: false,
  lawyerFound: false,
  lawyerName: null as string | null,
  currentEventId: null as string | null,
  currentRoomId: null as string | null,
  sessionReady: null as SessionReadyState | null,
  statusMessage: null as string | null,
  preCallReadiness: null as PreCallReadiness | null,
  preCallPermissionStatus: "idle" as PreCallPermissionStatus,
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
    set(
      message
        ? {
            statusMessage: message,
            isSearching: false,
            lawyerFound: false,
          }
        : {
            // Clearing an error must NOT abort an in-flight SOS search.
            // hub calls setErrorMessage(null) right after startSearch().
            statusMessage: null,
          },
    ),

  clearCallSession: () =>
    set({
      sessionReady: null,
      preCallReadiness: null,
      preCallPermissionStatus: "idle",
    }),

  setPreCallReadiness: (r) => set({ preCallReadiness: r }),
  setPreCallPermissionStatus: (s) => set({ preCallPermissionStatus: s }),
}));
