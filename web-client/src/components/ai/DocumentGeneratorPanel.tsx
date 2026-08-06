"use client";

import {
  AlertCircle,
  ArrowRight,
  Download,
  FileText,
  Mic,
  Printer,
  Save,
  Wand2,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { saveEvidence } from "@/app/actions/vault";
import { uploadFile } from "@/api/vaultApi";
import { renderDocumentExport } from "@/api/documentRenderApi";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { serializeDocumentFromDom } from "@/lib/documentSerialize";
import { glassInput, glassPanel, glassPanelNested } from "@/lib/vetoGlass";
import { useToastStore } from "@/store/useToastStore";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";
import {
  emptyParties,
  getDocumentFieldsConfig,
  type PartyRow,
} from "@/app/vault/generator/documentFields";

type DocumentGeneratorPanelProps = {
  variant?: "page" | "embedded";
};

type LegalDocument = {
  title: string;
  preamble: string;
  parties?: string[];
  definitions?: string[];
  clauses: string[];
  attachments?: string[];
  completionChecklist?: string[];
  legalNotes?: string[];
  signatures: { role: string; name: string }[];
  source?: "ai" | "fallback";
  warning?: string;
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
  { id: "family_estate", label: "משפחה, ירושה וצוואות" },
  { id: "tort_insurance", label: "נזיקין וביטוח" },
  { id: "consumer_privacy", label: "צרכנות, פרטיות והגנת מידע" },
  { id: "commercial", label: "מסחרי, חברות ושותפויות" },
  { id: "authority_request", label: "בקשה לרשות או לגוף ציבורי" },
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

export function DocumentGeneratorPanel({
  variant = "page",
}: DocumentGeneratorPanelProps) {
  const router = useRouter();
  const pushToast = useToastStore((s) => s.push);
  const embedded = variant === "embedded";
  const documentRef = useRef<HTMLDivElement>(null);
  const [selectedType, setSelectedType] = useState<(typeof DOCUMENT_TYPES)[number]["id"]>("warning_letter");
  const [details, setDetails] = useState("");
  const [document, setDocument] = useState<LegalDocument | null>(null);
  const [errorMsg, setErrorMsg] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isExportingPdf, setIsExportingPdf] = useState(false);
  const [isExportingDocx, setIsExportingDocx] = useState(false);
  const [isRecording, setIsRecording] = useState(false);

  const fieldsConfig = useMemo(() => getDocumentFieldsConfig(selectedType), [selectedType]);
  const [parties, setParties] = useState<PartyRow[]>(() => emptyParties(fieldsConfig.partyLabels.length));
  const [structuredFields, setStructuredFields] = useState<Record<string, string>>({});

  useEffect(() => {
    queueMicrotask(() => {
      setParties(emptyParties(fieldsConfig.partyLabels.length));
      setStructuredFields({});
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedType]);

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
    const requireMoreDetails = false;
    if (requireMoreDetails && selectedType === "custom" && details.trim().length < 12) {
      setErrorMsg("למסמך מותאם אישית צריך לכתוב לפחות משפט אחד עם פרטי המקרה.");
      return;
    }

    setIsGenerating(true);
    setErrorMsg("");
    try {
      const requestBody = JSON.stringify({
        documentType: selectedType,
        docTypeLabel: selectedLabel,
        prompt: details,
        structuredFacts: {
          parties: parties.map((p, i) => ({ ...p, label: fieldsConfig.partyLabels[i] || `צד ${i + 1}` })),
          fields: fieldsConfig.fields.map((f) => ({ label: f.label, value: structuredFields[f.key] || "" })),
        },
      });
      // A slow generation (long structured prompt) can occasionally exceed the
      // platform's function-duration limit (504) — retry once before giving up.
      const TRANSIENT_STATUSES = new Set([502, 503, 504]);
      let res: Response;
      try {
        res = await fetch("/api/generate-document", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: requestBody,
        });
        if (TRANSIENT_STATUSES.has(res.status)) {
          res = await fetch("/api/generate-document", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: requestBody,
          });
        }
      } catch {
        res = await fetch("/api/generate-document", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: requestBody,
        });
      }
      const data = (await res.json().catch(() => ({}))) as LegalDocument & { error?: string };
      if (!res.ok || data.error) {
        throw new Error(data.error || "יצירת המסמך נכשלה");
      }
      setDocument({
        title: data.title || selectedLabel,
        preamble: data.preamble || "",
        parties: Array.isArray(data.parties) ? data.parties : [],
        definitions: Array.isArray(data.definitions) ? data.definitions : [],
        clauses: Array.isArray(data.clauses) ? data.clauses : [],
        attachments: Array.isArray(data.attachments) ? data.attachments : [],
        completionChecklist: Array.isArray(data.completionChecklist) ? data.completionChecklist : [],
        legalNotes: Array.isArray(data.legalNotes) ? data.legalNotes : [],
        signatures: Array.isArray(data.signatures) ? data.signatures : [],
        source: data.source,
        warning: data.warning,
      });
      pushToast(data.warning || "המסמך נוצר. אפשר לערוך, להדפיס, להוריד או לשמור לכספת.", data.warning ? "info" : "success");
    } catch (e) {
      const msg = e instanceof Error ? e.message : "יצירת המסמך נכשלה";
      setErrorMsg(msg);
      pushToast(msg, "error");
    } finally {
      setIsGenerating(false);
    }
  };

  /**
   * Server-side export (`backend/src/services/documentRender`, Puppeteer):
   * real Chromium rendering gives selectable/searchable Hebrew text,
   * correct page breaks (clauses/signatures never split mid-line), and a
   * running header/footer with page numbers — none of which the old
   * html2canvas+jsPDF rasterization path (screenshot → sliced JPEG pages)
   * could provide. `serializeDocumentFromDom` reads the live, user-edited
   * `contentEditable` DOM (see `data-field` attributes in the JSX below),
   * since React state no longer reflects edits once the user starts typing.
   */
  const exportPdfBlob = async (): Promise<Blob> => {
    if (!documentRef.current) throw new Error("אין מסמך לייצוא");
    const serialized = serializeDocumentFromDom(documentRef.current);
    return renderDocumentExport(serialized, "pdf");
  };

  const handleExportPDF = async () => {
    setIsExportingPdf(true);
    try {
      const blob = await exportPdfBlob();
      const { saveAs } = await import("file-saver");
      saveAs(blob, `${safePdfBasename(document?.title || selectedLabel)}.pdf`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "ייצוא ה-PDF נכשל";
      pushToast(msg, "error");
    } finally {
      setIsExportingPdf(false);
    }
  };

  const handleExportDOCX = async () => {
    if (!documentRef.current) return;
    setIsExportingDocx(true);
    try {
      const serialized = serializeDocumentFromDom(documentRef.current);
      const blob = await renderDocumentExport(serialized, "docx");
      const { saveAs } = await import("file-saver");
      saveAs(blob, `${safePdfBasename(serialized.title || selectedLabel)}.docx`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "ייצוא ה-Word נכשל";
      pushToast(msg, "error");
    } finally {
      setIsExportingDocx(false);
    }
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
      if (!embedded) router.push("/vault");
    } catch (e) {
      const msg = e instanceof Error ? e.message : "שמירה לכספת נכשלה";
      setErrorMsg(msg);
      pushToast(msg, "error");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div
      className={
        embedded
          ? "flex min-h-0 flex-1 flex-col overflow-hidden"
          : "flex min-h-full flex-col pb-[calc(10rem+env(safe-area-inset-bottom))]"
      }
      dir="rtl"
    >
      <main
        className={
          embedded
            ? "grid min-h-0 flex-1 gap-3 overflow-y-auto p-3 lg:grid-cols-1"
            : "mx-auto grid w-full max-w-7xl flex-1 gap-5 px-4 pb-[calc(10rem+env(safe-area-inset-bottom))] pt-5 lg:grid-cols-[360px_minmax(0,1fr)]"
        }
      >
        <aside
          data-print="hide"
          className={`${glassPanel} h-fit ${embedded ? "p-3" : "p-5 lg:sticky lg:top-20"}`}
        >
          {!embedded ? (
            <Link
              href="/vault"
              className="mb-4 inline-flex items-center gap-2 text-sm font-bold text-secondary hover:text-primary"
            >
              <ArrowRight className="h-4 w-4" aria-hidden />
              חזרה לכספת
            </Link>
          ) : null}

          <h1
            className={`font-frank font-black text-primary ${embedded ? "text-lg" : "text-2xl"}`}
          >
            מחולל מסמכים משפטיים
          </h1>
          {!embedded ? (
            <p className="mt-2 text-sm leading-6 text-secondary">
              בחרו סוג מסמך, הוסיפו פרטים, והמערכת תנסח טיוטה שאפשר לערוך, להוריד או לשמור לכספת.
            </p>
          ) : null}

          <div className="mt-5 space-y-4">
            <label className="block">
              <span className="mb-1 block text-xs font-black text-secondary">סוג מסמך</span>
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

            <div>
              <span className="mb-2 block text-xs font-black text-secondary">פרטי הצדדים</span>
              <div className="space-y-3">
                {fieldsConfig.partyLabels.map((label, i) => (
                  <div key={`${selectedType}-party-${i}`} className={`${glassPanelNested} space-y-2 p-3`}>
                    <p className="text-xs font-black text-veto-gold-dark">{label}</p>
                    <input
                      value={parties[i]?.name || ""}
                      onChange={(e) =>
                        setParties((prev) => prev.map((p, idx) => (idx === i ? { ...p, name: e.target.value } : p)))
                      }
                      placeholder="שם מלא"
                      className={`${glassInput} text-sm`}
                    />
                    <div className="grid grid-cols-2 gap-2">
                      <input
                        value={parties[i]?.idNumber || ""}
                        onChange={(e) =>
                          setParties((prev) => prev.map((p, idx) => (idx === i ? { ...p, idNumber: e.target.value } : p)))
                        }
                        placeholder="ת.ז. / ח.פ."
                        className={`${glassInput} text-sm`}
                      />
                      <input
                        value={parties[i]?.address || ""}
                        onChange={(e) =>
                          setParties((prev) => prev.map((p, idx) => (idx === i ? { ...p, address: e.target.value } : p)))
                        }
                        placeholder="כתובת"
                        className={`${glassInput} text-sm`}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {fieldsConfig.fields.length > 0 ? (
              <div>
                <span className="mb-2 block text-xs font-black text-secondary">פרטים נוספים</span>
                <div className="space-y-3">
                  {fieldsConfig.fields.map((field) => (
                    <label key={`${selectedType}-${field.key}`} className="block">
                      <span className="mb-1 block text-xs font-bold text-secondary">{field.label}</span>
                      {field.type === "textarea" ? (
                        <textarea
                          value={structuredFields[field.key] || ""}
                          onChange={(e) => setStructuredFields((prev) => ({ ...prev, [field.key]: e.target.value }))}
                          placeholder={field.placeholder}
                          className={`${glassInput} min-h-20 resize-y text-sm leading-6`}
                        />
                      ) : (
                        <input
                          type={field.type === "date" ? "date" : "text"}
                          value={structuredFields[field.key] || ""}
                          onChange={(e) => setStructuredFields((prev) => ({ ...prev, [field.key]: e.target.value }))}
                          placeholder={field.placeholder}
                          className={`${glassInput} text-sm`}
                        />
                      )}
                    </label>
                  ))}
                </div>
              </div>
            ) : null}

            <label className="block">
              <span className="mb-1 flex items-center justify-between gap-3 text-xs font-black text-secondary">
                פרטי המקרה
                <IconButton
                  variant={isRecording ? "danger" : "secondary"}
                  size="sm"
                  onClick={handleVoiceRecord}
                  label="הכתבה קולית"
                  icon={<Mic className="h-4 w-4" aria-hidden />}
                />
              </span>
              <textarea
                value={details}
                onChange={(e) => setDetails(e.target.value)}
                placeholder="לדוגמה: שם הצדדים, תאריכים, סכומים, כתובות, מה הוסכם, מה הופר, ומה אתם רוצים שהמסמך יעשה."
                className={`${glassInput} resize-y leading-6 ${embedded ? "min-h-24" : "min-h-36"}`}
              />
            </label>
          </div>

          {errorMsg ? (
            <div className="mt-4 flex items-start gap-2 rounded-2xl border border-red-200 bg-red-50/90 p-3 text-sm text-red-900">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
              <span>{errorMsg}</span>
            </div>
          ) : null}

          <Button
            variant="primary"
            fullWidth
            className="mt-5"
            onClick={() => void generateDocument()}
            disabled={isGenerating}
            loading={isGenerating}
            iconStart={<Wand2 className="h-5 w-5" aria-hidden />}
          >
            {isGenerating ? "מנסח מסמך..." : "נסח מסמך AI"}
          </Button>

          {document ? (
            <div className={`${glassPanelNested} mt-5 p-4`}>
              {document.warning ? (
                <div className="mb-3 rounded-2xl border border-amber-200 bg-amber-50/90 p-3 text-sm font-bold text-amber-900">
                  {document.warning}
                </div>
              ) : null}
              <p className="text-sm font-black text-primary">פעולות למסמך</p>
              <div className="mt-3 grid gap-2">
                <Button
                  variant="primary"
                  disabled={isSaving}
                  loading={isSaving}
                  onClick={() => void handleSaveToVault()}
                  iconStart={<Save className="h-4 w-4" aria-hidden />}
                >
                  {isSaving ? "שומר..." : "שמור לכספת"}
                </Button>
                <div className="grid grid-cols-3 gap-2">
                  <Button
                    variant="secondary"
                    size="sm"
                    disabled={isExportingPdf}
                    loading={isExportingPdf}
                    onClick={() => void handleExportPDF()}
                    iconStart={<FileText className="h-4 w-4" aria-hidden />}
                  >
                    PDF
                  </Button>
                  <Button
                    variant="secondary"
                    size="sm"
                    disabled={isExportingDocx}
                    loading={isExportingDocx}
                    onClick={() => void handleExportDOCX()}
                    iconStart={<Download className="h-4 w-4" aria-hidden />}
                  >
                    Word
                  </Button>
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={() => window.print()}
                    iconStart={<Printer className="h-4 w-4" aria-hidden />}
                  >
                    הדפס
                  </Button>
                </div>
              </div>
            </div>
          ) : null}
        </aside>

        <section
          className={`${glassPanel} ${embedded ? "min-h-[280px] p-3" : "min-h-[70vh] p-4 md:p-8"}`}
        >
          {!document ? (
            <div
              className={`grid place-items-center text-center text-muted ${embedded ? "min-h-[200px]" : "min-h-[60vh]"}`}
            >
              <div>
                <FileText
                  className={`mx-auto mb-4 stroke-1 text-veto-gold-dark ${embedded ? "h-10 w-10" : "h-16 w-16"}`}
                  aria-hidden
                />
                <p className="text-lg font-black text-primary">המסמך יופיע כאן</p>
                {!embedded ? (
                  <p className="mt-2 max-w-md text-sm leading-6">
                    לאחר יצירה תוכלו לערוך את הטקסט ישירות בתצוגה, ואז להוריד או לשמור לכספת.
                  </p>
                ) : null}
              </div>
            </div>
          ) : (
            <article
              ref={documentRef}
              data-print="root"
              className={`mx-auto w-full bg-surface-overlay text-primary shadow-xl print:m-0 print:max-w-none print:shadow-none ${
                embedded
                  ? "max-w-full p-4"
                  : "min-h-[297mm] max-w-[210mm] p-8 md:p-14"
              }`}
              contentEditable
              suppressContentEditableWarning
            >
              <header
                className="mb-8 border-b-2 border-strong pb-4"
                contentEditable={false}
                suppressContentEditableWarning
              >
                <VetoBrandLogo className="h-8 w-auto max-w-[200px]" />
                <p className="mt-3 text-sm text-muted">נוצר בתאריך {new Date().toLocaleDateString("he-IL")}</p>
              </header>
              <h2 data-field="title" className="mb-8 text-center font-frank text-3xl font-black underline underline-offset-4">{document.title}</h2>
              <p data-field="preamble" className="mb-8 whitespace-pre-wrap text-base leading-8">{document.preamble}</p>
              {document.parties?.length ? (
                <section data-field-group="parties" className="mb-8 rounded-sm border border-subtle bg-surface-sunken p-4">
                  <h3 className="mb-3 font-frank text-lg font-black">הצדדים</h3>
                  <ol className="space-y-2">
                    {document.parties.map((item, index) => (
                      <li key={`party-${index}`} className="flex gap-3 text-sm leading-7">
                        <span className="font-black">{index + 1}.</span>
                        <span data-field="parties" data-index={index}>{item}</span>
                      </li>
                    ))}
                  </ol>
                </section>
              ) : null}
              {document.definitions?.length ? (
                <section data-field-group="definitions" className="mb-8 rounded-sm border border-subtle bg-surface-overlay p-4">
                  <h3 className="mb-3 font-frank text-lg font-black">הגדרות</h3>
                  <ol className="space-y-2">
                    {document.definitions.map((item, index) => (
                      <li key={`definition-${index}`} className="flex gap-3 text-sm leading-7">
                        <span className="font-black">{index + 1}.</span>
                        <span data-field="definitions" data-index={index}>{item}</span>
                      </li>
                    ))}
                  </ol>
                </section>
              ) : null}
              <h3 className="mb-4 font-frank text-xl font-black">סעיפים</h3>
              <ol data-field-group="clauses" className="space-y-4">
                {document.clauses.map((clause, index) => (
                  <li key={`${index}-${clause.slice(0, 12)}`} className="flex gap-3 text-base leading-8">
                    <span className="font-black">{index + 1}.</span>
                    <span data-field="clauses" data-index={index}>{clause}</span>
                  </li>
                ))}
              </ol>
              {document.attachments?.length ? (
                <section data-field-group="attachments" className="mt-12 border-t border-subtle pt-6">
                  <h3 className="mb-4 font-frank text-xl font-black">נספחים מומלצים</h3>
                  <ul className="list-inside list-disc space-y-2 text-base leading-7">
                    {document.attachments.map((item, index) => (
                      <li key={`attachment-${index}`} data-field="attachments" data-index={index}>{item}</li>
                    ))}
                  </ul>
                </section>
              ) : null}
              {document.completionChecklist?.length ? (
                <section data-field-group="completionChecklist" className="mt-10 rounded-sm border border-amber-200 bg-amber-50 p-5">
                  <h3 className="mb-4 font-frank text-xl font-black">צ&apos;קליסט לפני שימוש</h3>
                  <ol className="space-y-2">
                    {document.completionChecklist.map((item, index) => (
                      <li key={`check-${index}`} className="flex gap-3 text-base leading-7">
                        <span className="font-black">{index + 1}.</span>
                        <span data-field="completionChecklist" data-index={index}>{item}</span>
                      </li>
                    ))}
                  </ol>
                </section>
              ) : null}
              {document.legalNotes?.length ? (
                <section data-field-group="legalNotes" className="mt-10 border-t border-subtle pt-6">
                  <h3 className="mb-4 font-frank text-xl font-black">הערות משפטיות</h3>
                  <ul className="list-inside list-disc space-y-2 text-sm leading-7 text-secondary">
                    {document.legalNotes.map((item, index) => (
                      <li key={`note-${index}`} data-field="legalNotes" data-index={index}>{item}</li>
                    ))}
                  </ul>
                </section>
              ) : null}
              <section data-field-group="signatures" className="mt-16 border-t border-subtle pt-8">
                <h3 className="mb-10 font-frank text-xl font-black">חתימות</h3>
                <div className="grid gap-8 sm:grid-cols-2">
                  {document.signatures.map((sig, index) => (
                    <div key={`${sig.role}-${index}`} className="text-center">
                      <div className="mb-2 h-10 border-b border-strong" />
                      <p data-field="signatureRole" data-index={index} className="font-bold">{sig.role}</p>
                      <p data-field="signatureName" data-index={index} className="text-sm text-muted">{sig.name || ""}</p>
                    </div>
                  ))}
                </div>
              </section>
            </article>
          )}
        </section>
      </main>
      {!embedded ? <CitizenBottomNav active="vault" /> : null}
    </div>
  );
}
