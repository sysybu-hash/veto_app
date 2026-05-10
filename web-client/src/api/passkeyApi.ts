import { apiUrl, authFetch, tunnelBypassHeaders } from "@/api/apiClient";
import { getJwt } from "@/lib/authToken";

function base64UrlToBuffer(value: string): ArrayBuffer {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(value.length / 4) * 4, "=");
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  return bytes.buffer;
}

function bufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function decodeCreationOptions(options: PublicKeyCredentialCreationOptions): PublicKeyCredentialCreationOptions {
  return {
    ...options,
    challenge: base64UrlToBuffer(String(options.challenge)),
    user: {
      ...options.user,
      id: base64UrlToBuffer(String(options.user.id)),
    },
    excludeCredentials: options.excludeCredentials?.map((credential) => ({
      ...credential,
      id: base64UrlToBuffer(String(credential.id)),
    })),
  };
}

function decodeRequestOptions(options: PublicKeyCredentialRequestOptions): PublicKeyCredentialRequestOptions {
  return {
    ...options,
    challenge: base64UrlToBuffer(String(options.challenge)),
    allowCredentials: options.allowCredentials?.map((credential) => ({
      ...credential,
      id: base64UrlToBuffer(String(credential.id)),
    })),
  };
}

function serializeCredential(credential: PublicKeyCredential) {
  const response = credential.response;
  if (response instanceof AuthenticatorAttestationResponse) {
    return {
      id: credential.id,
      rawId: bufferToBase64Url(credential.rawId),
      type: credential.type,
      response: {
        attestationObject: bufferToBase64Url(response.attestationObject),
        clientDataJSON: bufferToBase64Url(response.clientDataJSON),
        transports: response.getTransports?.() ?? [],
      },
    };
  }
  if (response instanceof AuthenticatorAssertionResponse) {
    return {
      id: credential.id,
      rawId: bufferToBase64Url(credential.rawId),
      type: credential.type,
      response: {
        authenticatorData: bufferToBase64Url(response.authenticatorData),
        clientDataJSON: bufferToBase64Url(response.clientDataJSON),
        signature: bufferToBase64Url(response.signature),
        userHandle: response.userHandle ? bufferToBase64Url(response.userHandle) : null,
      },
    };
  }
  throw new Error("Unsupported credential response");
}

async function parseJsonError(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as { error?: string; message?: string };
    return data.error || data.message || res.statusText;
  } catch {
    return res.statusText;
  }
}

export function passkeysSupported(): boolean {
  return typeof window !== "undefined" && "PublicKeyCredential" in window && !!navigator.credentials;
}

export async function registerPasskey(deviceName = "Passkey"): Promise<void> {
  if (!passkeysSupported()) throw new Error("הדפדפן לא תומך ב-Passkeys.");
  const optionsRes = await authFetch(apiUrl("/api/auth/passkeys/register/options"), {
    method: "POST",
    body: JSON.stringify({}),
  });
  if (!optionsRes.ok) throw new Error(await parseJsonError(optionsRes));
  const { options } = (await optionsRes.json()) as { options: PublicKeyCredentialCreationOptions };
  const credential = (await navigator.credentials.create({
    publicKey: decodeCreationOptions(options),
  })) as PublicKeyCredential | null;
  if (!credential) throw new Error("לא נוצר Passkey.");
  const verifyRes = await authFetch(apiUrl("/api/auth/passkeys/register/verify"), {
    method: "POST",
    body: JSON.stringify({ response: serializeCredential(credential), deviceName }),
  });
  if (!verifyRes.ok) throw new Error(await parseJsonError(verifyRes));
}

export async function loginWithPasskey(phone: string): Promise<{ token: string; role: string }> {
  if (!passkeysSupported()) throw new Error("הדפדפן לא תומך ב-Passkeys.");
  const optionsRes = await fetch(apiUrl("/api/auth/passkeys/login/options"), {
    method: "POST",
    headers: { "Content-Type": "application/json", ...tunnelBypassHeaders() },
    body: JSON.stringify({ phone }),
  });
  if (!optionsRes.ok) throw new Error(await parseJsonError(optionsRes));
  const { options } = (await optionsRes.json()) as { options: PublicKeyCredentialRequestOptions };
  const credential = (await navigator.credentials.get({
    publicKey: decodeRequestOptions(options),
  })) as PublicKeyCredential | null;
  if (!credential) throw new Error("לא נמצא Passkey.");
  const verifyRes = await fetch(apiUrl("/api/auth/passkeys/login/verify"), {
    method: "POST",
    headers: { "Content-Type": "application/json", ...tunnelBypassHeaders() },
    body: JSON.stringify({ phone, response: serializeCredential(credential) }),
  });
  if (!verifyRes.ok) throw new Error(await parseJsonError(verifyRes));
  return (await verifyRes.json()) as { token: string; role: string };
}

export function isLoggedIn(): boolean {
  return !!getJwt();
}
