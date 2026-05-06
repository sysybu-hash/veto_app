import { io, type Socket } from "socket.io-client";
import { getJwt } from "./authToken";
import { getPublicApiOrigin, isLocaLtOrigin, tunnelBypassHeaders } from "./env";

let socket: Socket | null = null;

function buildOptions(token: string) {
  const bypass = tunnelBypassHeaders();
  const extraHeaders = Object.keys(bypass).length ? bypass : undefined;

  return {
    transports: ["polling", "websocket"],
    autoConnect: false,
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 2000,
    reconnectionDelayMax: 10000,
    timeout: 20000,
    auth: { token },
    // Polling requests from the browser can include the tunnel bypass header.
    ...(extraHeaders && {
      transportOptions: {
        polling: { extraHeaders },
      },
      extraHeaders,
    }),
  };
}

/**
 * Underlying socket.io manager; creates or returns the singleton.
 * Token is read from memory (`setSocketAuthToken`) or `localStorage` (`veto_jwt`).
 */
let cachedToken: string | null = null;

export function setSocketAuthToken(token: string | null): void {
  cachedToken = token;
  if (socket) {
    socket.auth = { token: token ?? "" };
    if (socket.connected) {
      socket.disconnect();
      socket.connect();
    }
  }
}

function resolveToken(explicit?: string | null): string | null {
  if (explicit != null) return explicit || "";
  if (cachedToken) return cachedToken;
  return getJwt();
}

export function getSocket(explicitToken?: string | null): Socket {
  const token = resolveToken(explicitToken);
  if (!token) {
    throw new Error("Socket auth: no JWT. Sign in at /login or set veto_jwt.");
  }

  if (!socket) {
    socket = io(getPublicApiOrigin(), buildOptions(token));
    if (isLocaLtOrigin()) {
      socket.io.engine.on("open", () => {
        // Debug only — never log token
        console.info("[socket] connected via", socket?.io.engine.transport.name);
      });
    }
    socket.on("connect_error", (err) => {
      console.warn("[socket] connect_error:", err.message);
    });
    socket.on("disconnect", (reason) => {
      console.info("[socket] disconnect:", reason);
    });
  } else {
    (socket.auth as { token?: string }) = { token };
  }

  return socket;
}

export function connectSocket(explicitToken?: string | null): Socket {
  const s = getSocket(explicitToken);
  if (!s.connected) {
    s.connect();
  }
  return s;
}

export function disconnectSocket(): void {
  socket?.disconnect();
  socket?.removeAllListeners();
  socket = null;
}

export function isSocketConnected(): boolean {
  return !!socket?.connected;
}
