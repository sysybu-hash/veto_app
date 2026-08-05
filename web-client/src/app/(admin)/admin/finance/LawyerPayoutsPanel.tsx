"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import { authFetch } from "@/api/apiClient";
import { Button } from "@/components/ui/primitives/Button";
import {
  Banknote,
  CheckCircle2,
  Download,
  Pencil,
  RefreshCw,
  Scale,
  XCircle,
} from "lucide-react";

type LawyerRow = {
  id: string;
  fullName: string;
  phone: string;
  email: string;
  isActive: boolean;
  pendingAmountIls: number;
  pendingCalls: number;
  inPayoutAmountIls: number;
  inPayoutCalls: number;
  paidAmountIls: number;
  paidCalls: number;
  activitySeconds: number;
  rates: { baseFee: number; overtimeShare: number };
  payout: {
    method?: string;
    paypal_email?: string | null;
    bank_holder_name?: string;
    bank_name?: string;
    bank_iban?: string;
    bank_branch?: string;
    bank_account?: string;
    notes?: string;
    custom_call_fee_ils?: number | null;
    custom_overtime_share?: number | null;
  } | null;
};

type EarningRow = {
  id: string;
  eventId: string;
  callCompletedAt: string | null;
  durationSeconds: number;
  baseFeeIls: number;
  overtimeShareIls: number;
  lawyerAmountIls: number;
  chargeStatus: string | null;
  status: string;
};

type BatchRow = {
  id: string;
  lawyerId: string;
  lawyerName: string;
  amountIls: number;
  callsCount: number;
  status: string;
  paymentMethod: string;
  paymentRef: string;
  paidAt: string | null;
  createdAt: string;
};

type Settings = {
  callFeeIls: number;
  overtimeShare: number;
  consultationIls: number;
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

function fmtDuration(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export function LawyerPayoutsPanel() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [lawyers, setLawyers] = useState<LawyerRow[]>([]);
  const [batches, setBatches] = useState<BatchRow[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [earnings, setEarnings] = useState<EarningRow[]>([]);
  const [selectedEarnings, setSelectedEarnings] = useState<Set<string>>(
    new Set(),
  );
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [fallbackMode, setFallbackMode] = useState(false);
  const [paymentRef, setPaymentRef] = useState("");
  const [profileDraft, setProfileDraft] = useState({
    method: "manual",
    paypal_email: "",
    bank_holder_name: "",
    bank_name: "",
    bank_iban: "",
    bank_branch: "",
    bank_account: "",
    notes: "",
    custom_call_fee_ils: "",
    custom_overtime_share: "",
  });
  const [lawyerDraft, setLawyerDraft] = useState({
    full_name: "",
    phone: "",
    email: "",
  });

  const selected = lawyers.find((l) => l.id === selectedId) || null;

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [lawyersRes, batchesRes] = await Promise.all([
        authFetch("/api/admin/finance/lawyers"),
        authFetch("/api/admin/finance/payouts"),
      ]);
      if (!lawyersRes.ok) {
        const err = (await lawyersRes.json().catch(() => null)) as {
          error?: string;
        } | null;
        throw new Error(err?.error || `טעינת עו״ד נכשלה (${lawyersRes.status})`);
      }
      const lawyersBody = (await lawyersRes.json()) as {
        data?: {
          lawyers?: LawyerRow[];
          settings?: Settings;
          source?: string;
        };
      };
      const nextLawyers = lawyersBody.data?.lawyers ?? [];
      setLawyers(nextLawyers);
      setSettings(lawyersBody.data?.settings ?? null);
      setFallbackMode(lawyersBody.data?.source === "fallback-activity");
      setSelectedId((prev) => {
        if (prev && nextLawyers.some((l) => l.id === prev)) return prev;
        return nextLawyers[0]?.id ?? null;
      });

      if (batchesRes.ok) {
        const b = (await batchesRes.json()) as {
          data?: { batches?: BatchRow[] };
        };
        setBatches(b.data?.batches ?? []);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "טעינה נכשלה");
      setLawyers([]);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadEarnings = useCallback(async (lawyerId: string) => {
    const res = await authFetch(
      `/api/admin/finance/lawyers/${encodeURIComponent(lawyerId)}/earnings`,
    );
    if (!res.ok) {
      setEarnings([]);
      return;
    }
    const body = (await res.json()) as { data?: { earnings?: EarningRow[] } };
    setEarnings(body.data?.earnings ?? []);
    setSelectedEarnings(new Set());
  }, []);

  const sync = useCallback(
    async (opts?: { quiet?: boolean }) => {
      if (!opts?.quiet) {
        setBusy(true);
        setMsg(null);
        setError(null);
      }
      try {
        const res = await authFetch("/api/admin/finance/lawyer-earnings/sync", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: "{}",
        });
        const body = (await res.json().catch(() => ({}))) as {
          error?: string;
          data?: { scanned?: number; upserted?: number; source?: string };
        };
        if (!res.ok) throw new Error(body.error || "סנכרון נכשל");
        if (body.data?.source === "fallback-activity") {
          setFallbackMode(true);
        } else {
          setFallbackMode(false);
        }
        if (!opts?.quiet) {
          setMsg(
            `סונכרנו ${body.data?.upserted ?? 0} מתוך ${body.data?.scanned ?? 0} שיחות.`,
          );
        }
        await load();
      } catch (e) {
        if (!opts?.quiet) {
          setError(e instanceof Error ? e.message : "סנכרון נכשל");
        }
      } finally {
        if (!opts?.quiet) setBusy(false);
      }
    },
    [load],
  );

  useEffect(() => {
    // Deferred so the loading-state write lands after this render commits.
    queueMicrotask(() => void load());
  }, [load]);

  const autoSyncedRef = useRef(false);
  useEffect(() => {
    if (
      loading ||
      fallbackMode ||
      lawyers.length === 0 ||
      autoSyncedRef.current
    ) {
      return;
    }
    autoSyncedRef.current = true;
    void sync({ quiet: true });
  }, [loading, fallbackMode, lawyers.length, sync]);

  // Deferred: repopulating the drafts is a state write, and doing it straight
  // from the effect body cascades a second render on every lawyer selection.
  useEffect(() => {
    queueMicrotask(() => {
      if (!selectedId) {
        setEarnings([]);
        return;
      }
      void loadEarnings(selectedId);
      const row = lawyers.find((l) => l.id === selectedId);
      const p = row?.payout;
      setLawyerDraft({
        full_name: row?.fullName || "",
        phone: row?.phone || "",
        email: row?.email || "",
      });
      setProfileDraft({
        method: p?.method || "manual",
        paypal_email: p?.paypal_email || "",
        bank_holder_name: p?.bank_holder_name || "",
        bank_name: p?.bank_name || "",
        bank_iban: p?.bank_iban || "",
        bank_branch: p?.bank_branch || "",
        bank_account: p?.bank_account || "",
        notes: p?.notes || "",
        custom_call_fee_ils:
          p?.custom_call_fee_ils != null ? String(p.custom_call_fee_ils) : "",
        custom_overtime_share:
          p?.custom_overtime_share != null
            ? String(p.custom_overtime_share)
            : "",
      });
    });
  }, [selectedId, lawyers, loadEarnings]);

  const saveLawyerDetails = async () => {
    if (!selectedId) return;
    setBusy(true);
    setMsg(null);
    setError(null);
    try {
      const res = await authFetch(
        `/api/admin/lawyers/${encodeURIComponent(selectedId)}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            full_name: lawyerDraft.full_name.trim(),
            phone: lawyerDraft.phone.trim(),
            email: lawyerDraft.email.trim() || null,
          }),
        },
      );
      if (!res.ok) {
        const t = await res.text().catch(() => "");
        throw new Error(t || `שמירת פרטי עו״ד נכשלה (${res.status})`);
      }
      setMsg("פרטי עורך הדין עודכנו.");
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "שמירת פרטים נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const createPayout = async () => {
    if (!selectedId) return;
    setBusy(true);
    setMsg(null);
    try {
      const earningIds = [...selectedEarnings];
      const res = await authFetch("/api/admin/finance/payouts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          lawyerId: selectedId,
          earningIds: earningIds.length ? earningIds : undefined,
          paymentMethod: profileDraft.method || "manual",
        }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        error?: string;
        data?: { amountIls?: number; callsCount?: number };
      };
      if (!res.ok) throw new Error(body.error || "יצירת תשלום נכשלה");
      setMsg(
        `נוצרה אצוות תשלום: ${ils(body.data?.amountIls || 0)} עבור ${body.data?.callsCount || 0} שיחות.`,
      );
      await load();
      await loadEarnings(selectedId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "יצירת תשלום נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const markPaid = async (batch: BatchRow) => {
    // Irreversible: the server refuses to cancel a batch once it is paid.
    if (
      !window.confirm(
        `לסמן ${ils(batch.amountIls)} עבור ${batch.lawyerName || "עורך הדין"} כשולם?\n` +
          "פעולה זו אינה הפיכה — לא ניתן לבטל אצווה ששולמה.",
      )
    ) {
      return;
    }
    const batchId = batch.id;
    setBusy(true);
    setMsg(null);
    try {
      const res = await authFetch(
        `/api/admin/finance/payouts/${encodeURIComponent(batchId)}/paid`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ paymentRef }),
        },
      );
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) throw new Error(body.error || "סימון שולם נכשל");
      setMsg("התשלום סומן כשולם.");
      setPaymentRef("");
      await load();
      if (selectedId) await loadEarnings(selectedId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "סימון שולם נכשל");
    } finally {
      setBusy(false);
    }
  };

  const cancelBatch = async (batchId: string) => {
    if (!window.confirm("לבטל את אצוות התשלום ולהחזיר את הזכאויות להמתנה?")) {
      return;
    }
    setBusy(true);
    try {
      const res = await authFetch(
        `/api/admin/finance/payouts/${encodeURIComponent(batchId)}/cancel`,
        { method: "PATCH", headers: { "Content-Type": "application/json" }, body: "{}" },
      );
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) throw new Error(body.error || "ביטול נכשל");
      setMsg("האצווה בוטלה.");
      await load();
      if (selectedId) await loadEarnings(selectedId);
    } catch (e) {
      setError(e instanceof Error ? e.message : "ביטול נכשל");
    } finally {
      setBusy(false);
    }
  };

  const saveProfile = async () => {
    if (!selectedId) return;
    setBusy(true);
    setMsg(null);
    try {
      const payload: Record<string, unknown> = {
        method: profileDraft.method,
        paypal_email: profileDraft.paypal_email || null,
        bank_holder_name: profileDraft.bank_holder_name,
        bank_name: profileDraft.bank_name,
        bank_iban: profileDraft.bank_iban,
        bank_branch: profileDraft.bank_branch,
        bank_account: profileDraft.bank_account,
        notes: profileDraft.notes,
      };
      if (profileDraft.custom_call_fee_ils.trim() !== "") {
        payload.custom_call_fee_ils = Number(profileDraft.custom_call_fee_ils);
      } else {
        payload.custom_call_fee_ils = null;
      }
      if (profileDraft.custom_overtime_share.trim() !== "") {
        payload.custom_overtime_share = Number(
          profileDraft.custom_overtime_share,
        );
      } else {
        payload.custom_overtime_share = null;
      }
      const res = await authFetch(
        `/api/admin/finance/lawyers/${encodeURIComponent(selectedId)}/payout-profile`,
        {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) throw new Error(body.error || "שמירת פרטי תשלום נכשלה");
      setMsg("פרטי תשלום לעו״ד נשמרו.");
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "שמירה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const exportCsv = async () => {
    if (!selectedId) return;
    setBusy(true);
    try {
      const res = await authFetch(
        `/api/admin/finance/lawyer-earnings/export?lawyerId=${encodeURIComponent(selectedId)}`,
      );
      if (!res.ok) {
        const err = (await res.json().catch(() => null)) as { error?: string } | null;
        throw new Error(err?.error || "ייצוא נכשל");
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `lawyer-earnings-${selectedId.slice(-6)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      setError(e instanceof Error ? e.message : "ייצוא נכשל");
    } finally {
      setBusy(false);
    }
  };

  const pendingEarnings = earnings.filter((e) => e.status === "pending");
  const toggleEarning = (id: string) => {
    setSelectedEarnings((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 className="flex items-center gap-2 font-frank text-xl font-black text-primary">
            <Scale className="h-5 w-5 text-brand-text" aria-hidden />
            תשלומים לעורכי דין
          </h2>
          <p className="mt-1 text-sm text-muted">
            חישוב לפי פעילות (שיחות שהושלמו) + חלק מדקות נוספות. ברירת מחדל:{" "}
            {settings
              ? `${ils(settings.callFeeIls)} לשיחה + ${Math.round(settings.overtimeShare * 100)}% מחיוב overtime`
              : "…"}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            variant="secondary"
            size="sm"
            disabled={busy || loading}
            onClick={() => void load()}
            iconStart={<RefreshCw className="h-4 w-4" aria-hidden />}
          >
            רענון
          </Button>
          <Button
            variant="primary"
            size="sm"
            disabled={busy}
            onClick={() => void sync()}
          >
            סנכרון משיחות
          </Button>
        </div>
      </div>

      {fallbackMode ? (
        <p
          className="rounded-xl border border-warning-border bg-warning-soft px-3 py-2 text-sm font-semibold text-warning-on-soft"
          role="status"
        >
          מצב תצוגה זמני לפי יומני חירום — ה-API של תשלומים לא זמין בשרת המחובר כרגע.
          להפעלה מלאה: הריצו backend מקומי מעודכן (localhost:5001) או פרסו את ה-backend
          ל-Render. בינתיים אפשר לערוך פרטי עו״ד ופרטי תשלום.
        </p>
      ) : null}
      {error ? (
        <div
          className="rounded-2xl border border-danger-border bg-danger-soft px-4 py-3 text-sm font-semibold text-danger-on-soft"
          role="alert"
        >
          {error}
        </div>
      ) : null}
      {msg ? (
        <p className="text-sm font-semibold text-success" role="status">
          {msg}
        </p>
      ) : null}

      <div className="grid gap-4 lg:grid-cols-[1.1fr_1.4fr]">
        <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-4">
          <h3 className="text-sm font-black text-primary">עורכי דין — יתרות</h3>
          <div
            className="mt-3 max-h-[28rem] overflow-auto"
            tabIndex={0}
            role="region"
            aria-label="עורכי דין — יתרות"
          >
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-subtle text-xs text-muted">
                  <th className="px-2 py-2 text-start">עו״ד</th>
                  <th className="px-2 py-2 text-start">ממתין</th>
                  <th className="px-2 py-2 text-start">שולם</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={3} className="px-2 py-8 text-center text-muted">
                      טוען…
                    </td>
                  </tr>
                ) : lawyers.length === 0 ? (
                  <tr>
                    <td colSpan={3} className="px-2 py-8 text-center text-muted">
                      אין עורכי דין או שסנכרון נדרש.
                    </td>
                  </tr>
                ) : (
                  lawyers.map((l) => (
                    <tr
                      key={l.id}
                      role="button"
                      tabIndex={0}
                      // role="button" does not support aria-selected; the
                      // supported way to expose a sticky on/off state is aria-pressed.
                      aria-pressed={selectedId === l.id}
                      className={`cursor-pointer border-b border-subtle/50 outline-none focus-visible:ring-2 focus-visible:ring-veto-gold ${
                        selectedId === l.id ? "bg-veto-gold/10" : "hover:bg-hover-overlay"
                      }`}
                      onClick={() => setSelectedId(l.id)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" || e.key === " ") {
                          e.preventDefault();
                          setSelectedId(l.id);
                        }
                      }}
                    >
                      <td className="px-2 py-2">
                        <p className="font-bold text-primary">{l.fullName || "—"}</p>
                        <p className="text-xs text-muted">{l.phone}</p>
                      </td>
                      <td className="px-2 py-2 font-bold text-primary">
                        {ils(l.pendingAmountIls)}
                        <span className="block text-xs font-medium text-muted">
                          {l.pendingCalls} שיחות
                        </span>
                      </td>
                      <td className="px-2 py-2 text-secondary">
                        {ils(l.paidAmountIls)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>

        <section className="space-y-4">
          {!selected ? (
            <div className="rounded-2xl border border-subtle bg-surface-raised/80 p-8 text-center text-sm text-muted">
              {loading
                ? "טוען עורכי דין…"
                : "בחרו עורך דין מהרשימה כדי לנהל פרטים, זכאויות ותשלומים."}
            </div>
          ) : (
            <>
              <article className="rounded-2xl border border-subtle bg-surface-raised/80 p-4">
                <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                  <h3 className="flex items-center gap-2 text-sm font-black text-primary">
                    <Pencil className="h-4 w-4 text-brand-text" aria-hidden />
                    פרטי עורך דין
                  </h3>
                  <Link
                    href="/admin/lawyers"
                    className="text-xs font-bold text-brand-text hover:underline"
                  >
                    ניהול מלא בעמוד עורכי דין
                  </Link>
                </div>
                <div className="grid gap-2 sm:grid-cols-3">
                  <label className="text-xs font-bold text-muted">
                    שם מלא
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={lawyerDraft.full_name}
                      onChange={(e) =>
                        setLawyerDraft((d) => ({
                          ...d,
                          full_name: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    טלפון
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={lawyerDraft.phone}
                      onChange={(e) =>
                        setLawyerDraft((d) => ({ ...d, phone: e.target.value }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    אימייל
                    <input
                      type="email"
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={lawyerDraft.email}
                      onChange={(e) =>
                        setLawyerDraft((d) => ({ ...d, email: e.target.value }))
                      }
                    />
                  </label>
                </div>
                <div className="mt-3">
                  <Button
                    variant="secondary"
                    size="sm"
                    disabled={busy || !lawyerDraft.full_name.trim()}
                    onClick={() => void saveLawyerDetails()}
                  >
                    שמירת פרטי עו״ד
                  </Button>
                </div>
              </article>

              <article className="rounded-2xl border border-subtle bg-surface-raised/80 p-4">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <h3 className="font-frank text-lg font-black text-primary">
                      {selected.fullName}
                    </h3>
                    <p className="text-sm text-muted">
                      ממתין: {ils(selected.pendingAmountIls)} · באצווה:{" "}
                      {ils(selected.inPayoutAmountIls)} · שולם:{" "}
                      {ils(selected.paidAmountIls)}
                    </p>
                    <p className="text-xs text-muted">
                      תעריף: {ils(selected.rates.baseFee)} / שיחה ·{" "}
                      {Math.round(selected.rates.overtimeShare * 100)}% overtime
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button
                      variant="secondary"
                      size="sm"
                      disabled={
                        busy ||
                        pendingEarnings.length === 0 ||
                        fallbackMode
                      }
                      onClick={() => void createPayout()}
                      iconStart={<Banknote className="h-4 w-4" aria-hidden />}
                    >
                      {selectedEarnings.size
                        ? `צור תשלום (${selectedEarnings.size})`
                        : "צור תשלום לכל הממתין"}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled={busy || fallbackMode}
                      onClick={() => void exportCsv()}
                      iconStart={<Download className="h-4 w-4" aria-hidden />}
                    >
                      CSV
                    </Button>
                  </div>
                </div>

                <div
                  className="mt-4 max-h-64 overflow-auto"
                  tabIndex={0}
                  role="region"
                  aria-label="זכאויות לתשלום"
                >
                  <table className="w-full min-w-[520px] text-sm">
                    <thead>
                      <tr className="border-b border-subtle text-xs text-muted">
                        {/* Selection column. An empty <th> leaves the row
                            checkboxes with no column name in a screen reader —
                            label it and hide the text visually. */}
                        <th className="px-1 py-2">
                          <span className="sr-only">בחירה לתשלום</span>
                        </th>
                        <th className="px-2 py-2 text-start">תאריך</th>
                        <th className="px-2 py-2 text-start">משך</th>
                        <th className="px-2 py-2 text-start">בסיס</th>
                        <th className="px-2 py-2 text-start">OT</th>
                        <th className="px-2 py-2 text-start">לעו״ד</th>
                        <th className="px-2 py-2 text-start">סטטוס</th>
                      </tr>
                    </thead>
                    <tbody>
                      {earnings.length === 0 ? (
                        <tr>
                          <td
                            colSpan={7}
                            className="px-2 py-6 text-center text-muted"
                          >
                            אין זכאויות. לחצו «סנכרון משיחות».
                          </td>
                        </tr>
                      ) : (
                        earnings.map((e) => (
                          <tr key={e.id} className="border-b border-subtle/50">
                            <td className="px-1 py-2">
                              {e.status === "pending" ? (
                                <input
                                  type="checkbox"
                                  checked={selectedEarnings.has(e.id)}
                                  onChange={() => toggleEarning(e.id)}
                                  aria-label="בחירה לתשלום"
                                />
                              ) : null}
                            </td>
                            <td className="px-2 py-2 text-secondary">
                              {fmtDate(e.callCompletedAt)}
                            </td>
                            <td className="px-2 py-2 text-secondary">
                              {fmtDuration(e.durationSeconds)}
                            </td>
                            <td className="px-2 py-2">{ils(e.baseFeeIls)}</td>
                            <td className="px-2 py-2">{ils(e.overtimeShareIls)}</td>
                            <td className="px-2 py-2 font-bold">
                              {ils(e.lawyerAmountIls)}
                            </td>
                            <td className="px-2 py-2 text-xs text-muted">
                              {e.status}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              </article>

              <article className="rounded-2xl border border-subtle bg-surface-raised/80 p-4">
                <h3 className="text-sm font-black text-primary">
                  פרטי העברת כספים לעו״ד
                </h3>
                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  <label className="text-xs font-bold text-muted">
                    שיטת תשלום
                    <select
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.method}
                      onChange={(e) =>
                        setProfileDraft((d) => ({ ...d, method: e.target.value }))
                      }
                    >
                      <option value="manual">ידני</option>
                      <option value="bank_transfer">העברה בנקאית</option>
                      <option value="paypal">PayPal</option>
                      <option value="bit">Bit</option>
                    </select>
                  </label>
                  <label className="text-xs font-bold text-muted">
                    אימייל PayPal
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.paypal_email}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          paypal_email: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    שם בעל החשבון
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.bank_holder_name}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          bank_holder_name: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    בנק
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.bank_name}
                      onChange={(e) =>
                        setProfileDraft((d) => ({ ...d, bank_name: e.target.value }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    סניף
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.bank_branch}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          bank_branch: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    מספר חשבון
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.bank_account}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          bank_account: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted sm:col-span-2">
                    IBAN
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.bank_iban}
                      onChange={(e) =>
                        setProfileDraft((d) => ({ ...d, bank_iban: e.target.value }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    תעריף שיחה מותאם (₪, ריק=ברירת מחדל)
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.custom_call_fee_ils}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          custom_call_fee_ils: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted">
                    חלק overtime מותאם (0–1)
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.custom_overtime_share}
                      onChange={(e) =>
                        setProfileDraft((d) => ({
                          ...d,
                          custom_overtime_share: e.target.value,
                        }))
                      }
                    />
                  </label>
                  <label className="text-xs font-bold text-muted sm:col-span-2">
                    הערות תשלום
                    <input
                      className="mt-1 min-h-10 w-full rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
                      value={profileDraft.notes}
                      onChange={(e) =>
                        setProfileDraft((d) => ({ ...d, notes: e.target.value }))
                      }
                    />
                  </label>
                </div>
                <div className="mt-3">
                  <Button
                    variant="secondary"
                    size="sm"
                    disabled={busy}
                    onClick={() => void saveProfile()}
                  >
                    שמירת פרטי תשלום
                  </Button>
                </div>
              </article>
            </>
          )}
        </section>
      </div>

      <section className="rounded-2xl border border-subtle bg-surface-raised/80 p-4">
        <h3 className="text-sm font-black text-primary">אצוות תשלום</h3>
        <div className="mt-3 flex flex-wrap items-end gap-2">
          <label className="text-xs font-bold text-muted">
            אסמכתא לתשלום (לסימון שולם)
            <input
              className="mt-1 min-h-10 w-64 rounded-xl border border-subtle bg-white/[0.04] px-2 text-sm text-primary"
              value={paymentRef}
              onChange={(e) => setPaymentRef(e.target.value)}
              placeholder="מס׳ העברה / PayPal"
            />
          </label>
        </div>
        {/* tabIndex + role: a scroll container that only responds to swipe or
            wheel is unreachable by keyboard (WCAG 2.1.1 / EN 301 549 9.2.1.1).
            Making it a focusable region lets arrow keys scroll it. */}
        <div
          className="mt-3 overflow-x-auto"
          tabIndex={0}
          role="region"
          aria-label="אצוות תשלום"
        >
          <table className="w-full min-w-[640px] text-sm">
            <thead>
              <tr className="border-b border-subtle text-xs text-muted">
                <th className="px-2 py-2 text-start">תאריך</th>
                <th className="px-2 py-2 text-start">עו״ד</th>
                <th className="px-2 py-2 text-start">סכום</th>
                <th className="px-2 py-2 text-start">שיחות</th>
                <th className="px-2 py-2 text-start">סטטוס</th>
                <th className="px-2 py-2 text-start">פעולות</th>
              </tr>
            </thead>
            <tbody>
              {batches.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-2 py-6 text-center text-muted">
                    אין אצוות עדיין.
                  </td>
                </tr>
              ) : (
                batches.map((b) => (
                  <tr key={b.id} className="border-b border-subtle/50">
                    <td className="px-2 py-2 text-secondary">
                      {fmtDate(b.createdAt)}
                    </td>
                    <td className="px-2 py-2 font-bold text-primary">
                      {b.lawyerName || b.lawyerId.slice(-6)}
                    </td>
                    <td className="px-2 py-2">{ils(b.amountIls)}</td>
                    <td className="px-2 py-2">{b.callsCount}</td>
                    <td className="px-2 py-2 text-xs">
                      {b.status}
                      {b.paymentRef ? (
                        <span className="block text-muted">{b.paymentRef}</span>
                      ) : null}
                    </td>
                    <td className="px-2 py-2">
                      <div className="flex flex-wrap gap-1">
                        {b.status === "pending" ? (
                          <>
                            <Button
                              variant="primary"
                              size="sm"
                              disabled={busy}
                              onClick={() => void markPaid(b)}
                              iconStart={
                                <CheckCircle2 className="h-3.5 w-3.5" aria-hidden />
                              }
                            >
                              סמן שולם
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              className="text-danger"
                              disabled={busy}
                              onClick={() => void cancelBatch(b.id)}
                              iconStart={
                                <XCircle className="h-3.5 w-3.5" aria-hidden />
                              }
                            >
                              בטל
                            </Button>
                          </>
                        ) : (
                          <span className="text-xs text-muted">
                            {b.paidAt ? fmtDate(b.paidAt) : "—"}
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
