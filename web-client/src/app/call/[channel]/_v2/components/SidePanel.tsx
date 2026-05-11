"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { apiUrl, authMultipartFetch } from "@/api/apiClient";
import { useTrWithFallback } from "../lib/trWithFallback";
import type { ChatMessage } from "../hooks/useCallChat";
import type { TranscriptSegment } from "../hooks/useRealtimeTranscription";

type Tab = "chat" | "transcript" | "files" | "info";

type SharedFile = {
  cloud_url: string;
  mime: string | null;
  by_role: "user" | "lawyer";
  ts: string;
  original_name: string | null;
};

export function SidePanel(props: {
  open: boolean;
  onClose: () => void;
  eventId: string | null;
  messages: ChatMessage[];
  onSendChat: (text: string) => Promise<void>;
  segments: TranscriptSegment[];
  sharedFiles: SharedFile[];
  onFileUploaded: () => void;
  partnerName?: string | null;
  callType: "video" | "audio" | "chat";
}) {
  const t = useTrWithFallback();
  const [tab, setTab] = useState<Tab>("chat");

  if (!props.open) return null;

  return (
    <aside
      role="complementary"
      aria-label={t("call.v2.side.aria", "Conversation tools")}
      className="@container/side absolute inset-y-0 end-0 z-30 flex h-full w-full max-w-full flex-col border-s border-white/10 bg-slate-950/95 backdrop-blur @lg/shell:max-w-sm"
    >
      <header className="flex items-center justify-between border-b border-white/10 px-3 py-2 text-xs font-semibold text-slate-300">
        <div className="flex gap-1.5" role="tablist">
          <TabBtn id="chat" current={tab} onSelect={setTab}>
            {t("call.v2.side.chat", "Chat")}
          </TabBtn>
          <TabBtn id="transcript" current={tab} onSelect={setTab}>
            {t("call.v2.side.transcript", "Transcript")}
          </TabBtn>
          <TabBtn id="files" current={tab} onSelect={setTab}>
            {t("call.v2.side.files", "Files")}
          </TabBtn>
          <TabBtn id="info" current={tab} onSelect={setTab}>
            {t("call.v2.side.info", "Info")}
          </TabBtn>
        </div>
        <button
          type="button"
          onClick={props.onClose}
          aria-label={t("call.v2.side.close", "Close panel")}
          className="rounded-full bg-white/10 px-2 py-1 text-xs hover:bg-white/15"
        >
          ✕
        </button>
      </header>

      {tab === "chat" && (
        <ChatTab messages={props.messages} onSend={props.onSendChat} />
      )}
      {tab === "transcript" && <TranscriptTab segments={props.segments} />}
      {tab === "files" && (
        <FilesTab
          eventId={props.eventId}
          sharedFiles={props.sharedFiles}
          onUploaded={props.onFileUploaded}
        />
      )}
      {tab === "info" && (
        <InfoTab partnerName={props.partnerName} callType={props.callType} />
      )}
    </aside>
  );
}

function TabBtn({
  id,
  current,
  onSelect,
  children,
}: {
  id: Tab;
  current: Tab;
  onSelect: (id: Tab) => void;
  children: React.ReactNode;
}) {
  const active = id === current;
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={() => onSelect(id)}
      className={`rounded-full px-3 py-1 text-xs font-semibold ${
        active ? "bg-[#C5A059] text-black" : "bg-white/10 text-slate-200"
      }`}
    >
      {children}
    </button>
  );
}

function ChatTab({
  messages,
  onSend,
}: {
  messages: ChatMessage[];
  onSend: (text: string) => Promise<void>;
}) {
  const t = useTrWithFallback();
  const [draft, setDraft] = useState("");
  const scrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages.length]);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const v = draft.trim();
    if (!v) return;
    setDraft("");
    await onSend(v);
  };

  return (
    <>
      <div ref={scrollRef} className="flex-1 space-y-2 overflow-y-auto p-3">
        {messages.length === 0 ? (
          <p className="mt-10 text-center text-xs text-slate-500">
            {t("call.chatEmpty", "No messages yet — say hello.")}
          </p>
        ) : (
          messages.map((m) => (
            <div
              key={m.id}
              className={`flex ${m.authorIsMe ? "justify-end" : "justify-start"}`}
            >
              <p
                className={`max-w-[82%] whitespace-pre-wrap break-words rounded-2xl px-3 py-2 text-sm ${
                  m.authorIsMe
                    ? "bg-[#C5A059] text-black"
                    : "bg-white/10 text-white"
                }`}
              >
                {m.text}
              </p>
            </div>
          ))
        )}
      </div>
      <form className="border-t border-white/10 p-2" onSubmit={submit}>
        <div className="flex gap-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder={t("call.chatPlaceholder", "Type a message…")}
            className="min-w-0 flex-1 rounded-xl border border-white/10 bg-white/10 px-3 py-2 text-sm text-white outline-none placeholder:text-slate-500 focus:ring-2 focus:ring-[#C5A059]"
          />
          <button
            type="submit"
            disabled={!draft.trim()}
            className="rounded-xl bg-[#C5A059] px-3 py-2 text-sm font-bold text-black disabled:opacity-50"
          >
            {t("chat.send", "Send")}
          </button>
        </div>
      </form>
    </>
  );
}

function TranscriptTab({ segments }: { segments: TranscriptSegment[] }) {
  const t = useTrWithFallback();
  const scrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [segments.length]);

  return (
    <div ref={scrollRef} className="flex-1 overflow-y-auto p-3 text-sm leading-6 text-slate-200">
      {segments.length === 0 ? (
        <p className="mt-10 text-center text-xs text-slate-500">
          {t("call.v2.side.transcriptEmpty", "Transcript will appear here once enabled.")}
        </p>
      ) : (
        segments.map((s) => (
          <p
            key={s.segmentId}
            className={`mb-1 ${s.isFinal ? "text-slate-100" : "text-slate-400 italic"}`}
          >
            {s.speaker && (
              <span className="me-1 text-[11px] text-amber-300">{s.speaker}:</span>
            )}
            {s.text}
          </p>
        ))
      )}
    </div>
  );
}

function FilesTab({
  eventId,
  sharedFiles,
  onUploaded,
}: {
  eventId: string | null;
  sharedFiles: SharedFile[];
  onUploaded: () => void;
}) {
  const t = useTrWithFallback();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const uploadFile = async (file: File) => {
    if (!eventId) return;
    setBusy(true);
    setError(null);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await authMultipartFetch(
        apiUrl(`/api/calls/${eventId}/file-share`),
        { method: "POST", body: fd },
      );
      if (!res.ok) throw new Error(`Upload failed (${res.status})`);
      onUploaded();
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="flex-1 overflow-y-auto p-3">
      <label
        className={`block cursor-pointer rounded-2xl border-2 border-dashed border-white/20 bg-white/5 p-4 text-center text-sm text-slate-300 hover:border-[#C5A059] hover:bg-white/[0.08] ${busy ? "opacity-60" : ""}`}
      >
        <input
          type="file"
          className="sr-only"
          disabled={busy}
          accept="image/*,application/pdf,video/*,audio/*"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) void uploadFile(f);
            e.target.value = "";
          }}
        />
        {busy
          ? t("call.v2.side.fileUploading", "Uploading…")
          : t("call.v2.side.fileDrop", "Click to share a file (max 50 MB)")}
      </label>
      {error && (
        <p className="mt-2 rounded-lg bg-red-950/70 px-3 py-2 text-xs text-red-200">{error}</p>
      )}
      <ul className="mt-4 space-y-2">
        {sharedFiles.map((f, i) => (
          <li
            key={`${f.cloud_url}-${i}`}
            className="flex items-center justify-between rounded-xl border border-white/10 bg-white/[0.04] px-3 py-2 text-xs"
          >
            <span className="truncate text-slate-200">
              {f.original_name || f.cloud_url.split("/").pop()}
            </span>
            <a
              href={f.cloud_url}
              target="_blank"
              rel="noreferrer"
              className="ms-2 rounded-md bg-[#C5A059] px-2 py-1 text-[11px] font-bold text-black"
            >
              {t("call.v2.side.fileOpen", "Open")}
            </a>
          </li>
        ))}
        {sharedFiles.length === 0 && (
          <li className="text-center text-xs text-slate-500">
            {t("call.v2.side.filesEmpty", "No files shared yet.")}
          </li>
        )}
      </ul>
    </div>
  );
}

function InfoTab({
  partnerName,
  callType,
}: {
  partnerName: string | null | undefined;
  callType: "video" | "audio" | "chat";
}) {
  const t = useTrWithFallback();
  return (
    <dl className="flex-1 space-y-3 p-4 text-xs text-slate-300">
      <div>
        <dt className="text-[11px] font-semibold uppercase text-slate-500">
          {t("call.v2.side.partner", "Speaking with")}
        </dt>
        <dd className="text-sm text-slate-100">
          {partnerName ?? t("call.v2.side.partnerUnknown", "—")}
        </dd>
      </div>
      <div>
        <dt className="text-[11px] font-semibold uppercase text-slate-500">
          {t("call.v2.side.type", "Call type")}
        </dt>
        <dd className="text-sm text-slate-100">{callType}</dd>
      </div>
      <p className="rounded-xl bg-white/[0.04] p-3 text-[11px] leading-5 text-slate-400">
        {t(
          "call.v2.side.privacyNote",
          "Audio and video are end-to-end encrypted between you and the lawyer. Cloud recording is controlled and approved only by the citizen; the lawyer sees recording status only.",
        )}
      </p>
    </dl>
  );
}
