import { getJwt } from "@/lib/authToken";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";

export { apiUrl, tunnelBypassHeaders };

/**
 * Headers for authenticated JSON requests (Bearer JWT + localtunnel bypass when needed).
 */
export function authJsonHeaders(): HeadersInit {
  const token = getJwt();
  if (!token) {
    throw new Error("Not authenticated");
  }
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
    ...tunnelBypassHeaders(),
  };
}

/**
 * Headers for authenticated multipart uploads. Do not set `Content-Type`:
 * the browser must supply the multipart boundary.
 */
export function authMultipartHeaders(): HeadersInit {
  const token = getJwt();
  if (!token) {
    throw new Error("Not authenticated");
  }
  return {
    Authorization: `Bearer ${token}`,
    ...tunnelBypassHeaders(),
  };
}
