"use client";

import {
  AlertCircle,
  ArrowRight,
  Download,
  FileText,
  Loader2,
  Mic,
  Printer,
  Save,
  Wand2,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useRef, useState } from "react";
import { saveEvidence } from "@/app/actions/vault";
import { uploadFile } from "@/api/vaultApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { btnPrimaryDark, btnPrimaryGold, btnSecondaryGlass, glassInput, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";

type LegalDocument = {
  title: string;
  preamble: string;
  clauses: string[];
  signatures: { role: string; name: string }[];
};

type SpeechRecognitionLike = {
  lang: string;
  interimResults: boolean;
  onstart: (() => void) | null;
  onresult: ((event: { results: ArrayLike<ArrayLike<{ transcript: string }>> }) => void) | null;
  onerror: (() => void) | null;
  onend: (() => void) | null;
  start: () => void;
};

const DOCUMENT_TYPES = [
  { id: "warning_letter", label: "מכתב התראה לפני נקיטת הליכים" },
  { id: "power_of_attorney", label: "ייפוי כוח כללי / ספציפי" },
  { id: "lease_agreement", label: "חוזה שכירות" },
  { id: "nda", label: "הסכם סודיות (NDA)" },
  { id: "employment", label: "הסכם עבודה / הודעה לעובד" },
  { id: "loan_agreement", label: "הסכם הלוואה בין פרטיים" },
  { id: "cease_and_desist", label: "מכתב דרישה לחדול מהפרה" },
  { id: "custom", label: "מסמך משפטי מותאם אישית" },
] as const;

const VAULT_CATEGORY_AI_PDF = "AI_GENERATOR_PDF";

function safePdfBasename(title: string): string {
  return title.replace(/[/\\?%*:|"<>]/g, "_").trim().slice(0, 120) || "veto-document";
}

async function sha256HexFromBlob(blob: Blob): Promise<string> {
  const buf = await blob.arrayBuffer();
  const hash = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export default function DocumentGeneratorPage() {
  const router = useRouter();
  const pushToast = useToastStore((s) => s.push);
  const documentRef = useRef<HTMLDivElement>(null);
  const [selectedType, setSelectedType] = useState<(typeof DOCUMENT_TYPES)[number]["id"]>("warning_letter");
  const [details, setDetails] = useState("");
  const [document, setDocument] = useState<LegalDocument | null>(null);
  const [errorMsg, setErrorMsg] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isRecording, setIsRecording] = useState(false);

  const selectedLabel = useMemo(
    () => DOCUMENT_TYPES.find((x) => x.id === selectedType)?.label ?? "מסמך משפטי",
    [selectedType],
  );

  const handleVoiceRecord = () => {
    const win = window as Window & {
      SpeechRecognition?: new () => SpeechRecognitionLike;
      webkitSpeechRecognition?: new () => SpeechRecognitionLike;
    };
    const SpeechCtor = win.SpeechRecognition ?? win.webkitSpeechRecognition;
    if (!SpeechCtor) {
      setErrorMsg("הדפדפן לא תומך בהכתבה קולית. אפשר להקליד את הפרטים ידנית.");
      return;
    }
    const recognition = new SpeechCtor();
    recognition.lang = "he-IL";
    recognition.interimResults = false;
    recognition.onstart = () => setIsRecording(true);
    recognition.onresult = (event) => {
      const transcript = event.results[0]?.[0]?.transcript?.trim();
      if (transcript) {
        setDetails((prev) => [prev, transcript].filter(Boolean).join(" "));
      }
    };
    recognition.onerror = () => {
      setErrorMsg("לא הצלחתי לקלוט אודיו. בדקו הרשאת מיקרופון ונסו שוב.");
      setIsRecording(false);
    };
    recognition.onend = () => setIsRecording(false);
    recognition.start();
  };

  const generateDocument = async () => {
    if (selectedType === "custom" && details.trim().length < 12) {
      setErrorMsg("למסמך מותאם אישית צריך לכתוב לפחות משפט אחד עם פרטי המקרה.");
      return;
    }

    setIsGenerating(true);
    setErrorMsg("");
    try {
      const res = await fetch("/api/generate-document", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          documentType: selectedType,
          docTypeLabel: selectedLabel,
          prompt: details,
        }),
      });
      const data = (await res.json().catch(() => ({}))) as LegalDocument & { error?: string };
      if (!res.ok || data.error) {
        throw new Error(data.error || "יצירת המסמך נכשלה");
      }
      setDocument({
        title: data.title || selectedLabel,
        preamble: data.preamble || "",
        clauses: Array.isArray(data.clauses) ? data.clauses : [],
        signatures: Array.isArray(data.signatures) ? data.signatures : [],
      });
      pushToast("המסמך נוצר. אפשר לערוך, להדפיס, להוריד או לשמור לכספת.", "success");
    } catch (e) {
      const msg = e instanceof Error ? e.message : "יצירת המסמך נכשלה";
      setErrorMsg(msg);
      pushToast(msg, "error");
    } finally {
      setIsGenerating(false);
    }
  };

  const buildPdfOptions = () => ({
    margin: 10,
    filename: `${safePdfBasename(document?.title || selectedLabel)}.pdf`,
    image: { type: "jpeg" as const, quality: 0.98 },
    html2canvas: { scale: 2, useCORS: true },
    jsPDF: { unit: "mm" as const, format: "a4" as const, orientation: "portrait" as const },
  });

  const exportPdfBlob = async (): Promise<Blob> => {
    if (!documentRef.current) throw new Error("אין מסמך לייצוא");
    const html2pdf = (await import("html2pdf.js")).default;
    return (await html2pdf().set(buildPdfOptions()).from(documentRef.current).outputPdf("blob")) as Blob;
  };

  const handleExportPDF = async () => {
    if (!documentRef.current) return;
    const html2pdf = (await import("html2pdf.js")).default;
    html2pdf().set(buildPdfOptions()).from(documentRef.current).save();
  };

  const handleExportDOCX = async () => {
    if (!document) return;
    const { AlignmentType, Document, Packer, Paragraph } = await import("docx");
    const { saveAs } = await import("file-saver");
    const doc = new Document({
      sections: [
        {
          properties: {},
          children: [
            new Paragraph({ text: document.title, heading: "Heading1", alignment: AlignmentType.CENTER }),
            new Paragraph({ text: document.preamble, spacing: { before: 300, after: 300 } }),
            ...document.clauses.map((clause, i) => new Paragraph({ text: `${i + 1}. ${clause}`, spacing: { after: 180 } })),
            new Paragraph({ text: "חתימות:", spacing: { before: 500, after: 250 } }),
            ...document.signatures.map((sig) => new Paragraph({ text: `${sig.role}: _______________________ ${sig.name || ""}`, spacing: { after: 180 } })),
          ],
        },
      ],
    });
    saveAs(await Packer.toBlob(doc), `${safePdfBasename(document.title)}.docx`);
  };

  const handleSaveToVault = async () => {
    if (!document) return;
    setIsSaving(true);
    setErrorMsg("");
    try {
      const blob = await exportPdfBlob();
      const base = safePdfBasename(document.title);
      const file = new File([blob], `${base}.pdf`, { type: "application/pdf" });
      const hash = await sha256HexFromBlob(blob);
      const uploaded = await uploadFile(file, "");
      if (!uploaded.url) throw new Error("הקובץ עלה אבל השרת לא החזיר URL");
      const saved = await saveEvidence({
        title: document.title,
        url: uploaded.url,
        hash,
        category: VAULT_CATEGORY_AI_PDF,
        isVerified: true,
      });
      if (!saved.success) throw new Error(saved.error);
      pushToast("המסמך נשמר בכספת.", "success");
      router.push("/vault");
    } catch (e) {
      const msg = e instanceof Error ? e.message : "שמירה לכספת נכשלה";
      setErrorMsg(msg);
      pushToast(msg, "error");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="flex min-h-full flex-col pb-28" dir="rtl">
      <main className="mx-auto grid w-full max-w-7xl flex-1 gap-5 px-4 py-5 lg:grid-cols-[360px_minmax(0,1fr)]">
        <aside className={`${glassPanel} h-fit p-5 lg:sticky lg:top-20`}>
          <Link href="/vault" className="mb-4 inline-flex items-center gap-2 text-sm font-bold text-slate-700 hover:text-slate-950">
            <ArrowRight className="h-4 w-4" aria-hidden />
            חזרה לכספת
          </Link>

          <h1 className="font-frank text-2xl font-black text-slate-950">מחולל מסמכים משפטיים</h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">
            בחרו סוג מסמך, הוסיפו פרטים, והמערכת תנסח טיוטה שאפשר לערוך, להוריד או לשמור לכספת.
          </p>

          <div className="mt-5 space-y-4">
            <label className="block">
              <span className="mb-1 block text-xs font-black text-slate-700">סוג מסמך</span>
              <select
                value={selectedType}
                onChange={(e) => setSelectedType(e.target.value as (typeof DOCUMENT_TYPES)[number]["id"])}
                className={glassInput}
              >
                {DOCUMENT_TYPES.map((type) => (
                  <option key={type.id} value={type.id}>{type.label}</option>
                ))}
              </select>
            </label>

            <label className="block">
              <span className="mb-1 flex items-center justify-between gap-3 text-xs font-black text-slate-700">
                פרטי המקרה
                <button
                  type="button"
                  onClick={handleVoiceRecord}
                  className={`rounded-xl p-2 transition ${isRecording ? "bg-red-100 text-red-700" : "bg-white/50 text-slate-700 hover:bg-white/80"}`}
                  title="הכתבה קולית"
                >
                  <Mic className="h-4 w-4" aria-hidden />
                </button>
              </span>
              <textarea
                value={details}
                onChange={(e) => setDetails(e.target.value)}
                placeholder="לדוגמה: שם הצדדים, תאריכים, סכומים, כתובות, מה הוסכם, מה הופר, ומה אתם רוצים שהמסמך יעשה."
                className={`${glassInput} min-h-36 resize-y leading-6`}
              />
            </label>
          </div>

          {errorMsg ? (
            <div className="mt-4 flex items-start gap-2 rounded-2xl border border-red-200 bg-red-50/90 p-3 text-sm text-red-900">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
              <span>{errorMsg}</span>
            </div>
          ) : null}

          <button
            type="button"
            onClick={() => void generateDocument()}
            disabled={isGenerating}
            className={`mt-5 flex w-full items-center justify-center gap-2 px-4 py-3 text-sm ${btnPrimaryGold} disabled:cursor-not-allowed disabled:opacity-60`}
          >
            {isGenerating ? <Loader2 className="h-5 w-5 animate-spin" aria-hidden /> : <Wand2 className="h-5 w-5" aria-hidden />}
            {isGenerating ? "מנסח מסמך..." : "נסח מסמך AI"}
          </button>

          {document ? (
            <div className={`${glassPanelNested} mt-5 p-4`}>
              <p className="text-sm font-black text-slate-900">פעולות למסמך</p>
              <div className="mt-3 grid gap-2">
                <button type="button" disabled={isSaving} onClick={() => void handleSaveToVault()} className={`flex items-center justify-center gap-2 px-4 py-3 text-sm ${btnPrimaryDark} disabled:opacity-60`}>
                  {isSaving ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : <Save className="h-4 w-4" aria-hidden />}
                  {isSaving ? "שומר..." : "שמור לכספת"}
                </button>
                <div className="grid grid-cols-3 gap-2">
                  <button type="button" onClick={() => void handleExportPDF()} className={`flex items-center justify-center gap-1 px-3 py-2 text-xs font-bold ${btnSecondaryGlass}`}>
                    <FileText className="h-4 w-4" aria-hidden />
                    PDF
                  </button>
                  <button type="button" onClick={() => void handleExportDOCX()} className={`flex items-center justify-center gap-1 px-3 py-2 text-xs font-bold ${btnSecondaryGlass}`}>
                    <Download className="h-4 w-4" aria-hidden />
                    Word
                  </button>
                  <button type="button" onClick={() => window.print()} className={`flex items-center justify-center gap-1 px-3 py-2 text-xs font-bold ${btnSecondaryGlass}`}>
                    <Printer className="h-4 w-4" aria-hidden />
                    הדפס
                  </button>
                </div>
              </div>
            </div>
          ) : null}
        </aside>

        <section className={`${glassPanel} min-h-[70vh] p-4 md:p-8`}>
          {!document ? (
            <div className="grid min-h-[60vh] place-items-center text-center text-slate-500">
              <div>
                <FileText className="mx-auto mb-4 h-16 w-16 stroke-1 text-[#9b7430]" aria-hidden />
                <p className="text-lg font-black text-slate-800">המסמך יופיע כאן</p>
                <p className="mt-2 max-w-md text-sm leading-6">לאחר יצירה תוכלו לערוך את הטקסט ישירות בתצוגה, ואז להוריד או לשמור לכספת.</p>
              </div>
            </div>
          ) : (
            <article
              ref={documentRef}
              className="mx-auto min-h-[297mm] w-full max-w-[210mm] bg-white p-8 text-slate-950 shadow-xl md:p-14 print:m-0 print:max-w-none print:shadow-none"
              contentEditable
              suppressContentEditableWarning
            >
              <header className="mb-8 border-b-2 border-slate-900 pb-4">
                <p className="font-frank text-xl font-black">VETO Legal</p>
                <p className="mt-1 text-sm text-slate-500">נוצר בתאריך {new Date().toLocaleDateString("he-IL")}</p>
              </header>
              <h2 className="mb-8 text-center font-frank text-3xl font-black underline underline-offset-4">{document.title}</h2>
              <p className="mb-8 whitespace-pre-wrap text-base leading-8">{document.preamble}</p>
              <h3 className="mb-4 font-frank text-xl font-black">סעיפים</h3>
              <ol className="space-y-4">
                {document.clauses.map((clause, index) => (
                  <li key={`${index}-${clause.slice(0, 12)}`} className="flex gap-3 text-base leading-8">
                    <span className="font-black">{index + 1}.</span>
                    <span>{clause}</span>
                  </li>
                ))}
              </ol>
              <section className="mt-16 border-t border-slate-200 pt-8">
                <h3 className="mb-10 font-frank text-xl font-black">חתימות</h3>
                <div className="grid gap-8 sm:grid-cols-2">
                  {document.signatures.map((sig, index) => (
                    <div key={`${sig.role}-${index}`} className="text-center">
                      <div className="mb-2 h-10 border-b border-slate-500" />
                      <p className="font-bold">{sig.role}</p>
                      {sig.name ? <p className="text-sm text-slate-500">{sig.name}</p> : null}
                    </div>
                  ))}
                </div>
              </section>
            </article>
          )}
        </section>
      </main>
      <CitizenBottomNav active="vault" />
    </div>
  );
}
