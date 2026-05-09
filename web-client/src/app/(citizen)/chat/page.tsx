"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Bot,
  Camera,
  MessageCircle,
  Mic,
  RefreshCcw,
  Search,
  Send,
  Sparkles,
  Trash2,
  UserRound,
} from "lucide-react";
import {
  deleteChatConversation,
  deleteChatMessage,
  fetchChatConversations,
  fetchChatMessages,
  fetchChatPartners,
  sendChatMessage,
  type ChatConversation,
  type ChatMessage,
  type ChatPartner,
} from "@/api/chatApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { getJwt } from "@/lib/authToken";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { btnPrimaryDark, btnSecondaryGlass, glassInput, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { useAiChatStore } from "@/store/useAiChatStore";

type Thread = {
  id: string;
  name: string;
  role: string;
  last?: string;
  lastAt?: string | null;
  unread?: number;
};

function getUserIdFromJwt(): string | null {
  const token = getJwt();
  if (!token) return null;
  try {
    const payload = JSON.parse(
      atob(token.split(".")[1]?.replace(/-/g, "+").replace(/_/g, "/") ?? ""),
    ) as { userId?: string; id?: string; _id?: string };
    return payload.userId ?? payload.id ?? payload._id ?? null;
  } catch {
    return null;
  }
}

function formatTime(iso?: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return new Intl.DateTimeFormat("he-IL", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(d);
}

function threadFromConversation(c: ChatConversation): Thread {
  return {
    id: String(c.partner_id),
    name: c.partner_name || "Unknown",
    role: c.partner_role || "user",
    last: c.last_message,
    lastAt: c.last_message_at,
    unread: c.unread_count,
  };
}

function threadFromPartner(p: ChatPartner): Thread {
  return { id: String(p.id), name: p.name || "Unknown", role: p.role || "user" };
}

export default function ChatPage() {
  const { t } = useTranslation();
  const [threads, setThreads] = useState<Thread[]>([]);
  const [active, setActive] = useState<Thread | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [draft, setDraft] = useState("");
  const [query, setQuery] = useState("");
  const [loadingThreads, setLoadingThreads] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const myUserId = useMemo(() => getUserIdFromJwt(), []);
  const openAiChat = useAiChatStore((s) => s.openChat);
  const addAiMessage = useAiChatStore((s) => s.addMessage);
  const aiMessages = useAiChatStore((s) => s.messages);

  const loadThreads = useCallback(async () => {
    setLoadingThreads(true);
    setError(null);
    try {
      const [conversations, partners] = await Promise.all([
        fetchChatConversations(),
        fetchChatPartners(),
      ]);
      const merged = new Map<string, Thread>();
      partners.map(threadFromPartner).forEach((p) => merged.set(p.id, p));
      conversations.map(threadFromConversation).forEach((c) => {
        merged.set(c.id, { ...merged.get(c.id), ...c });
      });
      const next = Array.from(merged.values()).sort((a, b) => {
        const at = a.lastAt ? Date.parse(a.lastAt) : 0;
        const bt = b.lastAt ? Date.parse(b.lastAt) : 0;
        return bt - at;
      });
      setThreads(next);
      setActive((cur) => cur && next.some((x) => x.id === cur.id) ? cur : next[0] ?? null);
    } catch (e) {
      setError(e instanceof Error ? e.message : t("chat.loadFailed"));
    } finally {
      setLoadingThreads(false);
    }
  }, [t]);

  const loadMessages = useCallback(async (thread: Thread) => {
    setLoadingMessages(true);
    setError(null);
    try {
      setMessages(await fetchChatMessages(thread.id));
    } catch (e) {
      setError(e instanceof Error ? e.message : t("chat.messagesFailed"));
      setMessages([]);
    } finally {
      setLoadingMessages(false);
    }
  }, [t]);

  useEffect(() => {
    void Promise.resolve().then(loadThreads);
  }, [loadThreads]);

  useEffect(() => {
    if (active) void Promise.resolve().then(() => loadMessages(active));
  }, [active, loadMessages]);

  const filteredThreads = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return threads;
    return threads.filter((x) =>
      `${x.name} ${x.role} ${x.last ?? ""}`.toLowerCase().includes(q),
    );
  }, [query, threads]);

  const submit = useCallback(async () => {
    const text = draft.trim();
    if (!active || !text) return;
    setBusy(true);
    setError(null);
    try {
      const message = await sendChatMessage({
        receiver_id: active.id,
        receiver_role: active.role,
        text,
      });
      setMessages((prev) => [...prev, message]);
      setDraft("");
      void loadThreads();
    } catch (e) {
      setError(e instanceof Error ? e.message : t("chat.sendFailed"));
    } finally {
      setBusy(false);
    }
  }, [active, draft, loadThreads, t]);

  const removeMessage = useCallback(async (messageId: string) => {
    setError(null);
    try {
      await deleteChatMessage(messageId);
      setMessages((prev) => prev.filter((m) => m._id !== messageId));
      void loadThreads();
    } catch (e) {
      setError(e instanceof Error ? e.message : t("chat.deleteFailed"));
    }
  }, [loadThreads, t]);

  const removeThread = useCallback(async (thread?: Thread) => {
    const target = thread ?? active;
    if (!target) return;
    const ok = window.confirm(`למחוק את כל השיחה עם ${target.name}?`);
    if (!ok) return;
    setBusy(true);
    setError(null);
    try {
      await deleteChatConversation(target.id);
      setThreads((prev) => prev.filter((x) => x.id !== target.id));
      if (active?.id === target.id) {
        setMessages([]);
        setActive(null);
      }
      void loadThreads();
    } catch (e) {
      setError(e instanceof Error ? e.message : "מחיקת השיחה נכשלה");
    } finally {
      setBusy(false);
    }
  }, [active, loadThreads]);

  const openLegalAi = useCallback(() => {
    const alreadyIntroduced = aiMessages.some((m) => m.id === "chat-ai-tools-intro");
    if (!alreadyIntroduced) {
      addAiMessage({
        id: "chat-ai-tools-intro",
        role: "assistant",
        content:
          "פתחתי עוזר AI משפטי מתוך הצ׳אט. אפשר לכתוב שאלה, לעבור למצב אודיו חי, או לפתוח מצלמה לפענוח מסמך ושמירה לכספת.",
      });
    }
    openAiChat();
  }, [addAiMessage, aiMessages, openAiChat]);

  return (
    <>
      <main className="mx-auto grid w-full max-w-6xl flex-1 gap-4 px-4 py-5 pb-28 lg:grid-cols-[340px_minmax(0,1fr)]">
        <section className={`${glassPanel} flex min-h-[260px] flex-col p-4`}>
          <div className="mb-4 flex items-start justify-between gap-3">
            <div>
              <h1 className="font-frank text-2xl font-black text-slate-100">
                {t("chat.title")}
              </h1>
              <p className="mt-1 text-sm text-slate-400">{t("chat.subtitle")}</p>
            </div>
            <div className="flex shrink-0 gap-2">
              <button
                type="button"
                onClick={openLegalAi}
                className="grid h-10 w-10 place-items-center rounded-xl border border-[#C5A059]/50 bg-slate-950 text-[#C5A059] shadow-[0_0_18px_rgba(197,160,89,0.25)]"
                aria-label="פתיחת צ׳אט AI משפטי"
                title="צ׳אט AI משפטי"
              >
                <Sparkles className="h-4 w-4" aria-hidden />
              </button>
              <button
                type="button"
                onClick={() => void loadThreads()}
                className={`grid h-10 w-10 place-items-center ${btnSecondaryGlass}`}
                aria-label={t("common.retry")}
              >
                <RefreshCcw className="h-4 w-4" aria-hidden />
              </button>
            </div>
          </div>

          <button
            type="button"
            onClick={openLegalAi}
            className="mb-3 rounded-2xl border border-[#C5A059]/45 bg-slate-950 px-4 py-3 text-start text-white shadow-[0_0_22px_rgba(15,23,42,0.18)] transition hover:bg-slate-900"
          >
            <span className="flex items-center gap-2 text-sm font-black">
              <Bot className="h-5 w-5 text-[#C5A059]" aria-hidden />
              פתח צ׳אט AI משפטי
            </span>
            <span className="mt-2 flex flex-wrap gap-2 text-[11px] font-bold text-slate-200">
              <span className="inline-flex items-center gap-1 rounded-full bg-white/10 px-2 py-1">
                <MessageCircle className="h-3.5 w-3.5" aria-hidden />
                שיחה
              </span>
              <span className="inline-flex items-center gap-1 rounded-full bg-white/10 px-2 py-1">
                <Mic className="h-3.5 w-3.5" aria-hidden />
                אודיו
              </span>
              <span className="inline-flex items-center gap-1 rounded-full bg-white/10 px-2 py-1">
                <Camera className="h-3.5 w-3.5" aria-hidden />
                פענוח מסמכים
              </span>
            </span>
          </button>

          <label className="relative mb-3 block">
            <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="חיפוש שיחה"
              className={`${glassInput} pe-3 ps-10`}
            />
          </label>

          <div className="min-h-0 flex-1 space-y-2 overflow-y-auto">
            {loadingThreads ? (
              [1, 2, 3].map((i) => (
                <div key={i} className="h-20 animate-pulse rounded-2xl bg-white/[0.03]" />
              ))
            ) : filteredThreads.length === 0 ? (
              <div className={`${glassPanelNested} p-4 text-sm text-slate-300`}>
                {t("chat.emptyThreads")}
              </div>
            ) : (
              filteredThreads.map((thread) => (
                <div
                  key={thread.id}
                  className={`w-full rounded-2xl border px-3 py-3 text-start transition ${
                    active?.id === thread.id
                      ? "border-[#C5A059] bg-[#C5A059]/20"
                      : "border-white/10 bg-white/[0.03] hover:bg-white/[0.04]"
                  }`}
                >
                  <div className="flex items-start gap-2">
                    <button
                      type="button"
                      onClick={() => setActive(thread)}
                      className="min-w-0 flex-1 text-start"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <span className="truncate text-sm font-black text-slate-100">
                          {thread.name}
                        </span>
                        {!!thread.unread && (
                          <span className="rounded-full bg-[#C5A059] px-2 py-0.5 text-[10px] font-bold text-black">
                            {thread.unread}
                          </span>
                        )}
                      </div>
                      <p className="mt-1 truncate text-xs text-slate-400">
                        {thread.last || t("chat.noMessages")}
                      </p>
                      <p className="mt-1 text-[10px] font-semibold text-slate-500">
                        {thread.role === "lawyer" ? t("chat.lawyer") : t("chat.member")}
                      </p>
                    </button>
                    <button
                      type="button"
                      onClick={() => void removeThread(thread)}
                      disabled={busy}
                      className="grid h-9 w-9 shrink-0 place-items-center rounded-xl border border-red-500/30 bg-red-500/10 text-red-300 transition hover:bg-red-500/15 disabled:opacity-50"
                      aria-label={`מחיקת שיחה עם ${thread.name}`}
                      title="מחיקת שיחה"
                    >
                      <Trash2 className="h-4 w-4" aria-hidden />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </section>

        <section className={`${glassPanel} flex min-h-[560px] flex-col overflow-hidden`}>
          {active ? (
            <>
              <header className="flex items-center justify-between gap-3 border-b border-white/10 px-5 py-4">
                <div className="flex min-w-0 items-center gap-3">
                  <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-slate-950 text-white">
                    <UserRound className="h-5 w-5" aria-hidden />
                  </div>
                  <div className="min-w-0">
                    <h2 className="truncate font-frank text-xl font-black text-slate-100">
                      {active.name}
                    </h2>
                    <p className="text-xs font-semibold text-slate-400">
                      {active.role === "lawyer" ? t("chat.lawyer") : t("chat.member")} · {messages.length} הודעות
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={openLegalAi}
                  className="grid h-10 w-10 shrink-0 place-items-center rounded-xl border border-[#C5A059]/50 bg-slate-950 text-[#C5A059]"
                  aria-label="פתיחת AI לשיחה"
                  title="AI לשיחה, אודיו ופענוח מסמכים"
                >
                  <Sparkles className="h-4 w-4" aria-hidden />
                </button>
                <button
                  type="button"
                  onClick={() => void removeThread()}
                  disabled={busy}
                  className="grid h-10 w-10 shrink-0 place-items-center rounded-xl border border-red-500/30 bg-red-500/10 text-red-300 disabled:opacity-50"
                  aria-label="מחיקת שיחה"
                >
                  <Trash2 className="h-4 w-4" aria-hidden />
                </button>
              </header>

              {error && (
                <div className="mx-5 mt-4 rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
                  {error}
                </div>
              )}

              <div className="flex-1 space-y-3 overflow-y-auto px-4 py-5">
                {loadingMessages ? (
                  <p className="text-center text-sm text-slate-400">{t("common.loading")}</p>
                ) : messages.length === 0 ? (
                  <div className={`${glassPanelNested} mx-auto grid max-w-md place-items-center gap-3 p-7 text-center text-sm text-slate-300`}>
                    <MessageCircle className="h-8 w-8 text-[#9b7430]" aria-hidden />
                    {t("chat.emptyMessages")}
                  </div>
                ) : (
                  messages.map((message) => {
                    const mine = myUserId != null && String(message.sender_id) === myUserId;
                    return (
                      <div key={message._id} className={`flex ${mine ? "justify-end" : "justify-start"}`}>
                        <div className={`max-w-[82%] rounded-2xl border px-4 py-2.5 shadow-sm ${
                          mine
                            ? "border-[#C5A059]/40 bg-[#C5A059]/20 text-slate-950"
                            : "border-white/10 bg-white/[0.05] text-slate-100"
                        }`}>
                          <p className="whitespace-pre-wrap break-words text-sm leading-relaxed">{message.text}</p>
                          <div className="mt-1 flex items-center justify-between gap-3 text-[10px] text-slate-500">
                            <span>{formatTime(message.createdAt)}</span>
                            {mine && (
                              <button type="button" onClick={() => void removeMessage(message._id)} className="font-semibold text-red-300">
                                {t("common.delete")}
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              <form className="border-t border-white/10 p-4" onSubmit={(e) => { e.preventDefault(); void submit(); }}>
                <div className="flex gap-2">
                  <textarea
                    value={draft}
                    onChange={(e) => setDraft(e.target.value)}
                    placeholder={t("chat.placeholder")}
                    rows={2}
                    className={`${glassInput} min-h-12 resize-none`}
                  />
                  <button type="submit" disabled={busy || draft.trim().length === 0} className={`grid h-12 w-12 shrink-0 place-items-center self-end ${btnPrimaryDark} disabled:opacity-50`} aria-label={t("chat.send")}>
                    <Send className="h-4 w-4" aria-hidden />
                  </button>
                </div>
              </form>
            </>
          ) : (
            <div className="flex flex-1 items-center justify-center p-6 text-center text-sm text-slate-400">
              {loadingThreads ? t("common.loading") : t("chat.pickThread")}
            </div>
          )}
        </section>
      </main>
      <CitizenBottomNav active="chat" />
    </>
  );
}
