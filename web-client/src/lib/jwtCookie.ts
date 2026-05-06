import { cookies } from "next/headers";

/** Synced from `authToken.setJwt` for server actions / RSC (SameSite=Lax, not HttpOnly). */
export const VETO_JWT_COOKIE = "veto_jwt";

export type VetoJwtPayload = {
  userId?: string;
  role?: string;
};

export function decodeJwtPayload(token: string): VetoJwtPayload | null {
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json) as VetoJwtPayload;
  } catch {
    return null;
  }
}

export async function getVetoJwtFromCookies(): Promise<string | null> {
  const jar = await cookies();
  const raw = jar.get(VETO_JWT_COOKIE)?.value;
  if (!raw) return null;
  try {
    return decodeURIComponent(raw);
  } catch {
    return raw;
  }
}

export async function getVetoUserIdFromCookies(): Promise<string | null> {
  const token = await getVetoJwtFromCookies();
  if (!token) return null;
  const p = decodeJwtPayload(token);
  return typeof p?.userId === "string" ? p.userId : null;
}

export async function getVetoRoleFromCookies(): Promise<string | null> {
  const token = await getVetoJwtFromCookies();
  if (!token) return null;
  const p = decodeJwtPayload(token);
  return typeof p?.role === "string" ? p.role : null;
}
