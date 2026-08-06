"use client";

import {
  Download,
  Mail,
  RefreshCw,
  Scale,
  Tag,
  Wallet,
} from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { authFetch } from "@/api/apiClient";
import { Button } from "@/components/ui/primitives/Button";
import { LawyerPayoutsPanel } from "./LawyerPayoutsPanel";
import { PricingPanel } from "./PricingPanel";

type FinanceTab = "platform" | "lawyers" | "pricing";

type Preset = "today" | "week" | "month";

type FinanceReport = {
  generatedAt: string;
  range: { from: string; to: string; preset: string };
  revenue: {
    range: { totalIls: number; chargedCalls: number };
    today: { totalIls: number; chargedCalls: number };
    week: { totalIls: number; chargedCalls: number };
    month: { totalIls: number; chargedCalls: number };
  };
  subscriptions: {
    active: number;
    expired: number;
    free: number;
    none: number;
    lawyers: number;
    admins: number;
  };
  totals: { users: number; eventsInRange: number };
  recentCharges: Array<{
    id: string;
    amountIls: number;
    chargeStatus: string | null;
    callType: string | null;
    createdAt: string | null;
  }>;
  textReport: string;
  csv: string;
  source?: string;
};

function ils(n: number): string {
  return `${n.toLocaleString("he-IL", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })} ₪`;
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return "—";
  try {
    return new Intl.DateTimeFormat("he-IL", {
      dateStyle: "short",
      timeStyle: "short",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

export default function AdminFinancePage() {
  const [tab, setTab] = useState<FinanceTab>("lawyers");
  const [preset, setPreset] = useState<Preset>("month");
  const [report, setReport] = useState<FinanceReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [emailTo, setEmailTo] = useState("");
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBusy, setEmailBusy] = useState(false);
  const [emailMsg, setEmailMsg] = useState<string | null>(null);

  const load = useCallback(async (p: Preset) => {
    setLoading(true);
    setError(null);
    try {
      const res = await authFetch(
        `/api/admin/finance/report?preset=${encodeURIComponent(p)}`,
      );
      if (!res.ok) {
        const err = (await res.json().catch(() => null)) as {
          error?: string;
          message?: string;
        } | null;
        const raw = err?.error || err?.message || "";
        const friendly =
          /not\s*found/i.test(raw)
            ? "נתיב הדוח לא זמין בשרת עדיין — מנסים מצב חלופי. רעננו את הדף."
            : raw || `טעינה נכשלה (${res.status})`;
        throw new Error(friendly);
      }
      const body = (await res.json()) as { data?: FinanceReport };
      if (!body.data) throw new Error("תגובת שרת לא צפויה");
      setReport(body.data);
    } catch (e) {
      setReport(null);
      setError(e instanceof Error ? e.message : "טעינת הדוח נכשלה");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (tab !== "platform") return;
    // Deferred so the spinner/reset setState lands after this render commits
    // instead of cascading a second render pass out of the effect body.
    queueMicrotask(() => void load(preset));
  }, [load, preset, tab]);

  const downloadCsv = () => {
    if (!report?.csv) return;
    const blob = new Blob(["\uFEFF" + report.csv], {
      type: "text/csv;charset=utf-8",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `veto-finance-${preset}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const downloadText = () => {
    if (!report?.textReport) return;
    const blob = new Blob([report.textReport], {
      type: "text/plain;charset=utf-8",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `veto-finance-${preset}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const sendEmail = async () => {
    setEmailMsg(null);
    setEmailBusy(true);
    try {
      const res = await authFetch("/api/admin/finance/email-report", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          to: emailTo.trim(),
          subject: emailSubject.trim() || undefined,
          preset,
        }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        error?: string;
        sent?: boolean;
        to?: string;
      };
      if (!res.ok) {
        throw new Error(body.error || `שליחה נכשלה (${res.status})`);
      }
      setEmailMsg(`הדוח נשלח אל ${body.to || emailTo.trim()}`);
    } catch (e) {
      setEmailMsg(e instanceof Error ? e.message : "שליחת המייל נכשלה");
    } finally {
      setEmailBusy(false);
    }
  };

  return (
    <div className="mx-auto flex w-full max-w-6xl flex-1 flex-col gap-8 px-4 py-8 md:px-8">
      <header className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs font-bold uppercase tracking-wide text-brand-text">
            ממשק מנהל
          </p>
          <h1 className="mt-1 flex items-center gap-2 font-frank text-3xl font-black text-primary">
            <Wallet className="h-8 w-8 text-brand-text" aria-hidden />
            כספים ודוחות
          </h1>
          <p className="mt-1 text-sm text-muted">
            תשלומים לעורכי דין לפי פעילות, הכנסות פלטפורמה, דוחות ושליחת מייל.
          </p>
        </div>
        {tab === "platform" ? (
          <div className="flex flex-wrap items-center gap-2">
            {(
              [
                ["today", "היום"],
                ["week", "שבוע"],
                ["month", "חודש"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                onClick={() => setPreset(id)}
                className={`rounded-xl px-3 py-2 text-sm font-bold transition ${
                  preset === id
                    ? "bg-veto-gold/20 text-brand-text"
                    : "border border-subtle text-secondary hover:bg-hover-overlay"
                }`}
              >
                {label}
              </button>
            ))}
            <Button
              variant="secondary"
              size="sm"
              disabled={loading}
              onClick={() => void load(preset)}
              iconStart={
                <RefreshCw
                  className={`h-4 w-4 ${loading ? "animate-spin" : ""}`}
                  aria-hidden
                />
              }
            >
              רענון
            </Button>
          </div>
        ) : null}
      </header>

      <div className="flex gap-1 rounded-2xl border border-subtle bg-white/[0.04] p-1">
        <button
          type="button"
          onClick={() => setTab("lawyers")}
          className={`flex flex-1 items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-sm font-black transition ${
            tab === "lawyers"
              ? "bg-veto-gold/20 text-brand-text"
              : "text-secondary hover:bg-hover-overlay"
          }`}
        >
          <Scale className="h-4 w-4" aria-hidden />
          תשלומים לעו״ד
        </button>
        <button
          type="button"
          onClick={() => setTab("platform")}
          className={`flex flex-1 items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-sm font-black transition ${
            tab === "platform"
              ? "bg-veto-gold/20 text-brand-text"
              : "text-secondary hover:bg-hover-overlay"
          }`}
        >
          <Wallet className="h-4 w-4" aria-hidden />
          חיובי חריגה ודוחות
        </button>
        <button
          type="button"
          onClick={() => setTab("pricing")}
          className={`flex flex-1 items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-sm font-black transition ${
            tab === "pricing"
              ? "bg-veto-gold/20 text-brand-text"
              : "text-secondary hover:bg-hover-overlay"
          }`}
        >
          <Tag className="h-4 w-4" aria-hidden />
          מחירים
        </button>
      </div>

      {tab === "lawyers" ? <LawyerPayoutsPanel /> : null}
      {tab === "pricing" ? <PricingPanel /> : null}

      {tab === "platform" && error ? (
        <div
          className="rounded-2xl border border-danger-border bg-danger-soft px-4 py-3 text-sm font-semibold text-danger-on-soft"
          role="alert"
        >
          {error}
          <p className="mt-1 text-xs font-medium text-primary/80">
            אם הבעיה נמשכת — רעננו את הדף. דוחות מלאים דורשים גם פריסת backend מעודכן.
          </p>
        </div>
      ) : null}

      {tab === "platform" ? (
        <>
      {report?.source === "fallback-stats" ? (
        <p className="rounded-xl border border-warning-border bg-warning-soft px-3 py-2 text-sm font-semibold text-warning-on-soft">
          מצב זמני: הנתונים מורכבים מ־stats קיים בשרת. סיכומי שבוע/חודש מלאים וחיובים
          אחרונים יופיעו אחרי פריסת ה-backend המעודכן.
        </p>
      ) : null}

      <section className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          {
            // charge_amount_ils is overtime only — see buildFinanceReport.
            label: "חיובי חריגה בטווח",
            value: report ? ils(report.revenue.range.totalIls) : "—",
            hint: report
              ? `${report.revenue.range.chargedCalls} חיובים`
              : "",
          },
          {
            label: "היום",
            value: report ? ils(report.revenue.today.totalIls) : "—",
            hint: "",
          },
          {
            label: "7 ימים",
            value: report ? ils(report.revenue.week.totalIls) : "—",
            hint: "",
          },
          {
            label: "מתחילת החודש",
            value: report ? ils(report.revenue.month.totalIls) : "—",
            hint: "",
          },
        ].map((card) => (
          <article
            key={card.label}
            className="rounded-2xl border border-subtle bg-surface-raised/80 p-4 backdrop-blur-xl"
          >
            <p className="text-xs font-bold text-muted">{card.label}</p>
            <p className="mt-2 font-frank text-2xl font-black text-primary">
              {loading && !report ? "…" : card.value}
            </p>
            {card.hint ? (
              <p className="mt-1 text-xs text-secondary">{card.hint}</p>
            ) : null}
          </article>
        ))}
      </section>

      <section className="grid gap-4 lg:grid-cols-2">
        <article className="rounded-2xl border border-subtle bg-surface-raised/80 p-5 backdrop-blur-xl">
          <h2 className="font-frank text-lg font-black text-primary">
            ניהול מנויים
          </h2>
          <p className="mt-1 text-sm text-muted">
            מצב מנויים ומשתמשים במערכת.
          </p>
          <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
            {[
              ["פעילים", report?.subscriptions.active],
              ["פגו", report?.subscriptions.expired],
              ["פטורים", report?.subscriptions.free],
              ["ללא מנוי", report?.subscriptions.none],
              ["עורכי דין", report?.subscriptions.lawyers],
              ["מנהלים", report?.subscriptions.admins],
              ["סה״כ משתמשים", report?.totals.users],
              ["אירועי SOS בטווח", report?.totals.eventsInRange],
            ].map(([k, v]) => (
              <div
                key={String(k)}
                className="rounded-xl border border-subtle bg-white/[0.03] px-3 py-2"
              >
                <dt className="text-xs text-muted">{k}</dt>
                <dd className="mt-0.5 text-lg font-black text-primary">
                  {v ?? "—"}
                </dd>
              </div>
            ))}
          </dl>
        </article>

        <article className="rounded-2xl border border-subtle bg-surface-raised/80 p-5 backdrop-blur-xl">
          <h2 className="font-frank text-lg font-black text-primary">
            מחולל דוחות
          </h2>
          <p className="mt-1 text-sm text-muted">
            הורידו דוח טקסט או CSV לפי הטווח שנבחר למעלה.
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <Button
              variant="primary"
              disabled={!report || loading}
              onClick={downloadText}
              iconStart={<Download className="h-4 w-4" aria-hidden />}
            >
              הורדת דוח ניהול (TXT)
            </Button>
            <Button
              variant="secondary"
              disabled={!report || loading}
              onClick={downloadCsv}
              iconStart={<Download className="h-4 w-4" aria-hidden />}
            >
              הורדת חיובים (CSV)
            </Button>
          </div>
          {report ? (
            <pre className="mt-4 max-h-64 overflow-auto rounded-xl border border-subtle bg-black/20 p-3 text-xs leading-relaxed text-secondary">
              {report.textReport}
            </pre>
          ) : null}
        </article>
      </section>

      <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-5 backdrop-blur-xl">
        <h2 className="flex items-center gap-2 font-frank text-lg font-black text-primary">
          <Mail className="h-5 w-5 text-brand-text" aria-hidden />
          שליחת דוח במייל
        </h2>
        <p className="mt-1 text-sm text-muted">
          נשלח דוח טקסט + קובץ CSV. דורש הגדרת SMTP בשרת (SMTP_HOST, SMTP_FROM).
        </p>
        <div className="mt-4 grid gap-3 md:grid-cols-[1fr_1fr_auto]">
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-bold text-muted">
              אימייל יעד
            </span>
            <input
              type="email"
              value={emailTo}
              onChange={(e) => setEmailTo(e.target.value)}
              placeholder="finance@example.com"
              className="min-h-11 w-full rounded-xl border border-subtle bg-white/[0.04] px-3 text-sm text-primary outline-none ring-veto-gold/40 focus:ring-2"
              disabled={emailBusy}
            />
          </label>
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-bold text-muted">
              נושא (אופציונלי)
            </span>
            <input
              type="text"
              value={emailSubject}
              onChange={(e) => setEmailSubject(e.target.value)}
              placeholder="דוח כספים VETO"
              className="min-h-11 w-full rounded-xl border border-subtle bg-white/[0.04] px-3 text-sm text-primary outline-none ring-veto-gold/40 focus:ring-2"
              disabled={emailBusy}
            />
          </label>
          <div className="flex items-end">
            <Button
              variant="primary"
              className="w-full md:w-auto"
              disabled={emailBusy || !emailTo.trim()}
              loading={emailBusy}
              onClick={() => void sendEmail()}
              iconStart={<Mail className="h-4 w-4" aria-hidden />}
            >
              שליחת דוח
            </Button>
          </div>
        </div>
        {emailMsg ? (
        <p
          className={`mt-3 text-sm font-semibold ${
            /נכשל|נדרש|SMTP|לא ניתן/i.test(emailMsg)
              ? "text-danger"
              : "text-success"
          }`}
          role="status"
        >
          {emailMsg}
        </p>
      ) : null}
      </section>

      <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-5 backdrop-blur-xl">
        <h2 className="font-frank text-lg font-black text-primary">
          חיובים אחרונים בטווח
        </h2>
        {/* Focusable scroll region — see LawyerPayoutsPanel for the rationale. */}
        <div
          className="mt-4 overflow-x-auto"
          tabIndex={0}
          role="region"
          aria-label="חיובים אחרונים בטווח"
        >
          <table className="w-full min-w-[640px] text-start text-sm">
            <thead>
              <tr className="border-b border-subtle text-xs text-muted">
                <th className="px-2 py-2 font-bold">תאריך</th>
                <th className="px-2 py-2 font-bold">סכום</th>
                <th className="px-2 py-2 font-bold">סטטוס</th>
                <th className="px-2 py-2 font-bold">סוג שיחה</th>
                <th className="px-2 py-2 font-bold">מזהה</th>
              </tr>
            </thead>
            <tbody>
              {(report?.recentCharges ?? []).length === 0 ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-2 py-8 text-center text-muted"
                  >
                    {loading ? "טוען…" : "אין חיובים בטווח שנבחר."}
                  </td>
                </tr>
              ) : (
                report!.recentCharges.map((row) => (
                  <tr key={row.id} className="border-b border-subtle/60">
                    <td className="px-2 py-2 text-secondary">
                      {fmtDate(row.createdAt)}
                    </td>
                    <td className="px-2 py-2 font-bold text-primary">
                      {ils(row.amountIls)}
                    </td>
                    <td className="px-2 py-2 text-secondary">
                      {row.chargeStatus || "—"}
                    </td>
                    <td className="px-2 py-2 text-secondary">
                      {row.callType || "—"}
                    </td>
                    <td className="px-2 py-2 font-mono text-xs text-muted">
                      {row.id.slice(-8)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        {report?.generatedAt ? (
          <p className="mt-3 text-xs text-muted">
            עודכן: {fmtDate(report.generatedAt)}
          </p>
        ) : null}
      </section>
        </>
      ) : null}
    </div>
  );
}
