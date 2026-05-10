"use client";

import {
  CheckCircle2,
  ChevronLeft,
  Plus,
  RefreshCw,
  Search,
  Trash2,
  XCircle,
} from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { getJwt } from "@/lib/authToken";

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
  createdAt?: string;
};

const SPECIALIZATION_OPTIONS = [
  "criminal",
  "family",
  "real estate",
  "labor",
  "commercial",
  "traffic",
] as const;

const SPEC_LABEL: Record<string, string> = {
  criminal: "פלילי",
  family: "משפחה",
  "real estate": "נדל״ן",
  labor: "עבודה",
  commercial: "מסחרי",
  traffic: "תעבורה",
};

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

async function createLawyer(body: {
  full_name: string;
  phone: string;
  email?: string;
  license_number?: string;
  specializations?: string[];
  years_of_experience?: number;
}) {
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
  const res = await fetch(`/api/admin/lawyers/${encodeURIComponent(id)}/approve`, {
    method: "PUT",
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error(`approve failed (${res.status})`);
}

async function deleteLawyer(id: string) {
  const res = await fetch(`/api/admin/lawyers/${encodeURIComponent(id)}`, {
    method: "DELETE",
    headers: authHeaders(),
  });
  if (!res.ok) throw new Error(`delete failed (${res.status})`);
}

export default function AdminLawyersPage() {
  const [list, setList] = useState<Lawyer[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [okMsg, setOkMsg] = useState<string | null>(null);
  const [errMsg, setErrMsg] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | "pending" | "approved">("all");

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
    void refresh();
  }, [refresh]);

  const filtered = useMemo(() => {
    if (!list) return [];
    const q = search.trim().toLowerCase();
    return list.filter((l) => {
      if (filter === "pending" && l.is_approved) return false;
      if (filter === "approved" && !l.is_approved) return false;
      if (!q) return true;
      const hay = [l.full_name, l.phone, l.email, l.license_number]
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
    <div className="min-h-screen bg-slate-950 p-6 md:p-10" dir="rtl">
      <header className="mx-auto mb-6 flex max-w-6xl items-center justify-between">
        <div>
          <Link
            href="/admin/dashboard"
            className="mb-2 inline-flex items-center gap-1 text-xs text-slate-400 hover:text-slate-200"
          >
            <ChevronLeft size={14} aria-hidden /> חזרה למרכז שליטה
          </Link>
          <h1 className="font-serif text-3xl font-bold text-slate-100">ניהול עורכי דין</h1>
          <p className="text-sm text-slate-500">
            הוספה, אישור, עריכה ומחיקה של עורכי דין במערכת.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void refresh()}
          aria-label="רענון"
          className="rounded-full border border-white/10 bg-white/[0.04] p-2 text-slate-200 hover:bg-white/[0.08]"
        >
          <RefreshCw className={`h-5 w-5 ${loading ? "animate-spin" : ""}`} aria-hidden />
        </button>
      </header>

      <div className="mx-auto max-w-6xl space-y-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[240px]">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="search"
              placeholder="חיפוש שם, טלפון, מספר רישיון…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full rounded-lg border border-white/10 bg-slate-950 py-2 pl-4 pr-10 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
            />
          </div>
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as typeof filter)}
            className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100"
          >
            <option value="all">הכל</option>
            <option value="pending">ממתינים לאישור</option>
            <option value="approved">מאושרים</option>
          </select>
          <button
            type="button"
            onClick={() => setShowCreate((v) => !v)}
            className="inline-flex items-center gap-2 rounded-lg bg-[#C5A059] px-4 py-2 text-sm font-bold text-black hover:bg-[#b08d4a]"
          >
            <Plus size={16} aria-hidden /> הוספת עורך דין
          </button>
        </div>

        {okMsg && (
          <div role="status" className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
            {okMsg}
          </div>
        )}
        {errMsg && (
          <div role="alert" className="rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-200">
            {errMsg}
          </div>
        )}

        {showCreate && (
          <CreateLawyerForm
            onClose={() => setShowCreate(false)}
            onCreated={async () => {
              setShowCreate(false);
              setOkMsg("עורך הדין נוסף ואושר אוטומטית");
              await refresh();
            }}
            onError={(m) => setErrMsg(m)}
          />
        )}

        <div className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.04]">
          <div className="overflow-x-auto">
            <table className="w-full text-right">
              <thead>
                <tr className="border-b border-white/10 bg-slate-950 text-xs uppercase tracking-wider text-slate-500">
                  <th className="p-4 font-bold">שם / טלפון</th>
                  <th className="p-4 text-center font-bold">תחומי התמחות</th>
                  <th className="p-4 text-center font-bold">רישיון / ותק</th>
                  <th className="p-4 text-center font-bold">סטטוס</th>
                  <th className="p-4 text-center font-bold">פעולות</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {filtered.map((l) => {
                  const isBusy = busyId === l._id;
                  return (
                    <tr key={l._id} className="hover:bg-white/[0.04]">
                      <td className="p-4">
                        <div className="font-bold text-slate-100">{l.full_name || "—"}</div>
                        <div className="text-xs text-slate-500">{l.phone || l.email || "—"}</div>
                      </td>
                      <td className="p-4 text-center text-xs text-slate-300">
                        {(l.specializations || []).length === 0
                          ? "—"
                          : l.specializations!
                              .map((s) => SPEC_LABEL[s] || s)
                              .join(", ")}
                      </td>
                      <td className="p-4 text-center text-xs text-slate-400">
                        {l.license_number || "—"}
                        <br />
                        <span className="text-[10px]">
                          {l.years_of_experience ?? 0} שנות ותק
                        </span>
                      </td>
                      <td className="p-4 text-center">
                        <div className="flex flex-col items-center gap-1 text-[11px]">
                          <span
                            className={`rounded px-2 py-0.5 font-bold ${
                              l.is_approved
                                ? "bg-emerald-500/15 text-emerald-300"
                                : "bg-amber-500/15 text-amber-300"
                            }`}
                          >
                            {l.is_approved ? "מאושר" : "ממתין"}
                          </span>
                          <button
                            type="button"
                            disabled={isBusy}
                            onClick={() =>
                              void run(
                                l._id,
                                () => patchLawyer(l._id, { is_available: !l.is_available }),
                                l.is_available ? "סומן כלא זמין" : "סומן כזמין",
                              )
                            }
                            className={`rounded px-2 py-0.5 font-bold ${
                              l.is_available
                                ? "bg-blue-500/15 text-blue-300"
                                : "bg-slate-500/20 text-slate-300"
                            }`}
                          >
                            {l.is_available ? "זמין" : "לא זמין"}
                          </button>
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center justify-center gap-2">
                          {!l.is_approved && (
                            <button
                              type="button"
                              disabled={isBusy}
                              onClick={() =>
                                void run(l._id, () => approveLawyer(l._id), "עורך הדין אושר")
                              }
                              className="inline-flex items-center gap-1 rounded bg-emerald-500/15 px-2 py-1 text-xs font-bold text-emerald-300 hover:bg-emerald-500/25"
                            >
                              <CheckCircle2 size={14} aria-hidden /> אישור
                            </button>
                          )}
                          <button
                            type="button"
                            disabled={isBusy}
                            onClick={() => {
                              if (!confirm(`למחוק את ${l.full_name}?`)) return;
                              void run(l._id, () => deleteLawyer(l._id), "עורך הדין נמחק");
                            }}
                            aria-label="מחק"
                            className="rounded p-1 text-red-400 hover:bg-red-500/10"
                          >
                            <Trash2 size={16} aria-hidden />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 && (
            <p className="p-8 text-center text-slate-500">
              {loading ? "טוען…" : search || filter !== "all" ? "לא נמצאו תוצאות." : "אין עורכי דין להצגה."}
            </p>
          )}
        </div>
      </div>
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
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [license, setLicense] = useState("");
  const [years, setYears] = useState<number>(0);
  const [specs, setSpecs] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);

  const toggle = (s: string) =>
    setSpecs((prev) => (prev.includes(s) ? prev.filter((x) => x !== s) : [...prev, s]));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await createLawyer({
        full_name: name.trim(),
        phone: phone.trim(),
        email: email.trim() || undefined,
        license_number: license.trim() || undefined,
        years_of_experience: Number.isFinite(years) ? years : 0,
        specializations: specs,
      });
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
      className="grid grid-cols-1 gap-3 rounded-2xl border border-white/10 bg-slate-950/40 p-5 md:grid-cols-2"
    >
      <input
        required
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="שם מלא"
        className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      />
      <input
        required
        value={phone}
        onChange={(e) => setPhone(e.target.value)}
        placeholder="טלפון (+972…)"
        className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      />
      <input
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="אימייל (אופציונלי)"
        type="email"
        className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      />
      <input
        value={license}
        onChange={(e) => setLicense(e.target.value)}
        placeholder="מספר רישיון לשכת עוה״ד"
        className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      />
      <input
        type="number"
        min={0}
        max={70}
        value={years}
        onChange={(e) => setYears(Math.max(0, Number(e.target.value) || 0))}
        placeholder="שנות ותק"
        className="rounded-lg border border-white/10 bg-slate-950 px-3 py-2 text-sm text-slate-100 outline-none focus:ring-2 focus:ring-[#C5A059]"
      />
      <div className="md:col-span-2">
        <p className="mb-2 text-xs font-bold text-slate-300">תחומי התמחות</p>
        <div className="flex flex-wrap gap-2">
          {SPECIALIZATION_OPTIONS.map((s) => {
            const on = specs.includes(s);
            return (
              <button
                type="button"
                key={s}
                onClick={() => toggle(s)}
                className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                  on
                    ? "border border-[#C5A059] bg-[#C5A059]/15 text-[#C5A059]"
                    : "border border-white/10 bg-white/[0.03] text-slate-400 hover:bg-white/[0.06]"
                }`}
              >
                {SPEC_LABEL[s]}
              </button>
            );
          })}
        </div>
      </div>
      <div className="md:col-span-2 flex items-center justify-end gap-2">
        <p className="me-auto text-xs text-slate-500">
          עורכי דין שנוצרים ע״י מנהל מאושרים אוטומטית.
        </p>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg border border-white/10 bg-white/[0.04] px-3 py-2 text-xs text-slate-300"
        >
          ביטול
        </button>
        <button
          type="submit"
          disabled={busy}
          className="inline-flex items-center gap-1 rounded-lg bg-[#C5A059] px-4 py-2 text-xs font-bold text-black disabled:opacity-60"
        >
          {busy ? "יוצר…" : (
            <>
              <CheckCircle2 size={14} aria-hidden /> צור עורך דין
            </>
          )}
        </button>
      </div>
      {!busy && specs.length === 0 && (
        <p className="md:col-span-2 inline-flex items-center gap-1 text-xs text-amber-300">
          <XCircle size={12} aria-hidden /> מומלץ לבחור לפחות תחום אחד — אחרת ה-SOS הגנרי לא יסונן אליו.
        </p>
      )}
    </form>
  );
}
