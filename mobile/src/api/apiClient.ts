import axios from "axios";

import { apiOrigin } from "@/constants/config";
import { useAuthStore } from "@/store/authStore";

export const apiClient = axios.create({
  baseURL: `${apiOrigin.replace(/\/$/, "")}/api`,
  timeout: 30_000,
  headers: {
    "Content-Type": "application/json",
  },
});

function shouldBypassTunnel(): boolean {
  const base = apiOrigin.toLowerCase();
  return base.includes("loca.lt");
}

apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  if (shouldBypassTunnel()) {
    config.headers["bypass-tunnel-reminder"] = "true";
  }
  return config;
});
