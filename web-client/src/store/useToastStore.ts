"use client";

import { create } from "zustand";

export type ToastVariant = "success" | "error" | "info" | "alert";

export type ToastItem = {
  id: string;
  message: string;
  variant: ToastVariant;
};

type ToastState = {
  items: ToastItem[];
  push: (message: string, variant?: ToastVariant) => void;
  dismiss: (id: string) => void;
};

function newId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `t-${Date.now()}`;
}

export const useToastStore = create<ToastState>((set, get) => ({
  items: [],

  push: (message, variant = "info") => {
    const id = newId();
    const item: ToastItem = { id, message, variant };
    set({ items: [...get().items, item] });
    const timeoutMs = variant === "alert" ? 12_000 : 4500;
    window.setTimeout(() => {
      get().dismiss(id);
    }, timeoutMs);
  },

  dismiss: (id) => {
    set({ items: get().items.filter((t) => t.id !== id) });
  },
}));
