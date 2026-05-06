"use client";

import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { getJwt } from "@/lib/authToken";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";
import {
  useAiChatStore,
  type AiChatMessage,
} from "@/store/useAiChatStore";

type AiChatApiResponse = {
  classified?: boolean;
  reply?: string;
  specialization?: string;
  lawyer?: { id?: string; name?: string; phone?: string } | null;
  error?: string;
};

function newId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `m-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

function buildHistoryBeforeUserMessage(
  messages: AiChatMessage[],
): { role: string; parts: { text: string }[] }[] {
  if (messages.length <= 1) return [];
  return messages.slice(0, -1).map((msg) => ({
    role: msg.role === "assistant" ? "model" : "user",
    parts: [{ text: msg.content }],
  }));
}

function formatAssistantReply(data: AiChatApiResponse): string {
  const base =
    typeof data.reply === "string" && data.reply.trim().length > 0
      ? data.reply.trim()
      : "Sorry, I could not generate a response.";

  if (data.classified && data.lawyer?.name) {
    const phone = data.lawyer.phone ? ` · ${data.lawyer.phone}` : "";
    return `${base}\n\n— Matching online lawyer: ${data.lawyer.name}${phone}`;
  }
  if (data.classified && data.specialization) {
    return `${base}\n\n— Classified: ${data.specialization}. No matching online lawyer is available right now.`;
  }
  return base;
}

export function GlobalAiOverlay() {
  const isOpen = useAiChatStore((s) => s.isOpen);
  const messages = useAiChatStore((s) => s.messages);
  const isLoading = useAiChatStore((s) => s.isLoading);
  const toggleChat = useAiChatStore((s) => s.toggleChat);
  const addMessage = useAiChatStore((s) => s.addMessage);
  const setLoading = useAiChatStore((s) => s.setLoading);
  const clearChat = useAiChatStore((s) => s.clearChat);

  const [draft, setDraft] = useState("");
  const [errorBanner, setErrorBanner] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = useCallback(() => {
    const el = scrollRef.current;
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  }, []);

  useLayoutEffect(() => {
    scrollToBottom();
  }, [messages, isLoading, isOpen, scrollToBottom]);

  useEffect(() => {
    if (isOpen) {
      inputRef.current?.focus();
    }
  }, [isOpen]);

  const send = useCallback(async () => {
    const text = draft.trim();
    if (!text || isLoading) return;

    const token = getJwt();
    if (!token) {
      setErrorBanner("Sign in to use the legal assistant.");
      return;
    }

    setErrorBanner(null);
    const userMessage: AiChatMessage = {
      id: newId(),
      role: "user",
      content: text,
    };
    addMessage(userMessage);
    setDraft("");
    setLoading(true);

    const history = buildHistoryBeforeUserMessage(
      useAiChatStore.getState().messages,
    );

    try {

      const res = await fetch(apiUrl("/api/ai/chat"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
          ...tunnelBypassHeaders(),
        },
        body: JSON.stringify({
          message: text,
          history,
          lang: "he",
        }),
      });

      const data: AiChatApiResponse = await res.json().catch(() => ({}));

      if (!res.ok) {
        const errText =
          typeof data.error === "string"
            ? data.error
            : `Request failed (${res.status})`;
        throw new Error(errText);
      }

      const assistantMessage: AiChatMessage = {
        id: newId(),
        role: "assistant",
        content: formatAssistantReply(data),
      };
      addMessage(assistantMessage);
    } catch (e) {
      const msg =
        e instanceof Error ? e.message : "Something went wrong. Try again.";
      addMessage({
        id: newId(),
        role: "assistant",
        content: `Sorry — ${msg}`,
      });
    } finally {
      setLoading(false);
    }
  }, [addMessage, draft, isLoading, setLoading]);

  const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      void send();
    }
  };

  return (
    <>
      {!isOpen && (
        <button
          type="button"
          onClick={toggleChat}
          className="fixed bottom-4 right-4 z-50 flex h-14 w-14 items-center justify-center rounded-full bg-blue-600 text-white shadow-lg shadow-blue-900/30 transition hover:bg-blue-500 focus:outline-none focus-visible:ring-4 focus-visible:ring-blue-400/50 active:scale-95"
          aria-label="Open VETO AI Assistant"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            className="h-7 w-7"
            aria-hidden
          >
            <path
              fillRule="evenodd"
              d="M4.848 2.771A49.144 49.144 0 0112 2.25c2.43 0 4.817.178 7.152.52 1.978.292 3.348 2.023 3.348 3.97v6.02c0 1.946-1.37 3.678-3.348 3.97a48.901 48.901 0 01-3.476.324.25.25 0 00-.155.07l-2.525 2.52a.75.75 0 01-1.257.555l-1.204-1.204c-.29.092-.585.178-.888.258-.813.206-1.65.308-2.496.308-2.43 0-4.817-.178-7.152-.52C2.958 19.21 1.5 17.478 1.5 15.532V9.512c0-1.946 1.458-3.678 3.348-3.97zM12 3.75c-2.344 0-4.688.173-7.02.505-.75.11-1.25.762-1.25 1.257v6.02c0 .495.5 1.147 1.25 1.257 2.305.332 4.65.505 7.02.505s4.715-.173 7.02-.505c.75-.11 1.25-.762 1.25-1.257V5.512c0-.495-.5-1.147-1.25-1.257A49.138 49.138 0 0012 3.75z"
              clipRule="evenodd"
            />
          </svg>
        </button>
      )}

      {isOpen && (
        <div
          className="fixed z-50 flex max-h-[calc(100dvh-1rem)] flex-col overflow-hidden rounded-t-2xl border border-slate-200 bg-white shadow-2xl max-sm:inset-x-0 max-sm:bottom-0 max-sm:top-12 max-sm:w-full sm:bottom-20 sm:right-4 sm:top-auto sm:h-[500px] sm:w-96 sm:rounded-2xl"
          role="dialog"
          aria-modal="false"
          aria-label="VETO AI Assistant"
        >
          <header className="flex shrink-0 items-center justify-between border-b border-slate-100 bg-slate-50 px-4 py-3">
            <div>
              <h2 className="text-sm font-semibold text-slate-900">
                VETO AI Assistant
              </h2>
              <p className="text-xs text-slate-500">
                General legal information — not formal advice
              </p>
            </div>
            <div className="flex items-center gap-1">
              {messages.length > 0 && (
                <button
                  type="button"
                  onClick={clearChat}
                  className="rounded-lg px-2 py-1 text-xs font-medium text-slate-600 hover:bg-slate-200/80"
                >
                  Clear
                </button>
              )}
              <button
                type="button"
                onClick={toggleChat}
                className="rounded-lg p-2 text-slate-600 hover:bg-slate-200/80"
                aria-label="Close assistant"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  className="h-5 w-5"
                >
                  <path d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </header>

          {errorBanner && (
            <div className="shrink-0 border-b border-amber-100 bg-amber-50 px-3 py-2 text-xs text-amber-900">
              {errorBanner}
            </div>
          )}

          <div
            ref={scrollRef}
            className="min-h-0 flex-1 space-y-3 overflow-y-auto scroll-smooth bg-white px-3 py-3"
          >
            {messages.length === 0 && !isLoading && (
              <p className="rounded-xl bg-slate-100 px-3 py-2 text-sm text-slate-600">
                Ask a legal question or paste text for a short summary. Press
                Enter to send; Shift+Enter for a new line.
              </p>
            )}

            {messages.map((m) => (
              <div
                key={m.id}
                className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[85%] whitespace-pre-wrap rounded-2xl px-3 py-2 text-sm leading-relaxed ${
                    m.role === "user"
                      ? "bg-blue-600 text-white"
                      : "bg-slate-100 text-slate-800"
                  }`}
                >
                  {m.content}
                </div>
              </div>
            ))}

            {isLoading && (
              <div className="flex justify-start">
                <div
                  className="flex items-center gap-1.5 rounded-2xl bg-slate-100 px-4 py-3"
                  aria-live="polite"
                >
                  <span className="sr-only">Assistant is typing</span>
                  <span className="h-2 w-2 animate-bounce rounded-full bg-slate-400 [animation-delay:-0.2s]" />
                  <span className="h-2 w-2 animate-bounce rounded-full bg-slate-400 [animation-delay:-0.1s]" />
                  <span className="h-2 w-2 animate-bounce rounded-full bg-slate-400" />
                </div>
              </div>
            )}
          </div>

          <footer className="shrink-0 border-t border-slate-100 bg-slate-50 p-3">
            <div className="flex gap-2">
              <textarea
                ref={inputRef}
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                onKeyDown={onKeyDown}
                placeholder="Type your question…"
                rows={1}
                disabled={isLoading}
                className="max-h-32 min-h-[44px] flex-1 resize-none rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-60"
              />
              <button
                type="button"
                onClick={() => void send()}
                disabled={isLoading || !draft.trim()}
                className="shrink-0 rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Send
              </button>
            </div>
          </footer>
        </div>
      )}
    </>
  );
}
