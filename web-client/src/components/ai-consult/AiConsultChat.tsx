"use client";

import { Scale, Send } from "lucide-react";
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { getJwt } from "@/lib/authToken";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";
import { useTranslation } from "@/lib/i18n/LocaleProvider";

export type AiConsultMode = "chat" | "decode" | "generate";

type Msg = {
  id: string;
  role: "user" | "assistant";
  content: string;
};

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

function formatReply(data: AiChatApiResponse, fallback: string): string {
  const base =
    typeof data.reply === "string" && data.reply.trim().length > 0
      ? data.reply.trim()
      : fallback;
  if (data.classified && data.lawyer?.name) {
    const phone = data.lawyer.phone ? ` · ${data.lawyer.phone}` : "";
    return `${base}\n\n${data.lawyer.name}${phone}`;
  }
  if (data.classified && data.specialization) {
    return `${base}\n\n${data.specialization}`;
  }
  return base;
}

type Props = {
  onSwitchMode: (mode: AiConsultMode) => void;
};

export function AiConsultChat({ onSwitchMode }: Props) {
  const { t, locale } = useTranslation();
  const [messages, setMessages] = useState<Msg[]>(() => [
    {
      id: "welcome",
      role: "assistant",
      content: t("aiConsult.welcome"),
    },
  ]);
  const [draft, setDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  useLayoutEffect(() => {
    const el = scrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [messages, busy]);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const send = useCallback(async () => {
    const text = draft.trim();
    if (!text || busy) return;
    const token = getJwt();
    if (!token) {
      setError(t("ai.signInBanner"));
      return;
    }

    setError(null);
    setDraft("");
    const userMsg: Msg = { id: newId(), role: "user", content: text };
    setMessages((prev) => [...prev, userMsg]);
    setBusy(true);

    const history = [...messages, userMsg]
      .filter((m) => m.id !== "welcome")
      .slice(0, -1)
      .slice(-12)
      .map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      }));

    try {
      const res = await fetch(apiUrl("/api/ai/chat"), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
          ...tunnelBypassHeaders(),
        },
        body: JSON.stringify({ message: text, history, lang: locale }),
      });
      const data: AiChatApiResponse = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(
          typeof data.error === "string"
            ? data.error
            : t("aiConsult.sendFailed"),
        );
      }
      setMessages((prev) => [
        ...prev,
        {
          id: newId(),
          role: "assistant",
          content: formatReply(data, t("aiConsult.emptyReply")),
        },
      ]);
    } catch (e) {
      setMessages((prev) => [
        ...prev,
        {
          id: newId(),
          role: "assistant",
          content:
            e instanceof Error ? e.message : t("aiConsult.sendFailed"),
        },
      ]);
    } finally {
      setBusy(false);
    }
  }, [busy, draft, locale, messages, t]);

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div
        ref={scrollRef}
        className="min-h-0 flex-1 space-y-4 overflow-y-auto px-1 py-4 sm:px-2"
      >
        {messages.map((m) => (
          <div
            key={m.id}
            className={`flex items-end gap-2.5 ${
              m.role === "user" ? "justify-end" : "justify-start"
            }`}
          >
            {m.role === "assistant" ? (
              <span
                className="mb-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-veto-gold text-zinc-950 shadow-sm"
                aria-hidden
              >
                <Scale className="h-4 w-4" />
              </span>
            ) : null}
            <div
              className={`max-w-[min(100%,36rem)] whitespace-pre-wrap rounded-2xl px-4 py-3 text-sm leading-relaxed shadow-sm ${
                m.role === "user"
                  ? "rounded-ee-md bg-veto-gold text-zinc-950"
                  : "rounded-es-md border border-black/5 bg-white/90 text-primary dark:border-white/10 dark:bg-zinc-900/80"
              }`}
            >
              {m.content}
            </div>
          </div>
        ))}
        {busy ? (
          <div className="flex items-center gap-2 text-sm text-secondary">
            <span className="h-2 w-2 animate-bounce rounded-full bg-veto-gold [animation-delay:-0.2s]" />
            <span className="h-2 w-2 animate-bounce rounded-full bg-veto-gold [animation-delay:-0.1s]" />
            <span className="h-2 w-2 animate-bounce rounded-full bg-veto-gold" />
            <span className="sr-only">{t("ai.srTyping")}</span>
          </div>
        ) : null}
      </div>

      {error ? (
        <p className="mb-2 rounded-xl border border-amber-300/80 bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-950 dark:border-amber-500/40 dark:bg-amber-950/40 dark:text-amber-100">
          {error}
        </p>
      ) : null}

      <div className="shrink-0 rounded-2xl border border-black/8 bg-white/95 p-2 shadow-[0_12px_40px_-24px_rgba(15,23,42,0.45)] dark:border-white/10 dark:bg-zinc-900/90">
        <div className="flex items-end gap-2">
          <button
            type="button"
            onClick={() => void send()}
            disabled={busy || !draft.trim()}
            aria-label={t("aiConsult.send")}
            className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-veto-gold text-zinc-950 shadow-md transition hover:bg-veto-gold-light disabled:cursor-not-allowed disabled:opacity-45"
          >
            <Send className="h-5 w-5" aria-hidden />
          </button>
          <textarea
            ref={inputRef}
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                void send();
              }
            }}
            rows={1}
            disabled={busy}
            placeholder={t("aiConsult.placeholder")}
            className="max-h-32 min-h-12 flex-1 resize-none bg-transparent px-2 py-3 text-sm text-primary outline-none placeholder:text-muted disabled:opacity-60"
          />
          <div className="flex shrink-0 flex-col gap-1">
            <button
              type="button"
              onClick={() => onSwitchMode("decode")}
              className="rounded-xl border border-black/8 px-2.5 py-1.5 text-[10px] font-black text-secondary transition hover:border-veto-gold/40 hover:text-primary dark:border-white/10"
            >
              {t("aiConsult.modeDecode")}
            </button>
            <button
              type="button"
              onClick={() => onSwitchMode("generate")}
              className="rounded-xl border border-black/8 px-2.5 py-1.5 text-[10px] font-black text-secondary transition hover:border-veto-gold/40 hover:text-primary dark:border-white/10"
            >
              {t("aiConsult.modeGenerate")}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
