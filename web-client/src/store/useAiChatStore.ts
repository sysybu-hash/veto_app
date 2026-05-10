import { create } from "zustand";

export type AiChatRole = "user" | "assistant";
export type AiChatMode = "text" | "live" | "vision";

export interface AiChatMessage {
  id: string;
  role: AiChatRole;
  content: string;
}

export interface AiChatState {
  isOpen: boolean;
  requestedMode: AiChatMode | null;
  messages: AiChatMessage[];
  isLoading: boolean;

  toggleChat: () => void;
  openChat: (mode?: AiChatMode) => void;
  closeChat: () => void;
  clearRequestedMode: () => void;
  addMessage: (message: AiChatMessage) => void;
  setLoading: (loading: boolean) => void;
  clearChat: () => void;
}

export const useAiChatStore = create<AiChatState>((set) => ({
  isOpen: false,
  requestedMode: null,
  messages: [],
  isLoading: false,

  toggleChat: () => set((s) => ({ isOpen: !s.isOpen })),
  openChat: (mode = "text") => set({ isOpen: true, requestedMode: mode }),
  closeChat: () => set({ isOpen: false }),
  clearRequestedMode: () => set({ requestedMode: null }),

  addMessage: (message) =>
    set((s) => ({ messages: [...s.messages, message] })),

  setLoading: (loading) => set({ isLoading: loading }),

  clearChat: () =>
    set({
      messages: [],
      isLoading: false,
    }),
}));
