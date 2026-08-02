"use client";

import {
  Activity,
  AlertTriangle,
  Clock,
  Database,
  DollarSign,
  Plus,
  RefreshCw,
  Search,
  ShieldCheck,
  Trash2,
  Users,
} from "lucide-react";
import { motion } from "framer-motion";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { authFetch } from "@/api/apiClient";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";
import { IconButton } from "@/components/ui/primitives/IconButton";

type AdminRole = "USER" | "ADMIN";

type AdminUser = {
  id: string;
  externalId: string;
  email: string;
  phone: string;
  name: string;
  role: AdminRole;
  createdAt: string;
  isPro: boolean;
  paymentExempt: boolean;
  isActive: boolean;
  isVerified: boolean;
  subscriptionExpiry: string | null;
  status: string;
};

type DashboardPayload = {
  stats: { users: number; lawyers: number; sos: number };
  users: AdminUser[];
  health: { database: string; api: string; timestamp: string };
};

type CommandCenterEvent = {
  _id: string;
  language?: string;
  status?: string;
  createdAt?: string;
  triggered_at?: string;
};

type CommandCenterData = {
  activeEvents: CommandCenterEvent[];
  stats: {
    dailyEventsCount: number;
    dailyRevenue: number;
    totalLawyers: number;
    activeEventsCount: number;
    lawyersOnline: number;
  };
};

function langLabel(code: string | undefined): string {
  switch (code) {
    case "he":
      return "עברית";
    case "ar":
      return "ערבית";
    case "ru":
      return "רוסית";
    case "en":
      return "אנגלית";
    default:
      return code ?? "—";
  }
}

async function fetchCommandCenter(): Promise<CommandCenterData | null> {
  try {
    const res = await authFetch("/api/admin/stats");
    if (!res.ok) return null;
    const body = (await res.json()) as { data?: CommandCenterData };
    return body.data ?? null;
  } catch (e) {
    console.error("Failed to fetch admin command center stats", e);
    return null;
  }
}

function authHeaders(): Record<string, string> {
  const t = getJwt();
  return t ? { Authorization: `Bearer ${t}` } : {};
}

async function fetchDashboardPayload(): Promise<DashboardPayload | null> {
  const res = await fetch("/api/admin/dashboard", {
    credentials: "include",
    cache: "no-store",
    headers: authHeaders(),
  });
  if (!res.ok) return null;
  return (await res.json()) as DashboardPayload;
}

async function patchUser(id: string, body: Record<string, unknown>) {
  const res = await fetch(`/api/admin/users/${encodeURIComponent(id)}`, {
    method: "PUT",
    credentials: "include",
    cache: "no-store",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.text().catch(() => "");
    throw new Error(err || `update failed (${res.status})`);
  }
}

async function deleteUser(id: string) {
  const res = await fetch(`/api/admin/users/${encodeURIComponent(id)}`, {
    method: "DELETE",
    credentials: "include",
    cache: "no-store",
    headers: authHeaders(),
  });
  if (!res.ok) {
    const err = await res.text().catch(() => "");
    throw new Error(err || `delete failed (${res.status})`);
  }
}

async function createUser(body: {
  full_name: string;
  phone: string;
  email?: string;
  role: "user" | "admin";
  manually_added?: boolean;
}) {
  const res = await fetch("/api/admin/users", {
    method: "POST",
    credentials: "include",
    cache: "no-store",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.text().catch(() => "");
    throw new Error(err || `create failed (${res.status})`);
  }
  return (await res.json()) as { user: { _id: string } };
}

export default function VetoMasterDashboard() {
  const [data, setData] = useState<DashboardPayload | null>(null);
  const [commandCenter, setCommandCenter] = useState<CommandCenterData | null>(null);
  const [commandCenterLoading, setCommandCenterLoading] = useState(true);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [actionMsg, setActionMsg] = useState<string | null>(null);
  const [actionErr, setActionErr] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const payload = await fetchDashboardPayload();
      setData(payload);
    } catch (err) {
      console.error(err);
      setData(null);
    } finally {
      setLoading(false);
    }
  }, []);

  const refreshCommandCenter = useCallback(async () => {
    setCommandCenterLoading(true);
    try {
      const cc = await fetchCommandCenter();
      setCommandCenter(cc);
    } finally {
      setCommandCenterLoading(false);
    }
  }, []);

  useEffect(() => {
    queueMicrotask(() => void refresh());
  }, [refresh]);

  useEffect(() => {
    queueMicrotask(() => void refreshCommandCenter());
    const interval = setInterval(() => void refreshCommandCenter(), 15_000);
    return () => clearInterval(interval);
  }, [refreshCommandCenter]);

  const filteredUsers = useMemo(() => {
    const list = data?.users ?? [];
    const q = searchTerm.trim().toLowerCase();
    if (!q) return list;
    return list.filter((u) => {
      const name = (u.name ?? "").toLowerCase();
      const email = (u.email ?? "").toLowerCase();
      const phone = (u.phone ?? "").toLowerCase();
      return name.includes(q) || email.includes(q) || phone.includes(q);
    });
  }, [data?.users, searchTerm]);

  const runUserAction = useCallback(
    async (id: string, action: () => Promise<void>, okMsg: string) => {
      setActionErr(null);
      setActionMsg(null);
      setBusyId(id);
      try {
        await action();
        setActionMsg(okMsg);
        await refresh();
      } catch (e) {
        setActionErr(e instanceof Error ? e.message : "פעולה נכשלה");
      } finally {
        setBusyId(null);
      }
    },
    [refresh],
  );

  const toggleExempt = (u: AdminUser) =>
    runUserAction(
      u.id,
      () => patchUser(u.id, { manually_added: !u.paymentExempt }),
      u.paymentExempt ? "הוסר סטטוס פטור" : "הוגדר כחשבון פטור",
    );

  const changeRole = (u: AdminUser, role: "user" | "admin") =>
    runUserAction(u.id, () => patchUser(u.id, { role }), "התפקיד עודכן");

  const toggleActive = (u: AdminUser) =>
    runUserAction(
      u.id,
      () => patchUser(u.id, { is_active: !u.isActive }),
      u.isActive ? "החשבון הושעה" : "החשבון הופעל",
    );

  const removeUser = (u: AdminUser) => {
    if (!confirm(`למחוק את ${u.name || u.phone || u.email}?`)) return;
    void runUserAction(u.id, () => deleteUser(u.id), "המשתמש נמחק");
  };

  if (loading && !data) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-surface-canvas">
        <RefreshCw className="h-8 w-8 animate-spin text-veto-gold" aria-hidden />
      </div>
    );
  }

  return (
    <div className="p-4 sm:p-6 md:p-10" dir="rtl">
      <section
          className="mb-10 rounded-2xl border border-subtle bg-veto-ink p-6 text-primary shadow-xl md:p-8"
          dir="rtl"
          aria-label="חדר בקרה"
          data-surface="ink"
        >
          <header className="mb-8 flex flex-col gap-4 border-b border-subtle pb-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-2xl font-bold md:text-3xl">
                חדר בקרה <span className="text-veto-gold">VETO</span>
              </h2>
              <p className="mt-1 text-sm text-muted">מבט על בזמן אמת · רענון כל 15 שניות</p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <Button variant="secondary" size="sm" className="rounded-full" onClick={() => void refreshCommandCenter()}>
                רענון מיידי
              </Button>
              <div className="flex items-center gap-2 rounded-full border border-green-500/20 bg-green-500/10 px-4 py-2 text-sm text-green-400">
                <span className="relative flex h-2 w-2">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-green-500" />
                </span>
                מערכת מקוונת
              </div>
            </div>
          </header>

          {commandCenterLoading && !commandCenter ? (
            <div className="flex min-h-[120px] items-center justify-center text-veto-gold animate-pulse">
              טוען נתוני מערכת...
            </div>
          ) : (
            <>
              <div className="mb-10 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
                {(
                  [
                    {
                      title: "אירועים פעילים",
                      value: commandCenter?.stats.activeEventsCount ?? 0,
                      icon: AlertTriangle,
                      color: "text-red-400",
                    },
                    {
                      title: "אירועים היום",
                      value: commandCenter?.stats.dailyEventsCount ?? 0,
                      icon: Activity,
                      color: "text-blue-400",
                    },
                    {
                      title: "הכנסות היום",
                      value: `₪${commandCenter?.stats.dailyRevenue ?? 0}`,
                      icon: DollarSign,
                      color: "text-green-400",
                    },
                    {
                      title: "עורכי דין רשומים",
                      value: commandCenter?.stats.totalLawyers ?? 0,
                      icon: Users,
                      color: "text-veto-gold",
                      sub: `מקוונים: ${commandCenter?.stats.lawyersOnline ?? 0}`,
                    },
                  ] as const
                ).map((stat, idx) => (
                  <motion.div
                    key={stat.title}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: idx * 0.08 }}
                    className="rounded-2xl border border-subtle bg-[rgba(255,255,255,0.06)] p-6 backdrop-blur-md"
                  >
                    <div className="mb-4 flex items-start justify-between">
                      <h3 className="font-medium text-muted">{stat.title}</h3>
                      <stat.icon className={stat.color} size={24} aria-hidden />
                    </div>
                    <p className="text-4xl font-bold">{stat.value}</p>
                    {"sub" in stat && stat.sub ? (
                      <p className="mt-1 text-sm text-muted">{stat.sub}</p>
                    ) : null}
                  </motion.div>
                ))}
              </div>

              <h3 className="mb-4 flex items-center gap-2 text-xl font-bold">
                <Clock className="text-veto-gold" aria-hidden />
                אירועים חיים
              </h3>
              <div className="overflow-hidden rounded-2xl border border-subtle bg-[rgba(255,255,255,0.06)] backdrop-blur-md">
                <table className="w-full text-end text-sm">
                  <thead className="bg-[rgba(255,255,255,0.06)] text-muted">
                    <tr>
                      <th className="p-4 font-medium">מזהה אירוע</th>
                      <th className="p-4 font-medium">שפה</th>
                      <th className="p-4 font-medium">סטטוס</th>
                      <th className="p-4 font-medium">זמן יצירה</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/10">
                    {!commandCenter?.activeEvents?.length ? (
                      <tr>
                        <td colSpan={4} className="p-8 text-center text-muted">
                          אין אירועי חירום פעילים כרגע.
                        </td>
                      </tr>
                    ) : (
                      commandCenter.activeEvents.map((ev) => {
                        const id = String(ev._id);
                        const t = ev.createdAt ?? ev.triggered_at;
                        return (
                          <tr key={id} className="transition-colors hover:bg-[rgba(255,255,255,0.06)]">
                            <td className="p-4 font-mono text-xs text-gray-300">{id.slice(-6)}</td>
                            <td className="p-4">{langLabel(ev.language)}</td>
                            <td className="p-4">
                              <span className="rounded-full border border-veto-gold/30 bg-veto-gold/20 px-3 py-1 text-xs font-medium text-veto-gold">
                                {ev.status ?? "—"}
                              </span>
                            </td>
                            <td className="p-4 text-muted">
                              {t ? new Date(t).toLocaleTimeString("he-IL") : "—"}
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </section>

        <header className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="font-serif text-3xl font-bold text-primary">ניהול מערכת VETO</h1>
            <p className="text-sm text-muted">סטטוס שרתים ומנויים בזמן אמת</p>
          </div>
          <IconButton
            variant="secondary"
            size="md"
            className="rounded-full"
            onClick={() => void refresh()}
            label="רענון נתונים"
            icon={<RefreshCw className={`h-5 w-5 ${loading ? "animate-spin" : ""}`} aria-hidden />}
          />
        </header>

        <div className="mb-8 grid grid-cols-1 gap-4 text-center md:grid-cols-4">
          <div className="flex items-center justify-center gap-3 rounded-xl border border-green-500/30 bg-green-500/10 p-4 font-bold text-green-700 dark:text-green-300">
            <Activity size={20} aria-hidden /> שרת API: פועל
          </div>
          <div
            className={`flex items-center justify-center gap-3 rounded-xl border p-4 font-bold ${
              data?.health.database === "OK"
                ? "border-blue-500/30 bg-blue-500/10 text-blue-700 dark:text-blue-300"
                : "border-red-500/30 bg-red-500/10 text-red-700 dark:text-red-300"
            }`}
          >
            <Database size={20} aria-hidden /> מסד נתונים:{" "}
            {data?.health.database === "OK" ? "מחובר" : "בעיה"}
          </div>
          <div className="flex items-center justify-center gap-3 rounded-xl border border-orange-500/30 bg-orange-500/10 p-4 font-bold text-orange-700 dark:text-orange-300">
            <ShieldCheck size={20} aria-hidden /> אבטחת JWT: תקינה
          </div>
          <div className="flex items-center justify-center gap-3 rounded-xl border border-subtle bg-surface-raised-2 p-4 font-bold backdrop-blur-xl">
            סה&quot;כ משתמשים: {data?.stats.users ?? 0}
          </div>
        </div>

        <div className="mb-6 grid grid-cols-1 gap-3 text-sm text-muted md:grid-cols-3">
          <div className="rounded-lg border border-subtle bg-surface-raised-2 px-4 py-3 backdrop-blur-xl">
            <span className="font-bold text-primary">{data?.stats.lawyers ?? 0}</span> עורכי דין
          </div>
          <div className="rounded-lg border border-subtle bg-surface-raised-2 px-4 py-3 backdrop-blur-xl">
            <span className="font-bold text-primary">{data?.stats.sos ?? 0}</span> אירועי SOS ב־24 שעות
          </div>
          <div className="rounded-lg border border-subtle bg-surface-raised-2 px-4 py-3 backdrop-blur-xl">
            עודכן:{" "}
            {data?.health.timestamp ? new Date(data.health.timestamp).toLocaleString("he-IL") : "—"}
          </div>
        </div>

        {actionMsg && (
          <div role="status" className="mb-4 rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-900 dark:text-emerald-200">
            {actionMsg}
          </div>
        )}
        {actionErr && (
          <div role="alert" className="mb-4 rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-900 dark:text-red-200">
            {actionErr}
          </div>
        )}

        <section className="overflow-hidden rounded-2xl border border-subtle bg-surface-raised-2 backdrop-blur-xl">
          <div className="flex flex-col items-stretch justify-between gap-4 border-b border-subtle p-6 md:flex-row md:items-center">
            <h3 className="font-serif text-xl font-bold text-primary">ניהול מנויים ומשתמשים</h3>
            <div className="flex flex-1 items-center justify-end gap-3">
              <div className="relative w-full md:w-80">
                <Search className="pointer-events-none absolute end-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
                <input
                  type="search"
                  placeholder="חיפוש לפי שם, אימייל או טלפון..."
                  className="w-full rounded-lg border border-subtle bg-surface-overlay py-2 ps-4 pe-10 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  aria-label="חיפוש משתמש"
                />
              </div>
              <Button
                variant="primary"
                size="sm"
                onClick={() => setShowCreate((v) => !v)}
                iconStart={<Plus size={16} aria-hidden />}
              >
                הוספת משתמש
              </Button>
            </div>
          </div>

          {showCreate && (
            <CreateUserForm
              onClose={() => setShowCreate(false)}
              onCreated={async () => {
                setShowCreate(false);
                setActionMsg("המשתמש נוצר");
                await refresh();
              }}
              onError={(m) => setActionErr(m)}
            />
          )}

          <div className="overflow-x-auto">
            <table className="w-full text-end">
              <thead>
                <tr className="border-b border-subtle bg-surface-raised text-xs uppercase tracking-wider text-muted">
                  <th className="p-4 font-bold">שם / טלפון / אימייל</th>
                  <th className="p-4 text-center font-bold">תפקיד</th>
                  <th className="p-4 text-center font-bold">סטטוס</th>
                  <th className="p-4 text-center font-bold">פטור</th>
                  <th className="p-4 text-center font-bold">תוקף</th>
                  <th className="p-4 text-center font-bold">פעולות</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-subtle">
                {filteredUsers.map((user) => {
                  const expiry = user.subscriptionExpiry
                    ? new Date(user.subscriptionExpiry).toLocaleDateString("he-IL")
                    : "—";
                  const isBusy = busyId === user.id;
                  return (
                    <tr key={user.id} className="transition hover:bg-surface-overlay">
                      <td className="p-4">
                        <div className="font-bold text-primary">{user.name || "—"}</div>
                        <div className="text-xs text-muted">
                          {user.phone || user.email || "—"}
                        </div>
                      </td>
                      <td className="p-4 text-center">
                        <select
                          disabled={isBusy}
                          value={user.role.toLowerCase()}
                          onChange={(e) =>
                            void changeRole(
                              user,
                              e.target.value as "user" | "admin",
                            )
                          }
                          aria-label={`תפקיד עבור ${user.name || user.phone || user.email || "משתמש"}`}
                          className="rounded-lg border border-subtle bg-surface-overlay px-2 py-1 text-xs text-primary"
                        >
                          <option value="user">אזרח</option>
                          <option value="admin">מנהל</option>
                        </select>
                      </td>
                      <td className="p-4 text-center text-xs">
                        <Button
                          variant="ghost"
                          size="sm"
                          className={
                            user.isActive
                              ? "bg-emerald-500/15 text-emerald-300 hover:bg-emerald-500/25"
                              : "bg-amber-500/15 text-amber-300 hover:bg-amber-500/25"
                          }
                          disabled={isBusy}
                          onClick={() => void toggleActive(user)}
                        >
                          {user.isActive ? "פעיל" : "מושעה"}
                        </Button>
                      </td>
                      <td className="p-4 text-center">
                        <label className="inline-flex cursor-pointer items-center gap-2 text-xs text-secondary">
                          <input
                            type="checkbox"
                            disabled={isBusy}
                            checked={user.paymentExempt}
                            onChange={() => void toggleExempt(user)}
                            className="h-4 w-4 cursor-pointer accent-veto-gold"
                          />
                          פטור
                        </label>
                      </td>
                      <td className="p-4 text-center text-xs text-muted">{expiry}</td>
                      <td className="p-4 text-center">
                        <div className="inline-flex items-center gap-2">
                          <Link
                            href={`/admin/users/${user.id}`}
                            className="text-xs font-bold text-veto-gold hover:underline"
                          >
                            ערוך
                          </Link>
                          <IconButton
                            variant="ghost"
                            size="sm"
                            className="text-red-400 hover:bg-red-500/10"
                            disabled={isBusy}
                            onClick={() => removeUser(user)}
                            label="מחק משתמש"
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
          {filteredUsers.length === 0 && (
            <p className="p-8 text-center text-muted">
              {searchTerm.trim() ? "לא נמצאו תוצאות לחיפוש." : "אין משתמשים להצגה."}
            </p>
          )}
        </section>
    </div>
  );
}

function CreateUserForm({
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
  const [role, setRole] = useState<"user" | "admin">("user");
  const [exempt, setExempt] = useState(true);
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await createUser({
        full_name: name.trim(),
        phone: phone.trim(),
        email: email.trim() || undefined,
        role,
        manually_added: exempt,
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
      className="grid grid-cols-1 gap-3 border-b border-subtle bg-surface-raised/50 p-6 md:grid-cols-5"
    >
      <input
        required
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="שם מלא"
        className="rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
      />
      <input
        required
        value={phone}
        onChange={(e) => setPhone(e.target.value)}
        placeholder="טלפון (+972...)"
        className="rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
      />
      <input
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="אימייל (אופציונלי)"
        type="email"
        className="rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
      />
      <select
        value={role}
        onChange={(e) => setRole(e.target.value as typeof role)}
        aria-label="תפקיד המשתמש החדש"
        className="rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
      >
        <option value="user">אזרח</option>
        <option value="admin">מנהל</option>
      </select>
      <div className="flex items-center justify-between gap-2">
        <label className="inline-flex cursor-pointer items-center gap-2 text-xs text-secondary">
          <input
            type="checkbox"
            checked={exempt}
            onChange={(e) => setExempt(e.target.checked)}
            className="h-4 w-4 cursor-pointer accent-veto-gold"
          />
          פטור מתשלום
        </label>
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" onClick={onClose}>
            ביטול
          </Button>
          <Button variant="primary" size="sm" type="submit" disabled={busy} loading={busy}>
            {busy ? "יוצר…" : "צור"}
          </Button>
        </div>
      </div>
    </form>
  );
}
