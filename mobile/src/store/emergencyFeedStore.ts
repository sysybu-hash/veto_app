import { create } from "zustand";

export type IncomingEmergency = {
  eventId: string;
  userId: string;
  userName: string;
  location: { lat: number; lng: number };
  language: string;
  timestamp: string;
};

type EmergencyFeedState = {
  items: IncomingEmergency[];
  push: (item: IncomingEmergency) => void;
  removeByEventId: (eventId: string) => void;
  clear: () => void;
};

export const useEmergencyFeedStore = create<EmergencyFeedState>((set) => ({
  items: [],
  push: (item) =>
    set((s) => ({
      items: [item, ...s.items.filter((i) => i.eventId !== item.eventId)],
    })),
  removeByEventId: (eventId) =>
    set((s) => ({
      items: s.items.filter((i) => i.eventId !== eventId),
    })),
  clear: () => set({ items: [] }),
}));
