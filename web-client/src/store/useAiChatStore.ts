import { create } from "zustand";

export type AiChatRole = "user" | "assistant";

export interface AiChatMessage {
  id: string;
  role: AiChatRole;
  content: string;
}

export interface AiChatState {
  isOpen: boolean;
  messages: AiChatMessage[];
  isLoading: boolean;

  toggleChat: () => void;
  addMessage: (message: AiChatMessage) => void;
  setLoading: (loading: boolean) => void;
  clearChat: () => void;
}

export const useAiChatStore = create<AiChatState>((set) => ({
  isOpen: false,
  messages: [],
  isLoading: false,

  toggleChat: () => set((s) => ({ isOpen: !s.isOpen })),

  addMessage: (message) =>
    set((s) => ({ messages: [...s.messages, message] })),

  setLoading: (loading) => set({ isLoading: loading }),

  clearChat: () =>
    set({
      messages: [],
      isLoading: false,
    }),
}));
