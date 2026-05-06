import Constants from "expo-constants";

const fromEnv =
  process.env.EXPO_PUBLIC_API_BASE ??
  (Constants.expoConfig?.extra?.apiBase as string | undefined);

/** API origin only — no trailing /api (axios baseURL adds /api). */
export const apiOrigin = fromEnv ?? "http://localhost:5001";

/** Socket.io origin (same host/port as API). */
export const socketOrigin =
  process.env.EXPO_PUBLIC_SOCKET_URL ??
  (Constants.expoConfig?.extra?.socketUrl as string | undefined) ??
  apiOrigin;

export const agoraAppId =
  process.env.EXPO_PUBLIC_AGORA_APP_ID ??
  (Constants.expoConfig?.extra?.agoraAppId as string | undefined) ??
  "";
