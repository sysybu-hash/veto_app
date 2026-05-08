"use client";

import { AnimatePresence, motion } from "framer-motion";
import { Camera, MessageSquare, Mic, ScanLine, Send, X } from "lucide-react";
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
import { saveAiAnalysisAsFile } from "@/app/actions/ai-to-vault";
import { analyzeLegalDocument } from "@/app/actions/ai-vision";
import {
  btnPrimaryGold,
  btnSecondaryGlass,
  glassBubbleAssistant,
  glassBubbleUser,
  glassInput,
  glassPanel,
} from "@/lib/vetoGlass";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useToastStore } from "@/store/useToastStore";

type AiChatApiResponse = {
  classified?: boolean;
  reply?: string;
  specialization?: string;
  lawyer?: { id?: string; name?: string; phone?: string } | null;
  error?: string;
};

export type AiAssistantMode = "text" | "live" | "vision";

type SpeechRecognitionLike = {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  onresult: ((event: {
    resultIndex: number;
    results: ArrayLike<{
      isFinal: boolean;
      0: { transcript: string };
    }>;
  }) => void) | null;
  onerror: ((event: { error: string }) => void) | null;
  onend: (() => void) | null;
  start: () => void;
  stop: () => void;
};

function localeToSpeechLang(locale: string): string {
  if (locale === "he") return "he-IL";
  if (locale === "ru") return "ru-RU";
  return "en-US";
}

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

const panelTransition = {
  type: "spring" as const,
  stiffness: 420,
  damping: 32,
};

function ModeToggleButton({
  active,
  onClick,
  label,
  children,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-pressed={active}
      title={label}
      className={`rounded-lg p-2 transition-all ${
        active
          ? "bg-white/50 text-slate-900 shadow-sm ring-1 ring-[#C5A059]/40 backdrop-blur-sm"
          : "text-slate-600 hover:bg-white/25 hover:text-slate-900"
      }`}
    >
      {children}
    </button>
  );
}

export function GlobalAiOverlay() {
  const { t, locale } = useTranslation();
  const isOpen = useAiChatStore((s) => s.isOpen);
  const messages = useAiChatStore((s) => s.messages);
  const isLoading = useAiChatStore((s) => s.isLoading);
  const toggleChat = useAiChatStore((s) => s.toggleChat);
  const addMessage = useAiChatStore((s) => s.addMessage);
  const setLoading = useAiChatStore((s) => s.setLoading);
  const clearChat = useAiChatStore((s) => s.clearChat);

  const [mode, setMode] = useState<AiAssistantMode>("text");
  const [draft, setDraft] = useState("");
  const [errorBanner, setErrorBanner] = useState<string | null>(null);
  const [visionError, setVisionError] = useState<string | null>(null);
  const [visionBusy, setVisionBusy] = useState(false);
  const [vaultSaveBusy, setVaultSaveBusy] = useState(false);
  const [isLiveListening, setIsLiveListening] = useState(false);
  const [liveTranscript, setLiveTranscript] = useState("");
  const [lastVisionAnalysis, setLastVisionAnalysis] = useState<string | null>(
    null,
  );
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const recognitionRef = useRef<SpeechRecognitionLike | null>(null);

  const pushToast = useToastStore((s) => s.push);

  const isAssistantActive = isOpen || isLoading;
  const speakText = useCallback((text: string) => {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) {
      return;
    }
    const clean = text.trim();
    if (!clean) return;
    window.speechSynthesis.cancel();
    const utter = new SpeechSynthesisUtterance(clean);
    utter.lang = localeToSpeechLang(locale);
    utter.rate = 1;
    utter.pitch = 1;
    window.speechSynthesis.speak(utter);
  }, [locale]);

  const setAssistantMode = useCallback((m: AiAssistantMode) => {
    if (m !== "vision") {
      setVisionError(null);
    }
    setMode(m);
  }, []);

  const handleToggleChat = useCallback(() => {
    if (isOpen) {
      setAssistantMode("text");
      setLastVisionAnalysis(null);
    }
    toggleChat();
  }, [isOpen, setAssistantMode, toggleChat]);

  const captureAndAnalyze = useCallback(async () => {
    const video = videoRef.current;
    if (!video || video.videoWidth === 0 || visionBusy) return;

    setVisionBusy(true);
    setLastVisionAnalysis(null);
    try {
      const maxW = 1280;
      const scale = Math.min(1, maxW / video.videoWidth);
      const w = Math.floor(video.videoWidth * scale);
      const h = Math.floor(video.videoHeight * scale);
      const canvas = document.createElement("canvas");
      canvas.width = w;
      canvas.height = h;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        pushToast(t("ai.errCannotCaptureFrame"), "error");
        return;
      }
      ctx.drawImage(video, 0, 0, w, h);
      const dataUrl = canvas.toDataURL("image/jpeg", 0.82);

      const result = await analyzeLegalDocument(dataUrl);
      if (result.success) {
        setLastVisionAnalysis(result.analysis);
        addMessage({
          id: newId(),
          role: "assistant",
          content: result.analysis,
        });
        pushToast(t("ai.toastVisionAnalyzed"), "success");
      } else {
        pushToast(result.error, "error");
      }
    } catch (e) {
      pushToast(
        e instanceof Error ? e.message : t("ai.errImageAnalyze"),
        "error",
      );
    } finally {
      setVisionBusy(false);
    }
  }, [addMessage, pushToast, t, visionBusy]);

  const saveVisionToVault = useCallback(async () => {
    if (!lastVisionAnalysis?.trim() || vaultSaveBusy) return;
    setVaultSaveBusy(true);
    try {
      const res = await saveAiAnalysisAsFile(lastVisionAnalysis);
      if (res.success) {
        pushToast(t("ai.toastAnalysisSaved"), "success");
        setLastVisionAnalysis(null);
      } else {
        pushToast(res.error, "error");
      }
    } catch (e) {
      pushToast(
        e instanceof Error ? e.message : t("ai.errVaultSave"),
        "error",
      );
    } finally {
      setVaultSaveBusy(false);
    }
  }, [lastVisionAnalysis, pushToast, t, vaultSaveBusy]);

  const scrollToBottom = useCallback(() => {
    const el = scrollRef.current;
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  }, []);

  useLayoutEffect(() => {
    scrollToBottom();
  }, [messages, isLoading, isOpen, mode, scrollToBottom]);

  useEffect(() => {
    if (isOpen && mode === "text") {
      inputRef.current?.focus();
    }
  }, [isOpen, mode]);

  useEffect(() => {
    if (!isOpen || mode !== "vision") {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((t) => t.stop());
        streamRef.current = null;
      }
      if (videoRef.current) {
        videoRef.current.srcObject = null;
      }
      return;
    }

    let cancelled = false;
    let attachedVideo: HTMLVideoElement | null = null;

    (async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: { ideal: "environment" } },
          audio: false,
        });
        if (cancelled) {
          stream.getTracks().forEach((t) => t.stop());
          return;
        }
        streamRef.current = stream;
        const el = videoRef.current;
        if (el) {
          attachedVideo = el;
          el.srcObject = stream;
          await el.play().catch(() => {});
        }
      } catch (e) {
        if (!cancelled) {
          setVisionError(
            e instanceof Error ? e.message : t("ai.cameraStartFail"),
          );
        }
      }
    })();

    return () => {
      cancelled = true;
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((t) => t.stop());
        streamRef.current = null;
      }
      if (attachedVideo) {
        attachedVideo.srcObject = null;
      }
    };
  }, [isOpen, mode, t]);

  const sendMessage = useCallback(async (
    rawText: string,
    opts?: { speakResponse?: boolean },
  ) => {
    const text = rawText.trim();
    if (!text || isLoading) return;

    const token = getJwt();
    if (!token) {
      setErrorBanner(t("ai.signInBanner"));
      return;
    }

    setErrorBanner(null);
    const userMessage: AiChatMessage = {
      id: newId(),
      role: "user",
      content: text,
    };
    addMessage(userMessage);
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
          lang: locale,
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
      if (opts?.speakResponse) {
        speakText(assistantMessage.content);
      }
    } catch (e) {
      const msg =
        e instanceof Error ? e.message : t("ai.errChatFallback");
      addMessage({
        id: newId(),
        role: "assistant",
        content: `${t("ai.replySorryPrefix")}${msg}`,
      });
    } finally {
      setLoading(false);
    }
  }, [addMessage, isLoading, locale, setLoading, speakText, t]);

  const send = useCallback(async () => {
    await sendMessage(draft);
    setDraft("");
  }, [draft, sendMessage]);

  const stopLiveListening = useCallback(() => {
    const rec = recognitionRef.current;
    if (rec) {
      rec.stop();
    }
    recognitionRef.current = null;
    setIsLiveListening(false);
  }, []);

  const startLiveListening = useCallback(() => {
    const token = getJwt();
    if (!token) {
      setErrorBanner(t("ai.signInBanner"));
      return;
    }
    if (typeof window === "undefined") return;
    const browserWindow = window as Window & {
      SpeechRecognition?: new () => SpeechRecognitionLike;
      webkitSpeechRecognition?: new () => SpeechRecognitionLike;
    };
    const SpeechCtor =
      browserWindow.SpeechRecognition ?? browserWindow.webkitSpeechRecognition;
    if (!SpeechCtor) {
      pushToast(t("ai.errLiveNotSupported"), "error");
      return;
    }
    if (recognitionRef.current) {
      stopLiveListening();
    }

    const recognition = new SpeechCtor();
    recognition.lang = localeToSpeechLang(locale);
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.onresult = (event) => {
      let finalText = "";
      let interim = "";
      for (let i = event.resultIndex; i < event.results.length; i += 1) {
        const part = event.results[i]?.[0]?.transcript?.trim() ?? "";
        if (!part) continue;
        if (event.results[i].isFinal) {
          finalText += `${part} `;
        } else {
          interim += `${part} `;
        }
      }
      setLiveTranscript((finalText || interim).trim());
      const finalized = finalText.trim();
      if (finalized) {
        void sendMessage(finalized, { speakResponse: true });
      }
    };
    recognition.onerror = (event) => {
      if (event.error === "not-allowed") {
        pushToast(t("ai.errLivePermission"), "error");
      } else {
        pushToast(t("ai.errLiveCapture"), "error");
      }
      stopLiveListening();
    };
    recognition.onend = () => {
      recognitionRef.current = null;
      setIsLiveListening(false);
    };

    recognitionRef.current = recognition;
    setLiveTranscript("");
    setIsLiveListening(true);
    recognition.start();
  }, [locale, pushToast, sendMessage, stopLiveListening, t]);

  useEffect(() => {
    if (mode !== "live" && recognitionRef.current) {
      stopLiveListening();
    }
  }, [mode, stopLiveListening]);

  const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      void send();
    }
  };

  const statusDot =
    mode === "text"
      ? "bg-[#C5A059] shadow-[0_0_8px_rgba(197,160,89,0.5)]"
      : "animate-pulse bg-red-500 shadow-[0_0_10px_rgba(239,68,68,0.55)]";

  const modeHint =
    mode === "text"
      ? t("ai.modeHintText")
      : mode === "live"
        ? t("ai.modeHintLive")
        : t("ai.modeHintVision");

  return (
    <div className="pointer-events-none fixed inset-0 z-50">
      <AnimatePresence>
        {!isOpen && (
          <motion.button
            key="ai-fab"
            type="button"
            suppressHydrationWarning
            initial={{ opacity: 0, scale: 0.85 }}
            animate={{ opacity: 1, scale: 1 }}
            whileHover={{ scale: 1.08 }}
            whileTap={{ scale: 0.92 }}
            onClick={handleToggleChat}
            className="pointer-events-auto fixed bottom-32 start-8 flex h-16 w-16 items-center justify-center rounded-full border-2 border-[#C5A059]/80 bg-slate-950 text-[#C5A059] shadow-[0_0_30px_rgba(197,160,89,0.35)] focus:outline-none focus-visible:ring-4 focus-visible:ring-[#C5A059]/45 sm:bottom-8"
            aria-label={t("ai.openAssistant")}
          >
            <motion.span
              aria-hidden
              className="pointer-events-none absolute inset-0 rounded-full bg-[#C5A059] opacity-20"
              animate={
                isAssistantActive
                  ? { scale: [1, 1.22, 1], opacity: [0.2, 0.38, 0.2] }
                  : { scale: 1, opacity: 0.2 }
              }
              transition={
                isAssistantActive
                  ? { duration: 2, repeat: Infinity, ease: "easeInOut" }
                  : { duration: 0.2 }
              }
            />
            <svg
              aria-hidden
              viewBox="0 0 64 64"
              className="relative z-[1] h-11 w-11 overflow-visible"
              fill="none"
            >
              <path
                d="M31.5 9.5 36 24.4l14.5 5.1L36 34.6l-4.5 14.9L27 34.6l-14.5-5.1L27 24.4 31.5 9.5Z"
                stroke="currentColor"
                strokeWidth="4"
                strokeLinejoin="round"
                fill="rgba(197,160,89,0.16)"
              />
              <path
                d="M48 8.5 50 15l6.5 2-6.5 2-2 6.5-2-6.5-6.5-2 6.5-2 2-6.5Z"
                stroke="currentColor"
                strokeWidth="2.6"
                strokeLinejoin="round"
                fill="rgba(197,160,89,0.2)"
              />
              <path
                d="M14 41.5 15.7 47l5.3 1.8-5.3 1.7L14 56l-1.7-5.5L7 48.8l5.3-1.8L14 41.5Z"
                stroke="currentColor"
                strokeWidth="2.6"
                strokeLinejoin="round"
                fill="rgba(197,160,89,0.2)"
              />
              <circle cx="49" cy="47" r="2.4" fill="currentColor" opacity="0.8" />
              <circle cx="14" cy="14" r="2" fill="currentColor" opacity="0.65" />
            </svg>
          </motion.button>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            key="ai-panel"
            role="dialog"
            aria-modal="false"
            aria-label={t("ai.title")}
            initial={{ opacity: 0, y: 24, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.96 }}
            transition={panelTransition}
            style={{
              height:
                mode === "text"
                  ? "min(600px, calc(100dvh - 7rem))"
                  : "min(520px, calc(100dvh - 7rem))",
            }}
            className={`pointer-events-auto fixed bottom-28 flex max-h-[calc(100dvh-6rem)] w-[min(calc(100%-2rem),450px)] max-w-[450px] flex-col overflow-hidden max-sm:inset-x-4 sm:start-8 sm:end-auto ${glassPanel} shadow-2xl`}
          >
            <header className="flex shrink-0 flex-wrap items-center justify-between gap-2 border-b border-white/40 bg-white/25 px-3 py-3 backdrop-blur-md sm:gap-3 sm:px-4">
              <div className="flex min-w-0 flex-1 items-center gap-2 sm:flex-initial sm:gap-3">
                <span
                  className={`h-2.5 w-2.5 shrink-0 rounded-full ${statusDot}`}
                  aria-hidden
                />
                <div className="min-w-0">
                  <h2 className="font-frank text-sm font-black tracking-tight text-slate-900 sm:text-base">
                    {t("ai.title")}
                  </h2>
                  <p className="truncate text-xs text-slate-600">{modeHint}</p>
                </div>
              </div>

              <div
                className="flex items-center gap-1 rounded-xl border border-white/40 bg-white/20 p-1 backdrop-blur-md"
                role="group"
                aria-label={t("ai.modePickerAria")}
              >
                <ModeToggleButton
                  active={mode === "text"}
                  onClick={() => setAssistantMode("text")}
                  label={t("ai.modeText")}
                >
                  <MessageSquare className="h-[18px] w-[18px]" aria-hidden />
                </ModeToggleButton>
                <ModeToggleButton
                  active={mode === "live"}
                  onClick={() => setAssistantMode("live")}
                  label={t("ai.modeLiveVoice")}
                >
                  <Mic className="h-[18px] w-[18px]" aria-hidden />
                </ModeToggleButton>
                <ModeToggleButton
                  active={mode === "vision"}
                  onClick={() => setAssistantMode("vision")}
                  label={t("ai.modeVisionCamera")}
                >
                  <Camera className="h-[18px] w-[18px]" aria-hidden />
                </ModeToggleButton>
              </div>

              <div className="flex shrink-0 items-center gap-1">
                {mode === "text" && messages.length > 0 && (
                  <button
                    type="button"
                    onClick={clearChat}
                    className={`rounded-lg px-2 py-1 text-xs font-medium ${btnSecondaryGlass}`}
                  >
                    {t("ai.clear")}
                  </button>
                )}
                <button
                  type="button"
                  onClick={handleToggleChat}
                  className={`rounded-full p-2 text-slate-700 hover:bg-white/30 ${btnSecondaryGlass} border-transparent`}
                  aria-label={t("ai.close")}
                >
                  <X className="h-5 w-5" aria-hidden />
                </button>
              </div>
            </header>

            {errorBanner && (
              <div className="shrink-0 border-b border-amber-300/60 bg-amber-100/50 px-3 py-2 text-xs text-amber-950 backdrop-blur-sm">
                {errorBanner}
              </div>
            )}

            <div className="relative min-h-0 flex-1">
              <AnimatePresence mode="wait">
                {mode === "text" && (
                  <motion.div
                    key="mode-text"
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 10 }}
                    transition={{ duration: 0.2 }}
                    className="absolute inset-0 flex min-h-0 flex-col"
                  >
                    <div
                      ref={scrollRef}
                      className="min-h-0 flex-1 space-y-3 overflow-y-auto scroll-smooth bg-white/15 px-3 py-3 backdrop-blur-sm"
                    >
                      {messages.length === 0 && !isLoading && (
                        <p
                          className={`px-3 py-3 text-sm leading-relaxed ${glassBubbleAssistant}`}
                        >
                          {t("ai.assistantWelcome")}
                        </p>
                      )}

                      {messages.map((m) => (
                        <div
                          key={m.id}
                          className={`flex w-full ${m.role === "user" ? "justify-end" : "justify-start"}`}
                        >
                          <div
                            className={`max-w-[85%] whitespace-pre-wrap px-3 py-2 text-sm leading-relaxed ${
                              m.role === "user"
                                ? glassBubbleUser
                                : glassBubbleAssistant
                            }`}
                          >
                            {m.content}
                          </div>
                        </div>
                      ))}

                      {isLoading && (
                        <div className="flex justify-start">
                          <div
                            className={`flex items-center gap-1.5 px-4 py-3 ${glassBubbleAssistant}`}
                            aria-live="polite"
                          >
                            <span className="sr-only">{t("ai.srTyping")}</span>
                            <span className="h-2 w-2 animate-bounce rounded-full bg-slate-700 [animation-delay:-0.2s]" />
                            <span className="h-2 w-2 animate-bounce rounded-full bg-slate-700 [animation-delay:-0.1s]" />
                            <span className="h-2 w-2 animate-bounce rounded-full bg-slate-700" />
                          </div>
                        </div>
                      )}
                    </div>
                  </motion.div>
                )}

                {mode === "live" && (
                  <motion.div
                    key="mode-live"
                    initial={{ opacity: 0, x: 10 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -10 }}
                    transition={{ duration: 0.2 }}
                    className="absolute inset-0 flex min-h-0 flex-col items-center justify-center gap-10 bg-white/15 px-4 text-center backdrop-blur-sm"
                  >
                    <div
                      className="flex h-28 items-end justify-center gap-1.5"
                      aria-hidden
                    >
                      {[1, 2, 3, 4, 5, 6, 7].map((i) => (
                        <motion.div
                          key={i}
                          animate={{ height: [28, 84, 28] }}
                          transition={{
                            repeat: Infinity,
                            duration: 0.5,
                            delay: i * 0.05,
                            ease: "easeInOut",
                          }}
                          className="w-2.5 rounded-full bg-[#C5A059] shadow-[0_0_20px_rgba(197,160,89,0.35)]"
                        />
                      ))}
                    </div>
                    <div className="max-w-xs">
                      <p className="font-frank text-3xl font-black text-slate-900">
                        {t("ai.geminiLive")}
                      </p>
                      <p className="mt-2 text-sm font-medium italic text-slate-600">
                        {isLiveListening
                          ? t("ai.liveListening")
                          : t("ai.liveAnalyzing")}
                      </p>
                      <p className="mt-2 truncate text-xs text-slate-600">
                        {liveTranscript || t("ai.liveTranscriptPlaceholder")}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={isLiveListening ? stopLiveListening : startLiveListening}
                      className={`px-4 py-2 text-sm font-bold ${btnPrimaryGold}`}
                    >
                      {isLiveListening ? t("ai.liveStop") : t("ai.liveStart")}
                    </button>
                  </motion.div>
                )}

                {mode === "vision" && (
                  <motion.div
                    key="mode-vision"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.2 }}
                    className="absolute inset-0 flex min-h-0 flex-col gap-3 overflow-hidden p-3"
                  >
                    <div
                      className="relative w-full overflow-hidden rounded-3xl border-2 border-[#C5A059]/50 bg-black/80 shadow-[0_0_24px_rgba(197,160,89,0.2)]"
                      style={{ aspectRatio: "16 / 9" }}
                    >
                      <video
                        ref={videoRef}
                        className="h-full w-full object-cover"
                        autoPlay
                        playsInline
                        muted
                      />

                      {visionError && (
                        <div className="absolute inset-0 flex items-center justify-center bg-black/70 p-4 text-center text-sm text-white">
                          {visionError}
                        </div>
                      )}

                      {!visionError && (
                        <>
                          <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
                            <span className="text-[10px] font-bold tracking-widest text-white/25 sm:text-xs">
                              {t("ai.cameraFeed")}
                            </span>
                          </div>

                          <motion.div
                            aria-hidden
                            animate={{ top: ["0%", "100%", "0%"] }}
                            transition={{
                              repeat: Infinity,
                              duration: 3,
                              ease: "linear",
                            }}
                            className="pointer-events-none absolute inset-x-0 z-10 h-px bg-linear-to-r from-transparent via-[#C5A059] to-transparent shadow-[0_0_15px_#C5A059]"
                          />

                          <div className="absolute bottom-3 end-3 flex items-center gap-2">
                            <span className="h-2.5 w-2.5 shrink-0 animate-pulse rounded-full bg-red-500" />
                            <span className="text-[10px] font-black tracking-widest text-white">
                              {t("ai.visionAnalyzing")}
                            </span>
                          </div>
                        </>
                      )}
                    </div>

                    <p className="rounded-xl border border-white/40 bg-white/25 px-3 py-2 text-center text-xs font-bold text-slate-700 backdrop-blur-md">
                      {t("ai.visionHint")}
                    </p>
                    <button
                      type="button"
                      disabled={
                        !!visionError || visionBusy || !getJwt()
                      }
                      onClick={() => void captureAndAnalyze()}
                      className={`flex w-full items-center justify-center gap-2 py-3 text-sm font-bold ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50 ${visionBusy ? "animate-pulse" : ""}`}
                    >
                      <ScanLine className="h-5 w-5 shrink-0" aria-hidden />
                      {visionBusy ? t("ai.analyzingFrame") : t("ai.captureAnalyze")}
                    </button>
                    {lastVisionAnalysis?.trim() ? (
                      <button
                        type="button"
                        disabled={vaultSaveBusy}
                        onClick={() => void saveVisionToVault()}
                        className={`flex w-full items-center justify-center gap-2 py-3 text-sm font-bold ${btnSecondaryGlass} disabled:cursor-not-allowed disabled:opacity-50`}
                      >
                        {vaultSaveBusy ? t("ai.savingVault") : t("ai.saveVault")}
                      </button>
                    ) : null}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            <AnimatePresence>
              {mode === "text" && (
                <motion.footer
                  key="text-footer"
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 8 }}
                  transition={{ duration: 0.2 }}
                  className="shrink-0 border-t border-white/40 bg-white/30 p-3 backdrop-blur-md"
                >
                  <div className="flex gap-2">
                    <textarea
                      ref={inputRef}
                      value={draft}
                      onChange={(e) => setDraft(e.target.value)}
                      onKeyDown={onKeyDown}
                      placeholder={t("ai.placeholder")}
                      rows={1}
                      disabled={isLoading}
                      className={`max-h-32 min-h-[44px] flex-1 resize-none ${glassInput} disabled:opacity-60`}
                    />
                    <button
                      type="button"
                      onClick={() => void send()}
                      disabled={isLoading || !draft.trim()}
                      className={`flex h-12 w-12 shrink-0 items-center justify-center ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-50`}
                      aria-label={t("ai.send")}
                    >
                      <Send className="h-[18px] w-[18px]" aria-hidden />
                    </button>
                  </div>
                </motion.footer>
              )}
            </AnimatePresence>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
