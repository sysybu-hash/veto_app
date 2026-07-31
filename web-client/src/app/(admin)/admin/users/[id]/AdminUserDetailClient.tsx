"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";

type AdminUser = {
  id: string;
  email: string;
  phone: string;
  name: string;
  role: string;
  createdAt: string;
  isPro: boolean;
  paymentExempt: boolean;
  isActive: boolean;
  isVerified: boolean;
  subscriptionExpiry: string | null;
  status: string;
};

type AuditLogEntry = {
  _id: string;
  action: string;
  createdAt: string;
  admin_role?: string;
  metadata?: { fields?: string[] } | null;
};

function authHeaders(): Record<string, string> {
  const t = getJwt();
  return t ? { Authorization: `Bearer ${t}` } : {};
}

async function fetchUser(id: string): Promise<AdminUser | null> {
  const res = await fetch("/api/admin/dashboard", {
    credentials: "include",
    cache: "no-store",
    headers: authHeaders(),
  });
  if (!res.ok) return null;
  const body = (await res.json()) as { users?: AdminUser[] };
  return body.users?.find((u) => u.id === id) ?? null;
}

async function fetchAuditLogs(id: string): Promise<AuditLogEntry[]> {
  const res = await fetch(
    `/api/admin/audit-logs?targetType=user&targetId=${encodeURIComponent(id)}&limit=20`,
    { credentials: "include", cache: "no-store", headers: authHeaders() },
  );
  if (!res.ok) return [];
  const body = (await res.json()) as { logs?: AuditLogEntry[] };
  return body.logs ?? [];
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

const ACTION_LABELS: Record<string, string> = {
  "user.create": "נוצר",
  "user.update": "עודכן",
  "user.delete": "נמחק",
};

function formatAction(entry: AuditLogEntry): string {
  const base = ACTION_LABELS[entry.action] ?? entry.action;
  const fields = entry.metadata?.fields;
  if (fields?.length) return `${base} (${fields.join(", ")})`;
  return base;
}

export function AdminUserDetailClient({ id }: { id: string }) {
  const router = useRouter();
  const [user, setUser] = useState<AdminUser | null>(null);
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [extendDays, setExtendDays] = useState("30");

  const load = useCallback(async () => {
    setLoading(true);
    const [u, l] = await Promise.all([fetchUser(id), fetchAuditLogs(id)]);
    if (!u) {
      setNotFound(true);
    } else {
      setUser(u);
      setNotFound(false);
    }
    setLogs(l);
    setLoading(false);
  }, [id]);

  useEffect(() => {
    queueMicrotask(() => {
      void load();
    });
  }, [load]);

  const runAction = async (action: () => Promise<void>, okMsg: string) => {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      await action();
      setMessage(okMsg);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "הפעולה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface-canvas p-4 sm:p-8" dir="rtl">
        <p className="text-muted">טוען…</p>
      </div>
    );
  }

  if (notFound || !user) {
    return (
      <div className="min-h-screen bg-surface-canvas p-4 sm:p-8" dir="rtl">
        <div className="mx-auto max-w-lg rounded-2xl border border-subtle bg-[rgba(255,255,255,0.04)] p-8 backdrop-blur-xl">
          <h1 className="font-serif text-2xl font-bold text-primary">משתמש לא נמצא</h1>
          <p className="mt-2 text-sm text-muted">
            ייתכן שהמשתמש נמחק, או שהמזהה שגוי.
          </p>
          <Link href="/admin/dashboard" className="mt-6 inline-block text-sm font-bold text-veto-gold hover:underline">
            חזרה למרכז שליטה
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface-canvas p-4 sm:p-8" dir="rtl">
      <div className="mx-auto max-w-2xl space-y-4">
        <Link href="/admin/dashboard" className="inline-block text-sm font-bold text-veto-gold hover:underline">
          ← חזרה למרכז שליטה
        </Link>

        <div className="rounded-2xl border border-subtle bg-[rgba(255,255,255,0.04)] p-6 backdrop-blur-xl">
          <h1 className="font-serif text-2xl font-bold text-primary">{user.name || "—"}</h1>
          <p className="mt-1 text-sm text-muted">{user.phone || user.email || "—"}</p>

          {message && (
            <p role="status" className="mt-3 rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-200">
              {message}
            </p>
          )}
          {error && (
            <p role="alert" className="mt-3 rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
              {error}
            </p>
          )}

          <dl className="mt-5 grid grid-cols-2 gap-4 text-sm">
            <div>
              <dt className="text-xs font-bold text-muted">תפקיד</dt>
              <dd className="mt-1 text-primary">{user.role === "ADMIN" ? "מנהל" : "אזרח"}</dd>
            </div>
            <div>
              <dt className="text-xs font-bold text-muted">סטטוס</dt>
              <dd className="mt-1 text-primary">{user.isActive ? "פעיל" : "מושעה"}</dd>
            </div>
            <div>
              <dt className="text-xs font-bold text-muted">מנוי</dt>
              <dd className="mt-1 text-primary">
                {user.paymentExempt ? "פטור מתשלום" : user.isPro ? "מנוי פעיל" : "ללא מנוי"}
              </dd>
            </div>
            <div>
              <dt className="text-xs font-bold text-muted">תוקף מנוי</dt>
              <dd className="mt-1 text-primary">
                {user.subscriptionExpiry
                  ? new Date(user.subscriptionExpiry).toLocaleDateString("he-IL")
                  : "—"}
              </dd>
            </div>
            <div>
              <dt className="text-xs font-bold text-muted">נרשם בתאריך</dt>
              <dd className="mt-1 text-primary">
                {new Date(user.createdAt).toLocaleDateString("he-IL")}
              </dd>
            </div>
            <div>
              <dt className="text-xs font-bold text-muted">אימות טלפון</dt>
              <dd className="mt-1 text-primary">{user.isVerified ? "מאומת" : "לא מאומת"}</dd>
            </div>
          </dl>

          <div className="mt-6 flex flex-wrap gap-2 border-t border-subtle pt-5">
            <Button
              variant="secondary"
              size="sm"
              disabled={busy}
              onClick={() =>
                runAction(
                  () => patchUser(user.id, { role: user.role === "ADMIN" ? "user" : "admin" }),
                  "התפקיד עודכן",
                )
              }
            >
              {user.role === "ADMIN" ? "הפוך לאזרח" : "הפוך למנהל"}
            </Button>
            <Button
              variant="secondary"
              size="sm"
              disabled={busy}
              onClick={() =>
                runAction(
                  () => patchUser(user.id, { is_active: !user.isActive }),
                  user.isActive ? "החשבון הושעה" : "החשבון הופעל",
                )
              }
            >
              {user.isActive ? "השעיית חשבון" : "הפעלת חשבון"}
            </Button>
            <Button
              variant="secondary"
              size="sm"
              disabled={busy}
              onClick={() =>
                runAction(
                  () => patchUser(user.id, { manually_added: !user.paymentExempt }),
                  user.paymentExempt ? "הוסר סטטוס פטור" : "הוגדר כחשבון פטור",
                )
              }
            >
              {user.paymentExempt ? "הסרת פטור תשלום" : "הגדרת פטור תשלום"}
            </Button>
            <Button
              variant="danger"
              size="sm"
              disabled={busy}
              onClick={() => {
                if (!confirm(`למחוק את ${user.name || user.phone}?`)) return;
                void (async () => {
                  setBusy(true);
                  setError(null);
                  try {
                    await deleteUser(user.id);
                    router.replace("/admin/dashboard");
                  } catch (e) {
                    setError(e instanceof Error ? e.message : "המחיקה נכשלה");
                    setBusy(false);
                  }
                })();
              }}
            >
              מחיקת משתמש
            </Button>
          </div>

          <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-subtle pt-4">
            <label htmlFor="extend-days" className="text-xs font-bold text-secondary">
              הארכת מנוי (ימים)
            </label>
            <input
              id="extend-days"
              type="number"
              min={1}
              value={extendDays}
              onChange={(e) => setExtendDays(e.target.value)}
              className="w-20 rounded-lg border border-subtle bg-surface-overlay px-2 py-1.5 text-sm text-primary"
            />
            <Button
              variant="primary"
              size="sm"
              disabled={busy || !Number(extendDays)}
              onClick={() =>
                runAction(
                  () => patchUser(user.id, { extendDays: Number(extendDays) }),
                  "המנוי הוארך",
                )
              }
            >
              הארכה
            </Button>
          </div>
        </div>

        <div className="rounded-2xl border border-subtle bg-[rgba(255,255,255,0.04)] p-6 backdrop-blur-xl">
          <h2 className="font-serif text-lg font-bold text-primary">פעולות אחרונות</h2>
          {logs.length === 0 ? (
            <p className="mt-3 text-sm text-muted">אין פעולות מתועדות עבור משתמש זה.</p>
          ) : (
            <ul className="mt-3 space-y-2">
              {logs.map((entry) => (
                <li
                  key={entry._id}
                  className="flex items-center justify-between gap-3 rounded-lg border border-subtle bg-white/[0.03] px-3 py-2 text-xs"
                >
                  <span className="text-primary">{formatAction(entry)}</span>
                  <span className="text-muted">
                    {new Date(entry.createdAt).toLocaleString("he-IL")}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
