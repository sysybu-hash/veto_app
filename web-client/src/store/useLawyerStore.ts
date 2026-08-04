import { create } from "zustand";
import { persist } from "zustand/middleware";

/** Normalized emergency alert from `new_emergency_alert` (backend dispatch). */
export interface LawyerActiveAlert {
  eventId: string;
  userId: string | null;
  userName: string;
  /** Optional — push deep-links may arrive without GPS. */
  location: { lat: number; lng: number } | null;
  language: string;
  timestamp: string;
}

type LawyerState = {
  isAvailable: boolean;
  activeAlert: LawyerActiveAlert | null;
  isAccepting: boolean;
  lastError: string | null;

  setAvailable: (available: boolean) => void;
  setActiveAlert: (alert: LawyerActiveAlert | null) => void;
  setAccepting: (value: boolean) => void;
  setLastError: (message: string | null) => void;
  clearAlert: () => void;
  reset: () => void;
};

const initial = {
  isAvailable: true,
  activeAlert: null as LawyerActiveAlert | null,
  isAccepting: false,
  lastError: null as string | null,
};

export const useLawyerStore = create<LawyerState>()(
  persist(
    (set) => ({
      ...initial,

      setAvailable: (available) => set({ isAvailable: available }),

      setActiveAlert: (alert) =>
        set({
          activeAlert: alert,
          lastError: null,
        }),

      setAccepting: (value) => set({ isAccepting: value }),

      setLastError: (message) => set({ lastError: message }),

      clearAlert: () => set({ activeAlert: null, isAccepting: false }),

      reset: () => set({ ...initial }),
    }),
    {
      name: "veto-lawyer-availability",
      partialize: (state) => ({ isAvailable: state.isAvailable }),
    },
  ),
);
