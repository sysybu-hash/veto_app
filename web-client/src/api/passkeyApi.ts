import {
  startAuthentication,
  startRegistration,
} from "@simplewebauthn/browser";
import { apiUrl, authFetch, tunnelBypassHeaders } from "@/api/apiClient";
import { getJwt } from "@/lib/authToken";

async function parseJsonError(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: string; message?: string };
    return data.error || data.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export function passkeysSupported(): boolean {
  return (
    typeof window !== "undefined" &&
    "PublicKeyCredential" in window &&
    !!navigator.credentials
  );
}

/** Canonical WebAuthn routes (Mission 9); `/passkeys/*` aliases remain on the server. */
const WEBAUTHN = {
  registerOptions: "/api/auth/webauthn/register-options",
  registerVerify: "/api/auth/webauthn/verify-registration",
  loginOptions: "/api/auth/webauthn/authentication-options",
  loginVerify: "/api/auth/webauthn/verify-authentication",
} as const;

export async function registerPasskey(deviceName = "Passkey"): Promise<void> {
  if (!passkeysSupported()) throw new Error("הדפדפן לא תומך ב-Passkeys.");
  const optionsRes = await authFetch(apiUrl(WEBAUTHN.registerOptions), {
    method: "POST",
    body: JSON.stringify({}),
  });
  if (!optionsRes.ok) throw new Error(await parseJsonError(optionsRes));
  const { options } = (await optionsRes.json()) as {
    options: Parameters<typeof startRegistration>[0]["optionsJSON"];
  };
  const attestation = await startRegistration({ optionsJSON: options });
  const verifyRes = await authFetch(apiUrl(WEBAUTHN.registerVerify), {
    method: "POST",
    body: JSON.stringify({ response: attestation, deviceName }),
  });
  if (!verifyRes.ok) throw new Error(await parseJsonError(verifyRes));
}

export type PasskeyLoginResult = {
  token: string;
  role: string;
  user?: {
    id?: string;
    onboarding_completed?: boolean;
    full_name?: string;
    phone?: string;
    email?: string | null;
  };
};

export async function loginWithPasskey(
  phone: string,
): Promise<PasskeyLoginResult> {
  if (!passkeysSupported()) throw new Error("הדפדפן לא תומך ב-Passkeys.");
  const optionsRes = await fetch(apiUrl(WEBAUTHN.loginOptions), {
    method: "POST",
    headers: { "Content-Type": "application/json", ...tunnelBypassHeaders() },
    body: JSON.stringify({ phone }),
  });
  if (!optionsRes.ok) throw new Error(await parseJsonError(optionsRes));
  const { options } = (await optionsRes.json()) as {
    options: Parameters<typeof startAuthentication>[0]["optionsJSON"];
  };
  const assertion = await startAuthentication({ optionsJSON: options });
  const verifyRes = await fetch(apiUrl(WEBAUTHN.loginVerify), {
    method: "POST",
    headers: { "Content-Type": "application/json", ...tunnelBypassHeaders() },
    body: JSON.stringify({ phone, response: assertion }),
  });
  if (!verifyRes.ok) throw new Error(await parseJsonError(verifyRes));
  return (await verifyRes.json()) as PasskeyLoginResult;
}

export function isLoggedIn(): boolean {
  return !!getJwt();
}
