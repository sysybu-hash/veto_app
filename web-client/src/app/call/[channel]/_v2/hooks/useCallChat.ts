"use client";

import { useCallback, useEffect, useState } from "react";
import { apiUrl, authFetch } from "@/api/apiClient";
import { connectSocket } from "@/lib/socketClient";

export type ChatMessage = {
  id: string;
  text: string;
  authorRole: "user" | "lawyer";
  authorIsMe: boolean;
  ts: number;
};

type RawHistory = {
  messages?: Array<{
    _id?: string;
    text?: string;
    author_role?: "user" | "lawyer";
    author_id?: string;
    ts?: string;
  }>;
};

type Role = "user" | "lawyer";

/**
 * Persistent in-call chat — history is read from /chat-history once on
 * mount, then live additions stream over the existing socket. Sending a
 * message goes through the new POST endpoint so it survives a reload.
 */
export function useCallChat(opts: {
  eventId: string | null;
  myUserId: string;
  myRole: Role;
}) {
  const { eventId, myUserId, myRole } = opts;
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Hydrate from server on mount.
  useEffect(() => {
    if (!eventId) return;
    let cancelled = false;
    queueMicrotask(() => {
      if (cancelled) return;
      setLoading(true);
    });
    void (async () => {
      try {
        const res = await authFetch(
          apiUrl(`/api/calls/${eventId}/chat-history`),
        );
        if (!res.ok) return;
        const data = (await res.json()) as RawHistory;
        if (cancelled) return;
        const hydrated: ChatMessage[] = (data.messages ?? []).map((m, i) => ({
          id: String(m._id ?? `hist-${i}-${m.ts ?? ""}`),
          text: String(m.text ?? ""),
          authorRole: (m.author_role ?? "user") as Role,
          authorIsMe: String(m.author_id ?? "") === myUserId,
          ts: m.ts ? Date.parse(m.ts) || Date.now() : Date.now(),
        }));
        setMessages(hydrated);
      } catch {
        /* leave empty */
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [eventId, myUserId]);

  // Stream live additions.
  useEffect(() => {
    if (!eventId) return undefined;
    let sock;
    try {
      sock = connectSocket();
    } catch {
      return undefined;
    }

    const onChat = (raw: unknown) => {
      if (!raw || typeof raw !== "object") return;
      const p = raw as Record<string, unknown>;
      if (typeof p.text !== "string" || !p.text.trim()) return;
      const id =
        typeof p._id === "string"
          ? p._id
          : `live-${Date.now()}-${Math.random()}`;
      const authorRole: Role =
        p.author_role === "lawyer" ? "lawyer" : "user";
      const authorId = typeof p.author_id === "string" ? p.author_id : "";

      setMessages((prev) => {
        if (prev.some((m) => m.id === id)) return prev;
        return [
          ...prev,
          {
            id,
            text: p.text as string,
            authorRole,
            authorIsMe: authorId === myUserId,
            ts: typeof p.ts === "number" ? p.ts : Date.now(),
          },
        ];
      });
    };

    sock.on("call-chat-message", onChat);
    return () => {
      sock.off("call-chat-message", onChat);
    };
  }, [eventId, myUserId]);

  const send = useCallback(
    async (text: string) => {
      const trimmed = text.trim();
      if (!eventId || !trimmed) return;

      // Optimistic add — replace with server id once POST returns.
      const tempId = `tmp-${Date.now()}`;
      setMessages((prev) => [
        ...prev,
        {
          id: tempId,
          text: trimmed,
          authorRole: myRole,
          authorIsMe: true,
          ts: Date.now(),
        },
      ]);

      try {
        const res = await authFetch(
          apiUrl(`/api/calls/${eventId}/chat-message`),
          {
            method: "POST",
            body: JSON.stringify({ text: trimmed }),
          },
        );
        if (!res.ok) {
          setError(`Send failed (${res.status})`);
          return;
        }
        const data = (await res.json()) as { message?: { _id?: string } };
        const serverId = data.message?._id;
        if (serverId) {
          setMessages((prev) =>
            prev.map((m) => (m.id === tempId ? { ...m, id: serverId } : m)),
          );
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      }
    },
    [eventId, myRole],
  );

  return { messages, loading, error, send };
}
