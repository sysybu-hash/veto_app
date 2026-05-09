"use client";

import {
  AlertCircle,
  ChevronRight,
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
import { useRef, useState } from "react";
import { saveEvidence } from "@/app/actions/vault";
import { uploadFile } from "@/api/vaultApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { useTranslation } from "@/lib/i18n/LocaleProvider";
import { useToastStore } from "@/store/useToastStore";

const DOCUMENT_TYPES = [
  { id: "warning_letter", label: "מכתב התראה טרם נקיטת הליכים (טרם תביעה)" },
  { id: "power_of_attorney", label: "ייפוי כוח כללי / ספציפי" },
  { id: "lease_agreement", label: "חוזה שכירות (מגורים/עסקי)" },
  { id: "nda", label: "הסכם סודיות (NDA)" },
  { id: "employment", label: "הסכם עבודה / הודעה על תנאי העסקה" },
  { id: "loan_agreement", label: "הסכם הלוואה בין פרטיים" },
  { id: "cease_and_desist", label: "מכתב דרישה לחדול מהפרת זכויות יוצרים" },
  {
    id: "custom",
    label: "מסמך משפטי מותאם אישית (הגדרה חופשית)",
  },
] as const;

interface LegalDocument {
  title: string;
  preamble: string;
  clauses: string[];
  signatures: { role: string; name: string }[];
}

/** קטגוריה ב-Prisma: מקור AI_GENERATOR + סוג PDF (שדה יחיד ב-schema) */
const VAULT_CATEGORY_AI_PDF = "AI_GENERATOR_PDF";

async function sha256HexFromBlob(blob: Blob): Promise<string> {
  const buf = await blob.arrayBuffer();
  const hash = await crypto.subtle.digest("SHA-256", buf);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function safePdfBasename(title: string): string {
  const cleaned = title.replace(/[/\\?%*:|"<>]/g, "_").trim();
  return cleaned.slice(0, 120) || "document";
}

export default function DocumentGeneratorPage() {
  const { t, locale } = useTranslation();
  const router = useRouter();
  const pushToast = useToastStore((s) => s.push);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [selectedType, setSelectedType] = useState<string>(DOCUMENT_TYPES[0]!.id);
  const [customPrompt, setCustomPrompt] = useState("");
  const [errorMsg, setErrorMsg] = useState("");
  const [document, setDocument] = useState<LegalDocument | null>(null);
  const documentRef = useRef<HTMLDivElement>(null);

  const handleVoiceRecord = () => {
    if (!("webkitSpeechRecognition" in window) && !("SpeechRecognition" in window)) {
      alert(t("docGenSpec.alertNoSpeech"));
      return;
    }

    // @ts-expect-error SpeechRecognition vendor API
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    recognition.lang = "he-IL";
    recognition.interimResults = false;
    recognition.onstart = () => setIsRecording(true);
    recognition.onresult = (event: {
      results: Array<Array<{ transcript: string }>>;
    }) => {
      const transcript = event.results[0][0].transcript;
      setCustomPrompt((prev) => `${prev} ${transcript}`);
    };
    recognition.onerror = () => setIsRecording(false);
    recognition.onend = () => setIsRecording(false);
    recognition.start();
  };

  const generateDocumentWithAI = async () => {
    if (!customPrompt && selectedType === "custom") return;

    setIsGenerating(true);
    setErrorMsg("");

    try {
      const docTypeLabel = DOCUMENT_TYPES.find((x) => x.id === selectedType)?.label;
      const res = await fetch("/api/generate-document", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          documentType: selectedType,
          prompt: customPrompt,
          docTypeLabel,
        }),
      });
      if (!res.ok) throw new Error(t("docGenSpec.errorFetch"));

      const data: LegalDocument = await res.json();
      setDocument(data);
    } catch (err) {
      console.error(err);
      setErrorMsg(t("docGenSpec.errorCatch"));
    } finally {
      setIsGenerating(false);
    }
  };

  const buildPdfOptions = () => ({
    margin: 10,
    filename: `${document?.title || t("docGenSpec.defaultDocName")}.pdf`,
    image: { type: "jpeg" as const, quality: 0.98 },
    html2canvas: { scale: 2 },
    jsPDF: {
      unit: "mm" as const,
      format: "a4" as const,
      orientation: "portrait" as const,
    },
  });

  const handleExportPDF = async () => {
    if (!documentRef.current) return;
    const html2pdf = (await import("html2pdf.js")).default;
    const opt = buildPdfOptions();
    html2pdf().set(opt).from(documentRef.current).save();
  };

  const handleSaveToVault = async () => {
    if (!documentRef.current || !document) return;

    setIsSaving(true);
    setErrorMsg("");
    try {
      const html2pdf = (await import("html2pdf.js")).default;
      const opt = buildPdfOptions();
      const el = documentRef.current;

      const blob = (await html2pdf()
        .set(opt)
        .from(el)
        .outputPdf("blob")) as Blob;

      const base = safePdfBasename(document.title);
      const file = new File([blob], `${base}.pdf`, {
        type: "application/pdf",
      });

      const hash = await sha256HexFromBlob(blob);
      const created = await uploadFile(file, "");
      const url =
        typeof created.url === "string" && created.url.length > 0
          ? created.url
          : "";
      if (!url) {
        throw new Error(t("vault.uploadMissingUrl"));
      }

      const title = document.title.trim().slice(0, 500) || `${base}.pdf`;

      const neon = await saveEvidence({
        title,
        url,
        hash,
        category: VAULT_CATEGORY_AI_PDF,
      });

      if (!neon.success) {
        throw new Error(neon.error);
      }

      pushToast(t("vault.uploadSuccessToast"), "success");
      router.replace("/vault");
    } catch (e) {
      const msg =
        e instanceof Error ? e.message : t("vault.uploadFailedGeneric");
      pushToast(msg, "error");
      setErrorMsg(msg);
    } finally {
      setIsSaving(false);
    }
  };

  const handleExportDOCX = async () => {
    if (!document) return;
    const { Document, Packer, Paragraph, AlignmentType } = await import("docx");
    const { saveAs } = await import("file-saver");
    const doc = new Document({
      sections: [
        {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any -- תואם למפרט המקורי (RTL בעברית)
          properties: { rtl: true } as any,
          children: [
            new Paragraph({
              text: document.title,
              heading: "Heading1",
              alignment: AlignmentType.CENTER,
            }),
            new Paragraph({
              text: document.preamble,
              spacing: { before: 400, after: 400 },
            }),
            ...document.clauses.map(
              (clause, i) =>
                new Paragraph({
                  text: `${i + 1}. ${clause}`,
                  spacing: { after: 200 },
                }),
            ),
            new Paragraph({
              text: "ולראיה באו הצדדים על החתום:",
              spacing: { before: 600, after: 400 },
            }),
            ...document.signatures.map(
              (sig) =>
                new Paragraph({
                  text: `${sig.role}: _______________________`,
                  spacing: { after: 200 },
                }),
            ),
          ],
        },
      ],
    });
    const blob = await Packer.toBlob(doc);
    saveAs(blob, `${document.title}.docx`);
  };

  const handlePrint = () => window.print();

  const rtl = locale === "he";

  return (
    <div
      className="flex min-h-screen flex-col pb-24"
      dir={rtl ? "rtl" : "ltr"}
    >
      <div className="flex min-h-0 flex-1 flex-col md:flex-row">
      <aside className="z-10 flex h-auto w-full flex-col overflow-y-auto border-white/10 bg-slate-950/70 backdrop-blur-xl p-6 md:sticky md:top-0 md:h-screen md:w-80 md:border-l print:hidden">
        <Link
          href="/vault"
          className="mb-8 flex items-center text-slate-500 transition hover:text-slate-200"
        >
          <ChevronRight className="ml-1 h-4 w-4" /> {t("docGenSpec.back")}
        </Link>
        <h2 className="mb-6 font-serif text-xl font-bold text-slate-100">
          {t("docGenSpec.sidebarTitle")}
        </h2>
        <div className="mb-6 space-y-3">
          <label className="text-sm font-medium text-slate-300">
            {t("docGenSpec.docTypeLabel")}
          </label>
          <select
            value={selectedType}
            onChange={(e) => setSelectedType(e.target.value)}
            className="w-full rounded-lg border border-white/10 bg-slate-950 p-3 text-sm text-slate-200 outline-none focus:ring-2 focus:ring-[#C5A059]"
          >
            {DOCUMENT_TYPES.map((type) => (
              <option key={type.id} value={type.id}>
                {type.label}
              </option>
            ))}
          </select>
        </div>
        <div className="mb-8 space-y-3">
          <div className="flex items-center justify-between">
            <label className="text-sm font-medium text-slate-300">
              {t("docGenSpec.detailsLabel")}
            </label>
            <button
              type="button"
              onClick={handleVoiceRecord}
              className={`rounded-full p-2 transition ${isRecording ? "animate-pulse bg-red-500/15 text-red-600" : "bg-white/[0.04] text-slate-500 hover:bg-white/[0.08]"}`}
              title={t("docGenSpec.voiceTitle")}
            >
              <Mic className="h-4 w-4" />
            </button>
          </div>
          <textarea
            value={customPrompt}
            onChange={(e) => setCustomPrompt(e.target.value)}
            placeholder={t("docGenSpec.textareaPlaceholder")}
            className="h-32 w-full resize-none rounded-lg border border-white/10 bg-slate-950 p-3 text-sm text-slate-200 outline-none focus:ring-2 focus:ring-[#C5A059]"
          />
        </div>
        {errorMsg ? (
          <div className="mb-4 flex items-start gap-2 rounded-lg bg-red-500/10 p-3 text-sm text-red-600">
            <AlertCircle className="mt-0.5 h-4 w-4" />
            <span>{errorMsg}</span>
          </div>
        ) : null}
        <button
          type="button"
          onClick={() => void generateDocumentWithAI()}
          disabled={isGenerating}
          className="mb-8 flex w-full items-center justify-center gap-2 rounded-lg bg-[#C5A059] py-3 font-medium text-white shadow-sm transition hover:bg-[#b08d4a] disabled:opacity-70"
        >
          {isGenerating ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            <Wand2 className="h-5 w-5" />
          )}
          {isGenerating ? t("docGenSpec.generating") : t("docGenSpec.generateBtn")}
        </button>
        {document ? (
          <div className="space-y-3 border-t border-white/10 pt-6">
            <label className="mb-2 block text-sm font-medium text-slate-500">
              {t("docGenSpec.exportSection")}
            </label>
            <button
              type="button"
              onClick={() => void handleSaveToVault()}
              disabled={isSaving}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-slate-900 py-2.5 text-sm font-medium text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isSaving ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}{" "}
              {isSaving ? t("docGenSpec.saveVaultBusy") : t("docGenSpec.saveVault")}
            </button>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => void handleExportPDF()}
                disabled={isSaving}
                className="flex items-center justify-center gap-2 rounded-lg bg-white/[0.04] py-2.5 text-sm font-medium text-slate-300 transition hover:bg-white/[0.08] disabled:opacity-50"
              >
                <FileText className="h-4 w-4" /> {t("docGenSpec.pdf")}
              </button>
              <button
                type="button"
                onClick={() => void handleExportDOCX()}
                disabled={isSaving}
                className="flex items-center justify-center gap-2 rounded-lg bg-white/[0.04] py-2.5 text-sm font-medium text-slate-300 transition hover:bg-white/[0.08] disabled:opacity-50"
              >
                <Download className="h-4 w-4" /> {t("docGenSpec.word")}
              </button>
            </div>
            <button
              type="button"
              onClick={handlePrint}
              disabled={isSaving}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-white/[0.04] py-2.5 text-sm font-medium text-slate-300 transition hover:bg-white/[0.08] disabled:opacity-50"
            >
              <Printer className="h-4 w-4" /> {t("docGenSpec.print")}
            </button>
          </div>
        ) : null}
      </aside>
      <main className="flex-1 overflow-y-auto p-4 md:p-12">
        {!document ? (
          <div className="flex h-full flex-col items-center justify-center text-slate-400 opacity-60 print:hidden">
            <FileText className="mb-4 h-16 w-16 stroke-1" />
            <p className="text-lg">{t("docGenSpec.emptyState")}</p>
          </div>
        ) : (
          <div
            ref={documentRef}
            className="mx-auto min-h-[297mm] w-full max-w-[210mm] border border-white/10 bg-white p-10 shadow-xl md:p-16 print:m-0 print:border-none print:p-0 print:shadow-none"
          >
            <div className="text-slate-900 outline-none" contentEditable suppressContentEditableWarning>
              <div className="mb-8 flex items-end justify-between border-b-2 border-slate-900 pb-4">
                <div>
                  <h1 className="font-serif text-2xl font-bold tracking-tight text-slate-900">
                    {t("docGenSpec.brandHeader")}
                  </h1>
                </div>
                <div className="text-left text-sm text-slate-500">
                  {t("docGenSpec.createdDate")}{" "}
                  {new Date().toLocaleDateString(rtl ? "he-IL" : locale === "ru" ? "ru-RU" : "en-US")}
                </div>
              </div>
              <h2 className="mb-8 text-center font-serif text-2xl font-bold text-slate-900 underline underline-offset-4 md:text-3xl">
                {document.title}
              </h2>
              <div className="mb-8 whitespace-pre-wrap font-sans text-base leading-loose text-slate-800">
                {document.preamble}
              </div>
              <div className="mb-12 space-y-4">
                <h3 className="mb-4 font-serif text-lg font-bold text-slate-900">
                  {t("docGenSpec.clausesHeading")}
                </h3>
                {document.clauses.map((clause, index) => (
                  <div
                    key={index}
                    className="flex gap-4 font-sans text-base leading-relaxed text-slate-800"
                  >
                    <span className="min-w-[24px] font-bold">{index + 1}.</span>
                    <p>{clause}</p>
                  </div>
                ))}
              </div>
              <div className="mt-16 border-t border-slate-200 pt-8">
                <h3 className="mb-12 font-serif text-lg font-bold text-slate-900">
                  {t("docGenSpec.signaturesHeading")}
                </h3>
                <div className="flex items-end justify-around">
                  {document.signatures.map((sig, idx) => (
                    <div key={idx} className="w-40 text-center">
                      <div className="mb-2 h-8 border-b border-slate-400"></div>
                      <p className="font-medium text-slate-800">{sig.role}</p>
                      {sig.name ? (
                        <p className="text-sm text-slate-500">{sig.name}</p>
                      ) : null}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
      </div>

      <CitizenBottomNav active="vault" />
    </div>
  );
}
