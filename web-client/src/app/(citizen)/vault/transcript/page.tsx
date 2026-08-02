"use client";

import { useEffect, useMemo, useState } from "react";
import { Download, Printer } from "lucide-react";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { Button } from "@/components/ui/primitives/Button";

/** Matches the payload written by `openTranscriptDocument` in VaultPageClient. */
export const TRANSCRIPT_DOCUMENT_STORAGE_KEY = "veto_transcript_document";

type TranscriptDocument = {
  title: string;
  body: string;
  at?: string;
  fileHash?: string | null;
  digitalSeal?: string | null;
};

type TranscriptTurn = { speaker: string | null; text: string };

/**
 * Splits a transcript body into per-speaker turns. The backend prompt
 * (`call.controller.js`) asks Gemini for lines like "דובר 1: ..." /
 * "אזרח: ..." / "עורך דין: ...", but older transcripts (or an unexpected
 * model response) may have none — those fall back to a single unlabeled
 * turn rather than breaking.
 */
function parseTranscriptTurns(body: string): TranscriptTurn[] {
  const lines = body
    .split(/\n+/)
    .map((line) => line.trim())
    .filter(Boolean);
  const speakerPattern = /^([\p{L}\p{N} ]{1,24}):\s*(.*)$/u;
  const turns: TranscriptTurn[] = [];
  for (const line of lines) {
    const match = line.match(speakerPattern);
    if (match) {
      turns.push({ speaker: match[1].trim(), text: match[2].trim() });
    } else if (turns.length > 0) {
      turns[turns.length - 1].text += ` ${line}`;
    } else {
      turns.push({ speaker: null, text: line });
    }
  }
  return turns;
}

function formatEventDate(at?: string): string | null {
  if (!at) return null;
  return new Intl.DateTimeFormat("he-IL", {
    dateStyle: "long",
    timeStyle: "short",
  }).format(new Date(at));
}

/** Downloads the transcript as a real .txt file — not just the print dialog. */
function downloadTranscriptFile(doc: TranscriptDocument) {
  const eventDate = formatEventDate(doc.at);
  const lines = [
    "VETO Legal — תמלול רשמי",
    doc.title,
    eventDate ? `מועד האירוע: ${eventDate}` : "",
    "",
    doc.body,
    "",
    doc.fileHash ? `חתימת קובץ (hash): ${doc.fileHash}` : "",
    doc.digitalSeal ? `חותם דיגיטלי: ${doc.digitalSeal}` : "",
  ].filter(Boolean);

  const blob = new Blob([lines.join("\n")], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${doc.title.replace(/[\\/:*?"<>|]/g, "_")}.txt`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

/**
 * A real, printable document view for an SOS transcript — replaces the
 * previous "צפייה בתמלול" popup modal per direct user feedback ("אני רוצה
 * שהתמלול יבוצע במסמך רשמי. לא בבאנר קופץ"). Reads its content from
 * sessionStorage rather than a route param since the transcript text is
 * already decoded client-side in VaultPageClient and there's no dedicated
 * single-evidence endpoint to fetch it by id.
 */
export default function TranscriptDocumentPage() {
  const [doc, setDoc] = useState<TranscriptDocument | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    queueMicrotask(() => {
      try {
        const raw = sessionStorage.getItem(TRANSCRIPT_DOCUMENT_STORAGE_KEY);
        if (raw) setDoc(JSON.parse(raw) as TranscriptDocument);
      } catch {
        setDoc(null);
      } finally {
        setLoaded(true);
      }
    });
  }, []);

  if (loaded && !doc) {
    return (
      <div className="mx-auto flex min-h-screen max-w-2xl flex-col items-center justify-center px-4 text-center">
        <p className="text-lg font-bold text-primary">לא נמצא תמלול להצגה</p>
        <p className="mt-2 text-sm text-muted">
          חזרו לכספת הראיות ופתחו את התמלול מחדש.
        </p>
      </div>
    );
  }

  if (!doc) return null;

  return <TranscriptDocument doc={doc} />;
}

function TranscriptDocument({ doc }: { doc: TranscriptDocument }) {
  const turns = useMemo(() => parseTranscriptTurns(doc.body), [doc.body]);
  const hasSpeakers = turns.some((turn) => turn.speaker);
  const eventDate = formatEventDate(doc.at);

  return (
    <div className="min-h-screen bg-surface-canvas px-4 py-10">
      <div
        data-print="hide"
        className="mx-auto mb-6 flex max-w-[210mm] flex-wrap justify-end gap-3"
      >
        <Button
          variant="secondary"
          size="sm"
          onClick={() => downloadTranscriptFile(doc)}
          iconStart={<Download className="h-4 w-4" aria-hidden />}
        >
          הורדת קובץ טקסט
        </Button>
        <Button
          variant="secondary"
          size="sm"
          onClick={() => window.print()}
          iconStart={<Printer className="h-4 w-4" aria-hidden />}
        >
          הדפסה / שמירה כ-PDF
        </Button>
      </div>

      <article
        data-print="root"
        className="mx-auto min-h-[297mm] w-full max-w-[210mm] rounded-sm border border-subtle bg-surface-overlay p-8 text-primary shadow-xl md:p-14 print:m-0 print:max-w-none print:shadow-none"
      >
        <header className="mb-8 border-b-2 border-strong pb-4">
          <VetoBrandLogo className="h-8 w-auto max-w-[200px]" />
          <p className="mt-3 text-sm text-muted">
            תמלול רשמי · הופק בתאריך {new Date().toLocaleDateString("he-IL")}
          </p>
        </header>

        <h1 className="mb-6 text-center font-frank text-2xl font-black">
          {doc.title}
        </h1>

        {eventDate && (
          <p className="mb-6 text-center text-sm text-muted">
            מועד האירוע: {eventDate}
          </p>
        )}

        <section className="rounded-sm border border-subtle bg-surface-sunken p-6">
          {hasSpeakers ? (
            <div className="space-y-4">
              {turns.map((turn, i) => (
                <p key={i} className="text-base leading-8">
                  {turn.speaker && (
                    <span className="font-bold text-veto-gold-dark">
                      {turn.speaker}:{" "}
                    </span>
                  )}
                  <span className="whitespace-pre-wrap break-words">
                    {turn.text}
                  </span>
                </p>
              ))}
            </div>
          ) : (
            <p className="whitespace-pre-wrap break-words text-base leading-8">
              {doc.body}
            </p>
          )}
        </section>

        <footer className="mt-10 border-t border-subtle pt-4 text-xs text-muted">
          <p>מסמך זה מהווה העתק תמלול מכספת הראיות המאובטחת של VETO Legal.</p>
          {doc.fileHash && (
            <p className="mt-1 font-mono">חתימת קובץ (hash): {doc.fileHash}</p>
          )}
          {doc.digitalSeal && (
            <p className="mt-1">חותם דיגיטלי: {doc.digitalSeal}</p>
          )}
        </footer>
      </article>
    </div>
  );
}
