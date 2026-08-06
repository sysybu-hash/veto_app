"use client";

import {
  CheckCircle2,
  ChevronLeft,
  Pencil,
  Plus,
  RefreshCw,
  Search,
  Trash2,
  X,
  XCircle,
} from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";

type Lawyer = {
  _id: string;
  full_name: string;
  phone: string;
  email?: string | null;
  license_number?: string | null;
  specializations?: string[];
  years_of_experience?: number;
  is_available?: boolean;
  is_verified?: boolean;
  is_approved?: boolean;
  is_active?: boolean;
  bio?: string;
  bar_association?: string;
  languages_spoken?: string[];
  preferred_language?: string;
  whatsapp_number?: string | null;
  telegram_username?: string | null;
  payout?: {
    method?: string;
    paypal_email?: string | null;
    bank_holder_name?: string;
    bank_name?: string;
    bank_iban?: string;
    bank_branch?: string;
    bank_account?: string;
    notes?: string;
  } | null;
  createdAt?: string;
};

type LawyerFormState = {
  full_name: string;
  phone: string;
  email: string;
  license_number: string;
  years_of_experience: number;
  specializations: string[];
  bio: string;
  bar_association: string;
  languages_spoken: string[];
  preferred_language: string;
  whatsapp_number: string;
  telegram_username: string;
  is_approved: boolean;
  is_active: boolean;
  is_available: boolean;
  is_verified: boolean;
  payout_method: string;
  paypal_email: string;
  bank_holder_name: string;
  bank_name: string;
  bank_iban: string;
  bank_branch: string;
  bank_account: string;
  payout_notes: string;
};

const SPECIALIZATION_OPTIONS = [
  "criminal",
  "family",
  "real estate",
  "labor",
  "commercial",
  "traffic",
  "notary",
  "general",
] as const;

const SPEC_LABEL: Record<string, string> = {
  criminal: "פלילי",
  family: "משפחה",
  "real estate": "נדל״ן",
  labor: "עבודה",
  commercial: "מסחרי",
  traffic: "תעבורה",
  notary: "נוטריון",
  general: "כללי",
};

const LANG_OPTIONS = [
  { id: "he", label: "עברית" },
  { id: "en", label: "English" },
  { id: "ru", label: "Русский" },
  { id: "ar", label: "العربية" },
] as const;

const emptyForm = (): LawyerFormState => ({
  full_name: "",
  phone: "",
  email: "",
  license_number: "",
  years_of_experience: 0,
  specializations: [],
  bio: "",
  bar_association: "",
  languages_spoken: ["he"],
  preferred_language: "he",
  whatsapp_number: "",
  telegram_username: "",
  is_approved: true,
  is_active: true,
  is_available: true,
  is_verified: true,
  payout_method: "manual",
  paypal_email: "",
  bank_holder_name: "",
  bank_name: "",
  bank_iban: "",
  bank_branch: "",
  bank_account: "",
  payout_notes: "",
});

function lawyerToForm(l: Lawyer): LawyerFormState {
  return {
    full_name: l.full_name || "",
    phone: l.phone || "",
    email: l.email || "",
    license_number: l.license_number || "",
    years_of_experience: l.years_of_experience ?? 0,
    specializations: [...(l.specializations || [])],
    bio: l.bio || "",
    bar_association: l.bar_association || "",
    languages_spoken:
      l.languages_spoken && l.languages_spoken.length
        ? [...l.languages_spoken]
        : ["he"],
    preferred_language: l.preferred_language || "he",
    whatsapp_number: l.whatsapp_number || "",
    telegram_username: l.telegram_username || "",
    is_approved: l.is_approved !== false,
    is_active: l.is_active !== false,
    is_available: !!l.is_available,
    is_verified: l.is_verified !== false,
    payout_method: l.payout?.method || "manual",
    paypal_email: l.payout?.paypal_email || "",
    bank_holder_name: l.payout?.bank_holder_name || "",
    bank_name: l.payout?.bank_name || "",
    bank_iban: l.payout?.bank_iban || "",
    bank_branch: l.payout?.bank_branch || "",
    bank_account: l.payout?.bank_account || "",
    payout_notes: l.payout?.notes || "",
  };
}

function formToPayload(f: LawyerFormState, mode: "create" | "edit") {
  const base: Record<string, unknown> = {
    full_name: f.full_name.trim(),
    phone: f.phone.trim(),
    email: f.email.trim() || undefined,
    license_number: f.license_number.trim() || undefined,
    years_of_experience: Number.isFinite(f.years_of_experience)
      ? f.years_of_experience
      : 0,
    specializations: f.specializations,
    bio: f.bio.trim(),
    bar_association: f.bar_association.trim(),
    languages_spoken: f.languages_spoken,
    preferred_language: f.preferred_language,
    whatsapp_number: f.whatsapp_number.trim() || null,
    telegram_username: f.telegram_username.trim() || null,
  };
  if (mode === "edit") {
    base.is_approved = f.is_approved;
    base.is_active = f.is_active;
    base.is_available = f.is_available;
    base.is_verified = f.is_verified;
    base.payout = {
      method: f.payout_method,
      paypal_email: f.paypal_email.trim() || null,
      bank_holder_name: f.bank_holder_name.trim(),
      bank_name: f.bank_name.trim(),
      bank_iban: f.bank_iban.trim(),
      bank_branch: f.bank_branch.trim(),
      bank_account: f.bank_account.trim(),
      notes: f.payout_notes.trim(),
    };
  }
  return base;
}

function authHeaders(): Record<string, string> {
  const t = getJwt();
  return t ? { Authorization: `Bearer ${t}` } : {};
}

async function listLawyers(): Promise<Lawyer[]> {
  const res = await fetch("/api/admin/lawyers", {
    cache: "no-store",
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error(`list failed (${res.status})`);
  const j = (await res.json()) as { lawyers?: Lawyer[] };
  return j.lawyers ?? [];
}

async function createLawyer(body: Record<string, unknown>) {
  const res = await fetch("/api/admin/lawyers", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const t = await res.text().catch(() => "");
    throw new Error(t || `create failed (${res.status})`);
  }
}

async function patchLawyer(id: string, body: Record<string, unknown>) {
  const res = await fetch(`/api/admin/lawyers/${encodeURIComponent(id)}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const t = await res.text().catch(() => "");
    throw new Error(t || `update failed (${res.status})`);
  }
}

async function approveLawyer(id: string) {
  const res = await fetch(
    `/api/admin/lawyers/${encodeURIComponent(id)}/approve`,
    { method: "PUT", headers: authHeaders() },
  );
  if (!res.ok) throw new Error(`approve failed (${res.status})`);
}

async function deleteLawyer(id: string) {
  const res = await fetch(`/api/admin/lawyers/${encodeURIComponent(id)}`, {
    method: "DELETE",
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error(`delete failed (${res.status})`);
}

const inputClass =
  "w-full rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold";

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block text-xs font-bold text-primary">
      <span className="mb-1 block text-muted">{label}</span>
      {children}
    </label>
  );
}

function SpecPicker({
  specs,
  onToggle,
}: {
  specs: string[];
  onToggle: (s: string) => void;
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {SPECIALIZATION_OPTIONS.map((s) => {
        const on = specs.includes(s);
        return (
          <button
            type="button"
            key={s}
            onClick={() => onToggle(s)}
            className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
              on
                ? "border border-veto-gold bg-veto-gold/15 text-brand-text"
                : "border border-subtle bg-surface-sunken text-secondary hover:bg-hover-overlay"
            }`}
          >
            {SPEC_LABEL[s] || s}
          </button>
        );
      })}
    </div>
  );
}

function LawyerFormFields({
  form,
  setForm,
  mode,
}: {
  form: LawyerFormState;
  setForm: React.Dispatch<React.SetStateAction<LawyerFormState>>;
  mode: "create" | "edit";
}) {
  const toggleSpec = (s: string) =>
    setForm((prev) => ({
      ...prev,
      specializations: prev.specializations.includes(s)
        ? prev.specializations.filter((x) => x !== s)
        : [...prev.specializations, s],
    }));

  const toggleLang = (id: string) =>
    setForm((prev) => {
      const has = prev.languages_spoken.includes(id);
      const next = has
        ? prev.languages_spoken.filter((x) => x !== id)
        : [...prev.languages_spoken, id];
      return {
        ...prev,
        languages_spoken: next.length ? next : ["he"],
      };
    });

  return (
    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
      <Field label="שם מלא *">
        <input
          required
          className={inputClass}
          value={form.full_name}
          onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))}
        />
      </Field>
      <Field label="טלפון *">
        <input
          required
          className={inputClass}
          value={form.phone}
          onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
          placeholder="+972…"
        />
      </Field>
      <Field label="אימייל">
        <input
          type="email"
          className={inputClass}
          value={form.email}
          onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
        />
      </Field>
      <Field label="מספר רישיון">
        <input
          className={inputClass}
          value={form.license_number}
          onChange={(e) =>
            setForm((f) => ({ ...f, license_number: e.target.value }))
          }
        />
      </Field>
      <Field label="לשכת עורכי דין">
        <input
          className={inputClass}
          value={form.bar_association}
          onChange={(e) =>
            setForm((f) => ({ ...f, bar_association: e.target.value }))
          }
          placeholder="לשכת עורכי הדין בישראל"
        />
      </Field>
      <Field label="שנות ותק">
        <input
          type="number"
          min={0}
          max={70}
          className={inputClass}
          value={form.years_of_experience}
          onChange={(e) =>
            setForm((f) => ({
              ...f,
              years_of_experience: Math.max(0, Number(e.target.value) || 0),
            }))
          }
        />
      </Field>
      <Field label="WhatsApp">
        <input
          className={inputClass}
          value={form.whatsapp_number}
          onChange={(e) =>
            setForm((f) => ({ ...f, whatsapp_number: e.target.value }))
          }
          placeholder="+972…"
        />
      </Field>
      <Field label="Telegram">
        <input
          className={inputClass}
          value={form.telegram_username}
          onChange={(e) =>
            setForm((f) => ({ ...f, telegram_username: e.target.value }))
          }
          placeholder="@username"
        />
      </Field>
      <Field label="שפת ממשק מועדפת">
        <select
          className={inputClass}
          value={form.preferred_language}
          onChange={(e) =>
            setForm((f) => ({ ...f, preferred_language: e.target.value }))
          }
        >
          {LANG_OPTIONS.map((l) => (
            <option key={l.id} value={l.id}>
              {l.label}
            </option>
          ))}
        </select>
      </Field>
      <div className="md:col-span-2">
        <p className="mb-1 text-xs font-bold text-muted">שפות דיבור</p>
        <div className="flex flex-wrap gap-2">
          {LANG_OPTIONS.map((l) => {
            const on = form.languages_spoken.includes(l.id);
            return (
              <button
                type="button"
                key={l.id}
                onClick={() => toggleLang(l.id)}
                className={`rounded-full px-3 py-1 text-xs font-semibold ${
                  on
                    ? "border border-veto-gold bg-veto-gold/15 text-brand-text"
                    : "border border-subtle text-secondary"
                }`}
              >
                {l.label}
              </button>
            );
          })}
        </div>
      </div>
      <div className="md:col-span-2">
        <p className="mb-1 text-xs font-bold text-muted">תחומי התמחות</p>
        <SpecPicker specs={form.specializations} onToggle={toggleSpec} />
      </div>
      <div className="md:col-span-2">
        <Field label="ביוגרפיה / אודות">
          <textarea
            rows={3}
            className={inputClass}
            value={form.bio}
            onChange={(e) => setForm((f) => ({ ...f, bio: e.target.value }))}
            maxLength={500}
          />
        </Field>
      </div>

      {mode === "edit" ? (
        <>
          <div className="md:col-span-2 grid grid-cols-2 gap-2 sm:grid-cols-4">
            {(
              [
                ["is_approved", "מאושר"],
                ["is_active", "פעיל"],
                ["is_available", "זמין לקריאות"],
                ["is_verified", "מאומת"],
              ] as const
            ).map(([key, label]) => (
              <label
                key={key}
                className="flex items-center gap-2 rounded-xl border border-subtle bg-surface-sunken px-3 py-2 text-xs font-bold text-primary"
              >
                <input
                  type="checkbox"
                  checked={form[key]}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, [key]: e.target.checked }))
                  }
                />
                {label}
              </label>
            ))}
          </div>

          <div className="md:col-span-2 mt-1 border-t border-subtle pt-3">
            <p className="mb-2 text-sm font-black text-primary">
              פרטי תשלום (להעברות)
            </p>
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
              <Field label="שיטת תשלום">
                <select
                  className={inputClass}
                  value={form.payout_method}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, payout_method: e.target.value }))
                  }
                >
                  <option value="manual">ידני</option>
                  <option value="bank_transfer">העברה בנקאית</option>
                  <option value="paypal">PayPal</option>
                  <option value="bit">Bit</option>
                </select>
              </Field>
              <Field label="אימייל PayPal">
                <input
                  className={inputClass}
                  value={form.paypal_email}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, paypal_email: e.target.value }))
                  }
                />
              </Field>
              <Field label="שם בעל החשבון">
                <input
                  className={inputClass}
                  value={form.bank_holder_name}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, bank_holder_name: e.target.value }))
                  }
                />
              </Field>
              <Field label="בנק">
                <input
                  className={inputClass}
                  value={form.bank_name}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, bank_name: e.target.value }))
                  }
                />
              </Field>
              <Field label="סניף">
                <input
                  className={inputClass}
                  value={form.bank_branch}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, bank_branch: e.target.value }))
                  }
                />
              </Field>
              <Field label="מספר חשבון">
                <input
                  className={inputClass}
                  value={form.bank_account}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, bank_account: e.target.value }))
                  }
                />
              </Field>
              <div className="md:col-span-2">
                <Field label="IBAN">
                  <input
                    className={inputClass}
                    value={form.bank_iban}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, bank_iban: e.target.value }))
                    }
                  />
                </Field>
              </div>
              <div className="md:col-span-2">
                <Field label="הערות תשלום">
                  <input
                    className={inputClass}
                    value={form.payout_notes}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, payout_notes: e.target.value }))
                    }
                  />
                </Field>
              </div>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}

function EditLawyerModal({
  lawyer,
  onClose,
  onSaved,
  onError,
}: {
  lawyer: Lawyer;
  onClose: () => void;
  onSaved: () => Promise<void>;
  onError: (msg: string) => void;
}) {
  const [form, setForm] = useState(() => lawyerToForm(lawyer));
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await patchLawyer(lawyer._id, formToPayload(form, "edit"));
      await onSaved();
    } catch (err) {
      onError(err instanceof Error ? err.message : "שמירה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-[80] flex items-end justify-center bg-black/45 p-3 sm:items-center"
      role="dialog"
      aria-modal
      aria-labelledby="edit-lawyer-title"
    >
      <form
        onSubmit={(e) => void submit(e)}
        className="max-h-[92dvh] w-full max-w-3xl overflow-y-auto rounded-2xl border border-subtle bg-surface-overlay p-5 shadow-modal"
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <h2
              id="edit-lawyer-title"
              className="font-frank text-xl font-black text-primary"
            >
              עריכת עורך דין
            </h2>
            <p className="text-sm text-muted">{lawyer.full_name}</p>
          </div>
          <IconButton
            variant="ghost"
            size="sm"
            onClick={onClose}
            label="סגור"
            icon={<X size={18} aria-hidden />}
          />
        </div>
        <LawyerFormFields form={form} setForm={setForm} mode="edit" />
        <div className="mt-5 flex justify-end gap-2 border-t border-subtle pt-4">
          <Button variant="secondary" type="button" onClick={onClose}>
            ביטול
          </Button>
          <Button
            variant="primary"
            type="submit"
            disabled={busy}
            loading={busy}
            iconStart={<CheckCircle2 size={14} aria-hidden />}
          >
            שמירת פרטים
          </Button>
        </div>
      </form>
    </div>
  );
}

export default function AdminLawyersPage() {
  const [list, setList] = useState<Lawyer[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<Lawyer | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);
  const [errMsg, setErrMsg] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | "pending" | "approved" | "inactive">(
    "all",
  );

  const refresh = useCallback(async () => {
    setLoading(true);
    setErrMsg(null);
    try {
      const data = await listLawyers();
      setList(data);
    } catch (e) {
      setList([]);
      setErrMsg(e instanceof Error ? e.message : "טעינה נכשלה");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(() => void refresh());
  }, [refresh]);

  const filtered = useMemo(() => {
    if (!list) return [];
    const q = search.trim().toLowerCase();
    return list.filter((l) => {
      if (filter === "pending" && l.is_approved) return false;
      if (filter === "approved" && !l.is_approved) return false;
      if (filter === "inactive" && l.is_active !== false) return false;
      if (!q) return true;
      const hay = [
        l.full_name,
        l.phone,
        l.email,
        l.license_number,
        l.bar_association,
        ...(l.specializations || []),
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      return hay.includes(q);
    });
  }, [list, search, filter]);

  const run = async (id: string, fn: () => Promise<void>, ok: string) => {
    setBusyId(id);
    setOkMsg(null);
    setErrMsg(null);
    try {
      await fn();
      setOkMsg(ok);
      await refresh();
    } catch (e) {
      setErrMsg(e instanceof Error ? e.message : "פעולה נכשלה");
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div className="min-h-screen bg-surface-canvas p-4 sm:p-6 md:p-10" dir="rtl">
      <header className="mx-auto mb-6 flex max-w-6xl items-center justify-between">
        <div>
          <Link
            href="/admin/dashboard"
            className="mb-2 inline-flex items-center gap-1 text-xs font-semibold text-muted hover:text-primary"
          >
            <ChevronLeft size={14} aria-hidden /> חזרה למרכז שליטה
          </Link>
          <h1 className="font-serif text-3xl font-bold text-primary">
            ניהול עורכי דין
          </h1>
          <p className="text-sm text-muted">
            הוספה, אישור, עריכת פרטים מלאה, זמינות ומחיקה.
          </p>
        </div>
        <IconButton
          variant="secondary"
          size="md"
          className="rounded-full"
          onClick={() => void refresh()}
          label="רענון"
          icon={
            <RefreshCw
              className={`h-5 w-5 ${loading ? "animate-spin" : ""}`}
              aria-hidden
            />
          }
        />
      </header>

      <div className="mx-auto max-w-6xl space-y-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[240px] flex-1">
            <Search className="pointer-events-none absolute end-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
            <input
              type="search"
              placeholder="חיפוש שם, טלפון, מספר רישיון…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full rounded-lg border border-subtle bg-surface-overlay py-2 pe-10 ps-4 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
            />
          </div>
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as typeof filter)}
            aria-label="סינון לפי סטטוס"
            className="rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary"
          >
            <option value="all">הכל</option>
            <option value="pending">ממתינים לאישור</option>
            <option value="approved">מאושרים</option>
            <option value="inactive">מושבתים</option>
          </select>
          <Button
            variant="primary"
            size="sm"
            onClick={() => setShowCreate((v) => !v)}
            iconStart={<Plus size={16} aria-hidden />}
          >
            הוספת עורך דין
          </Button>
        </div>

        {okMsg ? (
          <div
            role="status"
            className="rounded-lg border border-success-border bg-success-soft p-3 text-sm font-semibold text-success-on-soft"
          >
            {okMsg}
          </div>
        ) : null}
        {errMsg ? (
          <div
            role="alert"
            className="rounded-lg border border-danger-border bg-danger-soft p-3 text-sm font-semibold text-danger-on-soft"
          >
            {errMsg}
          </div>
        ) : null}

        {showCreate ? (
          <CreateLawyerForm
            onClose={() => setShowCreate(false)}
            onCreated={async () => {
              setShowCreate(false);
              setOkMsg("עורך הדין נוסף ואושר אוטומטית");
              await refresh();
            }}
            onError={(m) => setErrMsg(m)}
          />
        ) : null}

        <div className="overflow-hidden rounded-2xl border border-subtle bg-surface-raised/70">
          <div
            className="overflow-x-auto"
            tabIndex={0}
            role="region"
            aria-label="רשימת עורכי דין"
          >
            <table className="w-full text-end">
              <thead>
                <tr className="border-b border-subtle bg-surface-raised text-xs font-bold uppercase tracking-wider text-muted">
                  <th className="p-4">שם / טלפון</th>
                  <th className="p-4 text-center">תחומי התמחות</th>
                  <th className="p-4 text-center">רישיון / ותק</th>
                  <th className="p-4 text-center">סטטוס</th>
                  <th className="p-4 text-center">פעולות</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-subtle">
                {filtered.map((l) => {
                  const isBusy = busyId === l._id;
                  return (
                    <tr key={l._id} className="hover:bg-hover-overlay">
                      <td className="p-4">
                        <div className="font-bold text-primary">
                          {l.full_name || "—"}
                        </div>
                        <div className="text-xs font-medium text-secondary">
                          {l.phone || "—"}
                        </div>
                        {l.email ? (
                          <div className="text-xs text-muted">{l.email}</div>
                        ) : null}
                      </td>
                      <td className="p-4 text-center text-xs font-medium text-secondary">
                        {(l.specializations || []).length === 0
                          ? "—"
                          : l.specializations!
                              .map((s) => SPEC_LABEL[s] || s)
                              .join(", ")}
                      </td>
                      <td className="p-4 text-center text-xs font-medium text-secondary">
                        {l.license_number || "—"}
                        <br />
                        <span className="text-[11px] text-muted">
                          {l.years_of_experience ?? 0} שנות ותק
                        </span>
                      </td>
                      <td className="p-4 text-center">
                        <div className="flex flex-col items-center gap-1 text-[11px] font-bold">
                          <span
                            className={`rounded px-2 py-0.5 ${
                              l.is_approved
                                ? "bg-success-soft text-success-on-soft"
                                : "bg-warning-soft text-warning-on-soft"
                            }`}
                          >
                            {l.is_approved ? "מאושר" : "ממתין"}
                          </span>
                          <span
                            className={`rounded px-2 py-0.5 ${
                              l.is_active !== false
                                ? "bg-info-soft text-info-on-soft"
                                : "bg-danger-soft text-danger-on-soft"
                            }`}
                          >
                            {l.is_active !== false ? "פעיל" : "מושבת"}
                          </span>
                          <span
                            className={`rounded px-2 py-0.5 ${
                              l.is_available
                                ? "bg-brand-soft text-brand-on-soft"
                                : "bg-surface-sunken text-muted"
                            }`}
                          >
                            {l.is_available ? "זמין" : "לא זמין"}
                          </span>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex flex-wrap items-center justify-center gap-1.5">
                          <Button
                            variant="secondary"
                            size="sm"
                            disabled={isBusy}
                            iconStart={<Pencil size={14} aria-hidden />}
                            onClick={() => setEditing(l)}
                          >
                            עריכה
                          </Button>
                          {!l.is_approved ? (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="bg-success-soft text-success-on-soft"
                              disabled={isBusy}
                              iconStart={<CheckCircle2 size={14} aria-hidden />}
                              onClick={() =>
                                void run(
                                  l._id,
                                  () => approveLawyer(l._id),
                                  "עורך הדין אושר",
                                )
                              }
                            >
                              אישור
                            </Button>
                          ) : null}
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={isBusy}
                            onClick={() =>
                              void run(
                                l._id,
                                () =>
                                  patchLawyer(l._id, {
                                    is_available: !l.is_available,
                                  }),
                                l.is_available
                                  ? "סומן כלא זמין"
                                  : "סומן כזמין",
                              )
                            }
                          >
                            {l.is_available ? "השבת זמינות" : "הפעל זמינות"}
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            disabled={isBusy}
                            onClick={() =>
                              void run(
                                l._id,
                                () =>
                                  patchLawyer(l._id, {
                                    is_active: l.is_active === false,
                                  }),
                                l.is_active === false
                                  ? "החשבון הופעל"
                                  : "החשבון הושבת",
                              )
                            }
                          >
                            {l.is_active === false ? "הפעלה" : "השבתה"}
                          </Button>
                          <IconButton
                            variant="ghost"
                            size="sm"
                            className="text-danger-on-soft hover:bg-danger-soft"
                            disabled={isBusy}
                            onClick={() => {
                              if (!confirm(`למחוק את ${l.full_name}?`)) return;
                              void run(
                                l._id,
                                () => deleteLawyer(l._id),
                                "עורך הדין נמחק",
                              );
                            }}
                            label="מחק"
                            icon={<Trash2 size={16} aria-hidden />}
                          />
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 ? (
            <p className="p-8 text-center font-medium text-muted">
              {loading
                ? "טוען…"
                : search || filter !== "all"
                  ? "לא נמצאו תוצאות."
                  : "אין עורכי דין להצגה."}
            </p>
          ) : null}
        </div>
      </div>

      {editing ? (
        <EditLawyerModal
          lawyer={editing}
          onClose={() => setEditing(null)}
          onSaved={async () => {
            setEditing(null);
            setOkMsg("פרטי עורך הדין עודכנו");
            await refresh();
          }}
          onError={(m) => setErrMsg(m)}
        />
      ) : null}
    </div>
  );
}

function CreateLawyerForm({
  onClose,
  onCreated,
  onError,
}: {
  onClose: () => void;
  onCreated: () => Promise<void>;
  onError: (msg: string) => void;
}) {
  const [form, setForm] = useState(emptyForm);
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await createLawyer(formToPayload(form, "create"));
      await onCreated();
    } catch (err) {
      onError(err instanceof Error ? err.message : "יצירה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  return (
    <form
      onSubmit={(e) => void submit(e)}
      className="rounded-2xl border border-subtle bg-surface-raised/80 p-5"
    >
      <div className="mb-3 flex items-center justify-between">
        <h2 className="font-frank text-lg font-black text-primary">
          הוספת עורך דין חדש
        </h2>
        <IconButton
          variant="ghost"
          size="sm"
          onClick={onClose}
          label="סגור"
          icon={<X size={16} aria-hidden />}
        />
      </div>
      <LawyerFormFields form={form} setForm={setForm} mode="create" />
      <div className="mt-4 flex flex-wrap items-center justify-end gap-2">
        <p className="me-auto text-xs text-muted">
          עורכי דין שנוצרים ע״י מנהל מאושרים אוטומטית.
        </p>
        <Button variant="secondary" size="sm" type="button" onClick={onClose}>
          ביטול
        </Button>
        <Button
          variant="primary"
          size="sm"
          type="submit"
          disabled={busy}
          loading={busy}
          iconStart={<CheckCircle2 size={14} aria-hidden />}
        >
          {busy ? "יוצר…" : "צור עורך דין"}
        </Button>
      </div>
      {form.specializations.length === 0 ? (
        <p className="mt-2 inline-flex items-center gap-1 text-xs font-semibold text-warning">
          <XCircle size={12} aria-hidden /> מומלץ לבחור לפחות תחום אחד.
        </p>
      ) : null}
    </form>
  );
}
