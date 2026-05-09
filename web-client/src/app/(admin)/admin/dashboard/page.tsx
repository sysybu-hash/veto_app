"use client";

import {
  Activity,
  Database,
  FileText,
  LayoutDashboard,
  RefreshCw,
  Search,
  Settings,
  ShieldCheck,
} from "lucide-react";
import Link from "next/link";
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { Role } from "@prisma/client";

type DashboardPayload = {
  stats: { users: number; lawyers: number; sos: number };
  users: Array<{
    id: string;
    externalId: string;
    email: string;
    name: string;
    role: Role;
    createdAt: string;
    isPro: boolean;
  }>;
  health: { database: string; api: string; timestamp: string };
};

async function fetchDashboardPayload(): Promise<DashboardPayload | null> {
  const res = await fetch("/api/admin/dashboard", {
    credentials: "include",
    cache: "no-store",
  });
  if (!res.ok) return null;
  return (await res.json()) as DashboardPayload;
}

export default function VetoMasterDashboard() {
  const [data, setData] = useState<DashboardPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const payload = await fetchDashboardPayload();
        if (cancelled) return;
        setData(payload);
      } catch (err) {
        console.error(err);
        if (!cancelled) setData(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const refreshData = useCallback(async () => {
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

  const filteredUsers = useMemo(() => {
    const list = data?.users ?? [];
    const q = searchTerm.trim().toLowerCase();
    if (!q) return list;
    return list.filter((u) => {
      const name = (u.name ?? "").toLowerCase();
      const email = (u.email ?? "").toLowerCase();
      return name.includes(q) || email.includes(q);
    });
  }, [data?.users, searchTerm]);

  if (loading && !data) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-950">
        <RefreshCw className="h-8 w-8 animate-spin text-[#C5A059]" aria-hidden />
      </div>
    );
  }

  return (
    <div
      className="flex min-h-screen flex-col md:flex-row"
      dir="rtl"
    >
      <aside className="flex w-full flex-col gap-8 border-l border-white/10 bg-slate-950/70 backdrop-blur-xl p-6 print:hidden md:w-64">
        <div className="font-serif text-2xl font-bold tracking-tight text-slate-100">
          VETO Admin
        </div>
        <nav className="flex flex-col gap-2">
          <MenuLink
            href="/admin/dashboard"
            icon={<LayoutDashboard size={18} aria-hidden />}
            label="מרכז שליטה"
            active
          />
          <MenuLink
            href="/admin/vault"
            icon={<Database size={18} aria-hidden />}
            label="ניהול כספת"
          />
          <MenuLink
            href="/vault/generator"
            icon={<FileText size={18} aria-hidden />}
            label="מחולל מסמכים AI"
          />
          <MenuLink
            href="/admin/settings"
            icon={<Settings size={18} aria-hidden />}
            label="הגדרות מערכת"
          />
        </nav>
      </aside>

      <main className="flex-1 overflow-y-auto p-6 md:p-10">
        <header className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="font-serif text-3xl font-bold text-slate-100">
              ניהול מערכת VETO
            </h1>
            <p className="text-sm text-slate-500">
              סטטוס שרתים ומנויים בזמן אמת
            </p>
          </div>
          <button
            type="button"
            onClick={() => void refreshData()}
            className="rounded-full border border-white/10 bg-white/[0.04] p-2 text-slate-200 transition hover:bg-white/[0.08]"
            aria-label="רענון נתונים"
          >
            <RefreshCw
              className={`h-5 w-5 ${loading ? "animate-spin" : ""}`}
              aria-hidden
            />
          </button>
        </header>

        <div className="mb-8 grid grid-cols-1 gap-4 text-center md:grid-cols-4">
          <div className="flex items-center justify-center gap-3 rounded-xl border border-green-500/30 bg-green-500/10 p-4 font-bold text-green-300">
            <Activity size={20} aria-hidden /> שרת API: פועל
          </div>
          <div
            className={`flex items-center justify-center gap-3 rounded-xl border p-4 font-bold ${
              data?.health.database === "OK"
                ? "border-blue-500/30 bg-blue-500/10 text-blue-300"
                : "border-red-500/30 bg-red-500/10 text-red-300"
            }`}
          >
            <Database size={20} aria-hidden /> מסד נתונים:{" "}
            {data?.health.database === "OK" ? "מחובר" : "בעיה"}
          </div>
          <div className="flex items-center justify-center gap-3 rounded-xl border border-orange-500/30 bg-orange-500/10 p-4 font-bold text-orange-300">
            <ShieldCheck size={20} aria-hidden /> אבטחת JWT: תקינה
          </div>
          <div className="flex items-center justify-center gap-3 rounded-xl border border-white/10 bg-white/[0.04] p-4 font-bold backdrop-blur-xl">
            סה&quot;כ משתמשים: {data?.stats.users ?? 0}
          </div>
        </div>

        <div className="mb-6 grid grid-cols-1 gap-3 text-sm text-slate-400 md:grid-cols-3">
          <div className="rounded-lg border border-white/10 bg-white/[0.04] px-4 py-3 backdrop-blur-xl">
            <span className="font-bold text-slate-100">
              {data?.stats.lawyers ?? 0}
            </span>{" "}
            עורכי דין (Prisma)
          </div>
          <div className="rounded-lg border border-white/10 bg-white/[0.04] px-4 py-3 backdrop-blur-xl">
            <span className="font-bold text-slate-100">
              {data?.stats.sos ?? 0}
            </span>{" "}
            אירועי SOS ב־24 שעות
          </div>
          <div className="rounded-lg border border-white/10 bg-white/[0.04] px-4 py-3 backdrop-blur-xl">
            עודכן:{" "}
            {data?.health.timestamp
              ? new Date(data.health.timestamp).toLocaleString("he-IL")
              : "—"}
          </div>
        </div>

        <section className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.04] backdrop-blur-xl">
          <div className="flex flex-col items-center justify-between gap-4 border-b border-white/10 p-6 md:flex-row">
            <h3 className="font-serif text-xl font-bold text-slate-100">
              ניהול מנויים ומשתמשים
            </h3>
            <div className="relative w-full md:w-80">
              <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                type="search"
                placeholder="חיפוש משתמש..."
                className="w-full rounded-lg border border-white/10 bg-slate-950 py-2 pl-4 pr-10 text-sm outline-none focus:ring-2 focus:ring-[#C5A059]"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                aria-label="חיפוש משתמש"
              />
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-right">
              <thead>
                <tr className="border-b border-white/10 bg-slate-950 text-xs uppercase tracking-wider text-slate-500">
                  <th className="p-4 font-bold">שם ואימייל</th>
                  <th className="p-4 text-center font-bold">תפקיד</th>
                  <th className="p-4 text-center font-bold">סטטוס</th>
                  <th className="p-4 text-center font-bold">תאריך הרשמה</th>
                  <th className="p-4 text-left font-bold">פעולות</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="transition hover:bg-white/[0.04]">
                    <td className="p-4">
                      <div className="font-bold text-slate-100">
                        {user.name || "—"}
                      </div>
                      <div className="text-xs text-slate-500">{user.email}</div>
                    </td>
                    <td className="p-4 text-center">
                      <RoleBadge role={user.role} />
                    </td>
                    <td className="p-4 text-center text-sm">
                      <span
                        className={
                          user.isPro
                            ? "font-bold text-green-600"
                            : "text-slate-400"
                        }
                      >
                        {user.isPro ? "PRO" : "FREE"}
                      </span>
                    </td>
                    <td className="p-4 text-center text-sm text-slate-500">
                      {new Date(user.createdAt).toLocaleDateString("he-IL")}
                    </td>
                    <td className="p-4 text-left">
                      <Link
                        href={`/admin/users/${user.id}`}
                        className="text-sm font-bold text-[#C5A059] hover:underline"
                      >
                        ערוך
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {filteredUsers.length === 0 && (
            <p className="p-8 text-center text-slate-500">
              {searchTerm.trim()
                ? "לא נמצאו תוצאות לחיפוש."
                : "אין משתמשים להצגה."}
            </p>
          )}
        </section>
      </main>
    </div>
  );
}

function RoleBadge({ role }: { role: Role }) {
  if (role === "LAWYER") {
    return (
      <span className="rounded bg-purple-100 px-2 py-1 text-[10px] font-bold text-purple-700">
        עו&quot;ד
      </span>
    );
  }
  if (role === "ADMIN") {
    return (
      <span className="rounded bg-amber-500/15 px-2 py-1 text-[10px] font-bold text-amber-200">
        מנהל
      </span>
    );
  }
  return (
    <span className="rounded bg-blue-500/15 px-2 py-1 text-[10px] font-bold text-blue-300">
      אזרח
    </span>
  );
}

function MenuLink({
  href,
  icon,
  label,
  active = false,
}: {
  href: string;
  icon: ReactNode;
  label: string;
  active?: boolean;
}) {
  return (
    <Link
      href={href}
      className={`flex items-center gap-3 rounded-lg p-3 text-sm font-medium transition ${
        active
          ? "bg-[#C5A059]/10 text-[#C5A059]"
          : "text-slate-400 hover:bg-white/[0.04]"
      }`}
    >
      {icon}
      {label}
    </Link>
  );
}
