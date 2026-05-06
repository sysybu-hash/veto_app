import type { ApiUserRole } from "@/store/authStore";

import { apiClient } from "./apiClient";

export type VerifyOtpResponse = {
  token: string;
  user: {
    id: unknown;
    full_name: string;
    phone: string;
    role: ApiUserRole;
    preferred_language?: string;
  };
};

export async function requestOtp(phone: string) {
  const { data } = await apiClient.post<{ message: string; role?: ApiUserRole; otp?: string }>(
    "/auth/request-otp",
    { phone },
  );
  return data;
}

export async function verifyOtp(phone: string, otp: string) {
  const { data } = await apiClient.post<VerifyOtpResponse>("/auth/verify-otp", { phone, otp });
  return data;
}
