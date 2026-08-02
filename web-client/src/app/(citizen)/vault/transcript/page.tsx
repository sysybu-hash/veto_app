"use client";

import { useEffect, useState } from "react";
import { Printer } from "lucide-react";
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

  return (
    <div className="min-h-screen bg-surface-canvas px-4 py-10">
      <div
        data-print="hide"
        className="mx-auto mb-6 flex max-w-[210mm] justify-end"
      >
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

        {doc.at && (
          <p className="mb-6 text-center text-sm text-muted">
            מועד האירוע:{" "}
            {new Intl.DateTimeFormat("he-IL", {
              dateStyle: "long",
              timeStyle: "short",
            }).format(new Date(doc.at))}
          </p>
        )}

        <section className="rounded-sm border border-subtle bg-surface-sunken p-6">
          <p className="whitespace-pre-wrap break-words text-base leading-8">
            {doc.body}
          </p>
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
