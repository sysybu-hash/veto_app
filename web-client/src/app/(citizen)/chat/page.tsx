"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Bot,
  Check,
  Copy,
  Edit3,
  FileText,
  FolderLock,
  MessageCircle,
  Mic,
  RefreshCcw,
  Search,
  Send,
  Settings,
  Sparkles,
  Trash2,
  UserRound,
  X,
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
import { saveAiAnalysisAsFile } from "@/app/actions/ai-to-vault";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { getJwt } from "@/lib/authToken";
import { apiUrl, tunnelBypassHeaders } from "@/lib/env";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import {
  btnPrimaryDark,
  btnSecondaryGlass,
  glassInput,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";

type Thread = {
  id: string;
  name: string;
  role: string;
  last?: string;
  lastAt?: string | null;
  unread?: number;
};

type EmbeddedAiMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  createdAt: string;
  saved?: boolean;
};

type AiChatApiResponse = {
  classified?: boolean;
  reply?: string;
  specialization?: string;
  lawyer?: { id?: string; name?: string; phone?: string } | null;
  error?: string;
};

type SpeechRecognitionLike = {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  onresult:
    | ((event: {
        resultIndex: number;
        results: ArrayLike<{
          isFinal: boolean;
          0: { transcript: string };
        }>;
      }) => void)
    | null;
  onerror: ((event: { error: string }) => void) | null;
  onend: (() => void) | null;
  start: () => void;
  stop: () => void;
};

const EMBEDDED_AI_WELCOME_ID = "embedded-ai-welcome" as const;

function buildAiWelcome(content: string): EmbeddedAiMessage {
  return {
    id: EMBEDDED_AI_WELCOME_ID,
    role: "assistant",
    content,
    createdAt: "",
  };
}

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

function newId(prefix = "m"): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
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

function buildAiHistory(messages: EmbeddedAiMessage[]) {
  return messages
    .filter((m) => m.id !== EMBEDDED_AI_WELCOME_ID && m.content.trim())
    .slice(-10)
    .map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));
}

function formatAssistantReply(data: AiChatApiResponse): string {
  const base =
    typeof data.reply === "string" && data.reply.trim().length > 0
      ? data.reply.trim()
      : "לא הצלחתי לייצר תשובה כרגע. נסו שוב בעוד רגע.";

  if (data.classified && data.lawyer?.name) {
    const phone = data.lawyer.phone ? ` · ${data.lawyer.phone}` : "";
    return `${base}\n\nהתאמה זמינה: ${data.lawyer.name}${phone}`;
  }
  if (data.classified && data.specialization) {
    return `${base}\n\nסיווג: ${data.specialization}. אין עורך דין זמין כרגע.`;
  }
  return base;
}

function localeToSpeechLang(locale: string): string {
  if (locale === "ru") return "ru-RU";
  if (locale === "en") return "en-US";
  return "he-IL";
}

export default function ChatPage() {
  const router = useRouter();
  const { t, locale } = useTranslation();
  const pushToast = useToastStore((s) => s.push);
  const [threads, setThreads] = useState<Thread[]>([]);
  const [active, setActive] = useState<Thread | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [draft, setDraft] = useState("");
  const [query, setQuery] = useState("");
  const [loadingThreads, setLoadingThreads] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [aiOpen, setAiOpen] = useState(true);
  const [aiDraft, setAiDraft] = useState("");
  const [aiBusy, setAiBusy] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);
  const [aiMessages, setAiMessages] = useState<EmbeddedAiMessage[]>(() => [
    buildAiWelcome(t("chatPage.aboutAi")),
  ]);
  const [editingAiId, setEditingAiId] = useState<string | null>(null);
  const [editingAiText, setEditingAiText] = useState("");
  const [savingAiId, setSavingAiId] = useState<string | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const myUserId = useMemo(() => getUserIdFromJwt(), []);
  const aiScrollRef = useRef<HTMLDivElement>(null);
  const recognitionRef = useRef<SpeechRecognitionLike | null>(null);

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
      setActive((cur) => (cur && next.some((x) => x.id === cur.id) ? cur : next[0] ?? null));
    } catch (e) {
      setError(e instanceof Error ? e.message : t("chat.loadFailed"));
    } finally {
      setLoadingThreads(false);
    }
  }, [t]);

  const loadMessages = useCallback(
    async (thread: Thread) => {
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
    },
    [t],
  );

  useEffect(() => {
    void Promise.resolve().then(loadThreads);
  }, [loadThreads]);

  useEffect(() => {
    if (active) void Promise.resolve().then(() => loadMessages(active));
  }, [active, loadMessages]);

  useEffect(() => {
    const el = aiScrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [aiMessages, aiBusy, aiOpen]);

  useEffect(() => {
    return () => {
      recognitionRef.current?.stop();
      recognitionRef.current = null;
    };
  }, []);

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

  const removeMessage = useCallback(
    async (messageId: string) => {
      setError(null);
      try {
        await deleteChatMessage(messageId);
        setMessages((prev) => prev.filter((m) => m._id !== messageId));
        void loadThreads();
      } catch (e) {
        setError(e instanceof Error ? e.message : t("chat.deleteFailed"));
      }
    },
    [loadThreads, t],
  );

  const removeThread = useCallback(
    async (thread?: Thread) => {
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
        setError(e instanceof Error ? e.message : t("chatPage.deleteFailed"));
      } finally {
        setBusy(false);
      }
    },
    [active, loadThreads, t],
  );

  const appendAiAssistant = useCallback((content: string) => {
    setAiMessages((prev) => [
      ...prev,
      { id: newId("a"), role: "assistant", content, createdAt: new Date().toISOString() },
    ]);
  }, []);

  const runSiteAction = useCallback(
    (text: string): boolean => {
      const clean = text.trim().toLowerCase();
      const actions: Array<{ match: string[]; path: string; reply: string }> = [
        {
          match: ["מחולל", "מסמך", "מסמכים", "generator"],
          path: "/vault/generator",
          reply: "פתחתי את מחולל המסמכים. אפשר לחזור לכאן ולהמשיך את שיחת ה-AI.",
        },
        {
          match: ["כספת", "vault"],
          path: "/vault",
          reply: "פתחתי את הכספת.",
        },
        {
          match: ["יומן", "תור", "calendar"],
          path: "/calendar",
          reply: "פתחתי את היומן.",
        },
        {
          match: ["הגדרות", "settings"],
          path: "/settings",
          reply: "פתחתי את ההגדרות.",
        },
      ];
      const action = actions.find((item) => item.match.some((word) => clean.includes(word)));
      if (!action) return false;
      appendAiAssistant(action.reply);
      router.push(action.path);
      return true;
    },
    [appendAiAssistant, router],
  );

  const buildConversationContext = useCallback(() => {
    if (!active) return "";
    const transcript = messages
      .slice(-20)
      .map((m) => {
        const mine = myUserId != null && String(m.sender_id) === myUserId;
        return `${mine ? t("chatPage.citizenLabel") : active.name}: ${m.text}`;
      })
      .join("\n");
    return transcript ? `\n\nהקשר מהשיחה הנוכחית:\n${transcript}` : "";
  }, [active, messages, myUserId, t]);

  const sendEmbeddedAi = useCallback(
    async (override?: string) => {
      const rawText = override ?? aiDraft;
      const text = rawText.trim();
      if (!text || aiBusy) return;

      const token = getJwt();
      if (!token) {
        setAiError(t("chatPage.needSignInForAi"));
        return;
      }

      setAiOpen(true);
      setAiDraft("");
      setAiError(null);

      const userMessage: EmbeddedAiMessage = {
        id: newId("u"),
        role: "user",
        content: text,
        createdAt: new Date().toISOString(),
      };
      const nextMessages = [...aiMessages, userMessage];
      setAiMessages(nextMessages);

      if (runSiteAction(text)) return;

      setAiBusy(true);
      try {
        const enrichedMessage = `${text}${buildConversationContext()}`;
        const res = await fetch(apiUrl("/api/ai/chat"), {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
            ...tunnelBypassHeaders(),
          },
          body: JSON.stringify({
            message: enrichedMessage,
            history: buildAiHistory(nextMessages),
            lang: locale,
          }),
        });

        const data: AiChatApiResponse = await res.json().catch(() => ({}));
        if (!res.ok) {
          throw new Error(typeof data.error === "string" ? data.error : `Request failed (${res.status})`);
        }
        appendAiAssistant(formatAssistantReply(data));
      } catch (e) {
        appendAiAssistant(`${t("chatPage.aiCannotCompletePrefix")}${e instanceof Error ? e.message : t("chatPage.aiUnknownError")}`);
      } finally {
        setAiBusy(false);
      }
    },
    [
      aiBusy,
      aiDraft,
      aiMessages,
      appendAiAssistant,
      buildConversationContext,
      locale,
      runSiteAction,
      t,
    ],
  );

  const saveAiMessage = useCallback(
    async (message: EmbeddedAiMessage) => {
      if (!message.content.trim() || savingAiId) return;
      setSavingAiId(message.id);
      try {
        const res = await saveAiAnalysisAsFile(message.content);
        if (res.success) {
          setAiMessages((prev) => prev.map((m) => (m.id === message.id ? { ...m, saved: true } : m)));
          pushToast(t("chatPage.toastSavedToVault"), "success");
        } else {
          pushToast(res.error, "error");
        }
      } catch (e) {
        pushToast(e instanceof Error ? e.message : t("chatPage.toastSaveFailed"), "error");
      } finally {
        setSavingAiId(null);
      }
    },
    [pushToast, savingAiId, t],
  );

  const startEditingAi = (message: EmbeddedAiMessage) => {
    setEditingAiId(message.id);
    setEditingAiText(message.content);
  };

  const commitAiEdit = () => {
    const text = editingAiText.trim();
    if (!editingAiId || !text) return;
    setAiMessages((prev) =>
      prev.map((m) => (m.id === editingAiId ? { ...m, content: text, saved: false } : m)),
    );
    setEditingAiId(null);
    setEditingAiText("");
  };

  const deleteAiMessage = (id: string) => {
    setAiMessages((prev) => prev.filter((m) => m.id !== id));
    if (editingAiId === id) {
      setEditingAiId(null);
      setEditingAiText("");
    }
  };

  const summarizeConversation = () => {
    const context = buildConversationContext();
    if (!context) {
      appendAiAssistant(t("chatPage.emptyForSummary"));
      return;
    }
    void sendEmbeddedAi(t("chatPage.aiSummaryPrompt"));
  };

  const startDictation = useCallback(() => {
    if (typeof window === "undefined") return;
    const browserWindow = window as Window & {
      SpeechRecognition?: new () => SpeechRecognitionLike;
      webkitSpeechRecognition?: new () => SpeechRecognitionLike;
    };
    const SpeechCtor = browserWindow.SpeechRecognition ?? browserWindow.webkitSpeechRecognition;
    if (!SpeechCtor) {
      pushToast(t("chatPage.speechNotSupported"), "error");
      return;
    }
    recognitionRef.current?.stop();
    const recognition = new SpeechCtor();
    recognition.lang = localeToSpeechLang(locale);
    recognition.continuous = false;
    recognition.interimResults = true;
    recognition.onresult = (event) => {
      let text = "";
      for (let i = event.resultIndex; i < event.results.length; i += 1) {
        text += `${event.results[i]?.[0]?.transcript ?? ""} `;
      }
      setAiDraft((prev) => `${prev ? `${prev} ` : ""}${text.trim()}`.trim());
    };
    recognition.onerror = () => {
      setIsRecording(false);
      pushToast(t("chatPage.speechFailed"), "error");
    };
    recognition.onend = () => {
      recognitionRef.current = null;
      setIsRecording(false);
    };
    recognitionRef.current = recognition;
    setIsRecording(true);
    recognition.start();
  }, [locale, pushToast, t]);

  const stopDictation = () => {
    recognitionRef.current?.stop();
    recognitionRef.current = null;
    setIsRecording(false);
  };

  return (
    <>
      <main className="mx-auto grid w-full max-w-7xl flex-1 gap-4 px-4 py-5 pb-28 lg:grid-cols-[310px_minmax(0,1fr)_360px]">
        <section className={`${glassPanel} flex min-h-[260px] flex-col p-4`}>
          <div className="mb-4 flex items-start justify-between gap-3">
            <div>
              <h1 className="font-frank text-2xl font-black text-slate-900">
                {t("chat.title")}
              </h1>
              <p className="mt-1 text-sm text-slate-600">{t("chat.subtitle")}</p>
            </div>
            <button
              type="button"
              onClick={() => void loadThreads()}
              className={`grid h-10 w-10 place-items-center ${btnSecondaryGlass}`}
              aria-label={t("common.retry")}
            >
              <RefreshCcw className="h-4 w-4" aria-hidden />
            </button>
          </div>

          <button
            type="button"
            onClick={() => setAiOpen(true)}
            className="mb-3 rounded-2xl border border-[#C5A059]/45 bg-slate-950 px-4 py-3 text-start text-white shadow-[0_0_22px_rgba(15,23,42,0.18)] transition hover:bg-slate-900"
          >
            <span className="flex items-center gap-2 text-sm font-black">
              <Sparkles className="h-5 w-5 text-[#C5A059]" aria-hidden />
              AI עצמאי בתוך הצ׳אט
            </span>
            <span className="mt-2 block text-xs font-semibold text-slate-200">
              שיחה, שמירה, עריכה, מחיקה ופעולות באתר.
            </span>
          </button>

          <label className="relative mb-3 block">
            <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={t("chatPage.searchPlaceholder")}
              className={`${glassInput} pe-3 ps-10`}
            />
          </label>

          <div className="min-h-0 flex-1 space-y-2 overflow-y-auto">
            {loadingThreads ? (
              [1, 2, 3].map((i) => (
                <div key={i} className="h-20 animate-pulse rounded-2xl bg-white/35" />
              ))
            ) : filteredThreads.length === 0 ? (
              <div className={`${glassPanelNested} p-4 text-sm text-slate-700`}>
                {t("chat.emptyThreads")}
              </div>
            ) : (
              filteredThreads.map((thread) => (
                <div
                  key={thread.id}
                  className={`w-full rounded-2xl border px-3 py-3 text-start transition ${
                    active?.id === thread.id
                      ? "border-[#C5A059] bg-[#C5A059]/20"
                      : "border-white/35 bg-white/35 hover:bg-white/50"
                  }`}
                >
                  <div className="flex items-start gap-2">
                    <button type="button" onClick={() => setActive(thread)} className="min-w-0 flex-1 text-start">
                      <div className="flex items-center justify-between gap-3">
                        <span className="truncate text-sm font-black text-slate-900">
                          {thread.name}
                        </span>
                        {!!thread.unread && (
                          <span className="rounded-full bg-[#C5A059] px-2 py-0.5 text-[10px] font-bold text-black">
                            {thread.unread}
                          </span>
                        )}
                      </div>
                      <p className="mt-1 truncate text-xs text-slate-600">
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
                      className="grid h-9 w-9 shrink-0 place-items-center rounded-xl border border-red-200 bg-red-50/80 text-red-700 transition hover:bg-red-100 disabled:opacity-50"
                      aria-label={`${t("chatPage.deleteConversation")} · ${thread.name}`}
                      title={t("chatPage.deleteConversation")}
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
              <header className="flex items-center justify-between gap-3 border-b border-white/35 px-5 py-4">
                <div className="flex min-w-0 items-center gap-3">
                  <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-slate-950 text-white">
                    <UserRound className="h-5 w-5" aria-hidden />
                  </div>
                  <div className="min-w-0">
                    <h2 className="truncate font-frank text-xl font-black text-slate-900">
                      {active.name}
                    </h2>
                    <p className="text-xs font-semibold text-slate-600">
                      {active.role === "lawyer" ? t("chat.lawyer") : t("chat.member")} · {messages.length} הודעות
                    </p>
                  </div>
                </div>
                <div className="flex shrink-0 gap-2">
                  <button
                    type="button"
                    onClick={() => setAiOpen(true)}
                    className="grid h-10 w-10 place-items-center rounded-xl border border-[#C5A059]/50 bg-slate-950 text-[#C5A059]"
                    aria-label={t("chatPage.openAiPane")}
                    title={t("chatPage.openAiPane")}
                  >
                    <Sparkles className="h-4 w-4" aria-hidden />
                  </button>
                  <button
                    type="button"
                    onClick={() => void removeThread()}
                    disabled={busy}
                    className="grid h-10 w-10 place-items-center rounded-xl border border-red-200 bg-red-50/70 text-red-700 disabled:opacity-50"
                    aria-label={t("chatPage.deleteConversation")}
                  >
                    <Trash2 className="h-4 w-4" aria-hidden />
                  </button>
                </div>
              </header>

              {error && (
                <div className="mx-5 mt-4 rounded-xl border border-red-300/80 bg-red-50/90 px-3 py-2 text-sm text-red-900">
                  {error}
                </div>
              )}

              <div className="flex-1 space-y-3 overflow-y-auto px-4 py-5">
                {loadingMessages ? (
                  <p className="text-center text-sm text-slate-600">{t("common.loading")}</p>
                ) : messages.length === 0 ? (
                  <div className={`${glassPanelNested} mx-auto grid max-w-md place-items-center gap-3 p-7 text-center text-sm text-slate-700`}>
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
                            : "border-white/45 bg-white/60 text-slate-900"
                        }`}>
                          <p className="whitespace-pre-wrap break-words text-sm leading-relaxed">{message.text}</p>
                          <div className="mt-1 flex items-center justify-between gap-3 text-[10px] text-slate-500">
                            <span>{formatTime(message.createdAt)}</span>
                            {mine && (
                              <button type="button" onClick={() => void removeMessage(message._id)} className="font-semibold text-red-700">
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

              <form className="border-t border-white/35 p-4" onSubmit={(e) => { e.preventDefault(); void submit(); }}>
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
            <div className="flex flex-1 items-center justify-center p-6 text-center text-sm text-slate-600">
              {loadingThreads ? t("common.loading") : t("chat.pickThread")}
            </div>
          )}
        </section>

        <section className={`${glassPanel} flex min-h-[560px] flex-col overflow-hidden`}>
          <header className="flex items-start justify-between gap-3 border-b border-white/35 px-4 py-4">
            <div>
              <p className="flex items-center gap-2 text-xs font-black uppercase tracking-wide text-[#9b7430]">
                <Sparkles className="h-4 w-4" aria-hidden />
                AI עצמאי
              </p>
              <h2 className="mt-1 font-frank text-xl font-black text-slate-900">
                עוזר משפטי בצ׳אט
              </h2>
              <p className="mt-1 text-xs text-slate-600">
                נפרד מהבועה, עם שמירה ופעולות באתר.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setAiOpen((v) => !v)}
              className={`grid h-10 w-10 place-items-center ${btnSecondaryGlass}`}
              aria-label={aiOpen ? t("chatPage.closeAiPane") : t("chatPage.openAiPaneAlt")}
            >
              {aiOpen ? <X className="h-4 w-4" aria-hidden /> : <Bot className="h-4 w-4" aria-hidden />}
            </button>
          </header>

          {aiOpen ? (
            <>
              <div className="grid grid-cols-2 gap-2 border-b border-white/35 p-3 text-xs font-bold sm:grid-cols-4 lg:grid-cols-2">
                <button type="button" onClick={summarizeConversation} className={btnSecondaryGlass}>
                  סכם שיחה
                </button>
                <button type="button" onClick={() => void sendEmbeddedAi(t("chatPage.aiDraftPrompt"))} className={btnSecondaryGlass}>
                  נסח תשובה
                </button>
                <button type="button" onClick={() => { appendAiAssistant(t("chatPage.aiOpenedDocs")); router.push("/vault/generator"); }} className={btnSecondaryGlass}>
                  <FileText className="h-4 w-4" aria-hidden />
                  מחולל
                </button>
                <button type="button" onClick={() => { appendAiAssistant(t("chatPage.aiOpenedVault")); router.push("/vault"); }} className={btnSecondaryGlass}>
                  <FolderLock className="h-4 w-4" aria-hidden />
                  כספת
                </button>
              </div>

              {aiError && (
                <div className="mx-3 mt-3 rounded-xl border border-red-300/80 bg-red-50/90 px-3 py-2 text-xs text-red-900">
                  {aiError}
                </div>
              )}

              <div ref={aiScrollRef} className="min-h-0 flex-1 space-y-3 overflow-y-auto px-3 py-4">
                {aiMessages.map((message) => (
                  <div key={message.id} className={`flex ${message.role === "user" ? "justify-end" : "justify-start"}`}>
                    <div className={`max-w-[92%] rounded-2xl border px-3 py-2 shadow-sm ${
                      message.role === "user"
                        ? "border-[#C5A059]/50 bg-[#C5A059]/20"
                        : "border-white/45 bg-white/65"
                    }`}>
                      {editingAiId === message.id ? (
                        <div className="space-y-2">
                          <textarea
                            value={editingAiText}
                            onChange={(e) => setEditingAiText(e.target.value)}
                            rows={5}
                            className={`${glassInput} min-h-28 resize-none text-sm`}
                          />
                          <div className="flex gap-2">
                            <button type="button" onClick={commitAiEdit} className="rounded-xl bg-slate-950 px-3 py-2 text-xs font-bold text-white">
                              <Check className="h-4 w-4" aria-hidden />
                            </button>
                            <button type="button" onClick={() => setEditingAiId(null)} className={btnSecondaryGlass}>
                              ביטול
                            </button>
                          </div>
                        </div>
                      ) : (
                        <>
                          <p className="whitespace-pre-wrap break-words text-sm leading-relaxed text-slate-900">
                            {message.content}
                          </p>
                          <div className="mt-2 flex flex-wrap gap-1.5 text-[11px] font-bold">
                            <button type="button" onClick={() => startEditingAi(message)} className="rounded-lg border border-white/50 bg-white/45 px-2 py-1 text-slate-700">
                              <Edit3 className="h-3.5 w-3.5" aria-hidden />
                            </button>
                            <button type="button" onClick={() => deleteAiMessage(message.id)} className="rounded-lg border border-red-200 bg-red-50 px-2 py-1 text-red-700">
                              <Trash2 className="h-3.5 w-3.5" aria-hidden />
                            </button>
                            {message.role === "assistant" && (
                              <>
                                <button type="button" onClick={() => setDraft(message.content)} className="rounded-lg border border-white/50 bg-white/45 px-2 py-1 text-slate-700">
                                  <Copy className="h-3.5 w-3.5" aria-hidden />
                                  לשיחה
                                </button>
                                <button type="button" onClick={() => void saveAiMessage(message)} disabled={savingAiId === message.id} className="rounded-lg border border-[#C5A059]/40 bg-[#C5A059]/15 px-2 py-1 text-[#75551f] disabled:opacity-60">
                                  {message.saved ? t("chatPage.aiSaved") : savingAiId === message.id ? t("chatPage.aiSaving") : t("chatPage.aiSaveToVault")}
                                </button>
                              </>
                            )}
                          </div>
                        </>
                      )}
                    </div>
                  </div>
                ))}
                {aiBusy && (
                  <div className="rounded-2xl border border-white/45 bg-white/65 px-3 py-2 text-sm text-slate-600">
                    חושב ומנסח...
                  </div>
                )}
              </div>

              <div className="border-t border-white/35 p-3">
                <div className="mb-2 flex flex-wrap gap-2 text-xs font-bold">
                  <button type="button" onClick={() => { appendAiAssistant(t("chatPage.aiOpenedSettings")); router.push("/settings"); }} className={btnSecondaryGlass}>
                    <Settings className="h-4 w-4" aria-hidden />
                    הגדרות
                  </button>
                  <Link href="/vault/generator" className={btnSecondaryGlass}>
                    <FileText className="h-4 w-4" aria-hidden />
                    מסמך חדש
                  </Link>
                  <button type="button" onClick={isRecording ? stopDictation : startDictation} className={btnSecondaryGlass}>
                    <Mic className="h-4 w-4" aria-hidden />
                    {isRecording ? t("chatPage.recordStop") : t("chatPage.recordStart")}
                  </button>
                </div>
                <form onSubmit={(e) => { e.preventDefault(); void sendEmbeddedAi(); }} className="flex gap-2">
                  <textarea
                    value={aiDraft}
                    onChange={(e) => setAiDraft(e.target.value)}
                    placeholder={t("chatPage.aiPlaceholder")}
                    rows={2}
                    className={`${glassInput} min-h-12 resize-none`}
                  />
                  <button type="submit" disabled={aiBusy || aiDraft.trim().length === 0} className={`grid h-12 w-12 shrink-0 place-items-center self-end ${btnPrimaryDark} disabled:opacity-50`} aria-label={t("chatPage.aiSend")}>
                    <Send className="h-4 w-4" aria-hidden />
                  </button>
                </form>
              </div>
            </>
          ) : (
            <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center">
              <Bot className="h-10 w-10 text-[#9b7430]" aria-hidden />
              <p className="text-sm font-bold text-slate-800">חלון ה-AI סגור.</p>
              <button type="button" onClick={() => setAiOpen(true)} className={btnPrimaryDark}>
                פתח AI בצ׳אט
              </button>
            </div>
          )}
        </section>
      </main>
      <CitizenBottomNav active="chat" />
    </>
  );
}
