import * as SecureStore from "expo-secure-store";
import { create } from "zustand";

const SECURE_TOKEN_KEY = "veto_jwt";

export type ApiUserRole = "user" | "lawyer" | "admin";
export type AppRole = "citizen" | "lawyer" | "admin";

export type AuthUser = {
  id: string;
  full_name: string;
  phone: string;
  role: ApiUserRole;
  appRole: AppRole;
  preferred_language?: string;
};

export function toAppRole(role: ApiUserRole): AppRole {
  return role === "user" ? "citizen" : role;
}

/** Decode JWT payload (no verify) — fallback when user snapshot is missing. */
export function decodeJwtPayload(token: string): {
  userId?: string;
  role?: ApiUserRole;
  full_name?: string;
} | null {
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const json = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return {
      userId: json.userId,
      role: json.role,
      full_name: json.full_name,
    };
  } catch {
    return null;
  }
}

type AuthState = {
  token: string | null;
  user: AuthUser | null;
  hydrated: boolean;
  setSession: (token: string, user: AuthUser) => Promise<void>;
  clearSession: () => Promise<void>;
  loadStoredToken: () => Promise<string | null>;
  hydrateFromStorage: () => Promise<void>;
};

export const useAuthStore = create<AuthState>((set, get) => ({
  token: null,
  user: null,
  hydrated: false,

  setSession: async (token, user) => {
    await SecureStore.setItemAsync(SECURE_TOKEN_KEY, token);
    await SecureStore.setItemAsync("veto_user_snapshot", JSON.stringify(user)).catch(() => {});
    set({ token, user });
  },

  clearSession: async () => {
    await SecureStore.deleteItemAsync(SECURE_TOKEN_KEY).catch(() => {});
    await SecureStore.deleteItemAsync("veto_user_snapshot").catch(() => {});
    set({ token: null, user: null });
  },

  loadStoredToken: async () => {
    try {
      return await SecureStore.getItemAsync(SECURE_TOKEN_KEY);
    } catch {
      return null;
    }
  },

  hydrateFromStorage: async () => {
    const token = await get().loadStoredToken();
    let user: AuthUser | null = null;
    if (token) {
      try {
        const raw = await SecureStore.getItemAsync("veto_user_snapshot");
        if (raw) user = JSON.parse(raw) as AuthUser;
      } catch {
        user = null;
      }
      if (!user) {
        const payload = decodeJwtPayload(token);
        if (payload?.userId && payload.role && ["user", "lawyer", "admin"].includes(payload.role)) {
          user = {
            id: payload.userId,
            full_name: payload.full_name ?? "User",
            phone: "",
            role: payload.role,
            appRole: toAppRole(payload.role),
          };
        }
      }
    }
    set({ token, user, hydrated: true });
  },
}));
