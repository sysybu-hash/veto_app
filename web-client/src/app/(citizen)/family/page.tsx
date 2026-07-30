"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { authFetch, apiUrl } from "@/api/apiClient";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { citizenBottomSafe } from "@/lib/vetoGlass";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";

type FamilyState = {
  isOwner: boolean;
  owner: { id: string; name: string; phone: string; expiry: string | null } | null;
  members: Array<{ id: string; name: string; phone: string }>;
  seats: number;
};

async function fetchFamily(): Promise<FamilyState | null> {
  const r = await authFetch(apiUrl("/api/users/family"), { method: "GET" });
  if (!r.ok) return null;
  return (await r.json()) as FamilyState;
}

export default function FamilyPage() {
  const router = useRouter();
  const [state, setState] = useState<FamilyState | null>(null);
  const [phone, setPhone] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const r = await fetchFamily();
      setState(r);
    } catch {
      setState(null);
    }
  }, []);

  useEffect(() => {
    if (!getJwt()) {
      router.replace("/login");
      return;
    }
    queueMicrotask(() => void refresh());
  }, [refresh, router]);

  const invite = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      const r = await authFetch(apiUrl("/api/users/family/invite"), {
        method: "POST",
        body: JSON.stringify({ phone: phone.trim() }),
      });
      if (!r.ok) {
        const j = (await r.json().catch(() => ({}))) as { error?: string };
        throw new Error(j.error || "ההוספה נכשלה");
      }
      setPhone("");
      setNotice("חבר המשפחה הוסף למנוי.");
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "ההוספה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const remove = async (id: string) => {
    if (!confirm("להסיר את החבר מהמנוי המשפחתי?")) return;
    try {
      const r = await authFetch(
        apiUrl(`/api/users/family/${encodeURIComponent(id)}`),
        { method: "DELETE" },
      );
      if (!r.ok) {
        const j = (await r.json().catch(() => ({}))) as { error?: string };
        throw new Error(j.error || "ההסרה נכשלה");
      }
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "ההסרה נכשלה");
    }
  };

  return (
    <div
      dir="rtl"
      className={`mx-auto flex w-full max-w-2xl flex-col gap-6 px-4 py-8 ${citizenBottomSafe}`}
    >
      <header className="text-end">
        <h1 className="font-frank text-2xl font-bold text-primary">מנוי משפחתי</h1>
        <p className="mt-1 text-sm text-muted">
          הוספת בני משפחה למנוי הקיים שלך (עד {state?.seats ?? 4} משתמשים).
        </p>
      </header>

      {!state && (
        <div className="rounded-2xl border border-subtle bg-white/[0.04] p-6 text-sm text-secondary">
          טוען נתונים…
        </div>
      )}

      {state && !state.owner && (
        <div className="rounded-2xl border border-amber-500/30 bg-amber-500/10 p-6 text-sm text-amber-200">
          אינך חלק ממנוי משפחתי. לרכישה עברו לעמוד{" "}
          <Link href="/plans" className="font-bold underline">
            המנויים
          </Link>
          .
        </div>
      )}

      {state?.owner && (
        <section className="rounded-2xl border border-veto-gold/35 bg-veto-gold/10 p-5 text-end">
          <p className="text-sm font-bold text-primary">
            בעל המנוי: {state.owner.name || state.owner.phone}
          </p>
          {state.owner.expiry && (
            <p className="mt-1 text-xs text-muted">
              תוקף עד {new Date(state.owner.expiry).toLocaleDateString("he-IL")}
            </p>
          )}
          <p className="mt-2 text-xs text-secondary">
            {state.isOwner ? "אתה בעל המנוי." : "אתה חבר במנוי."}
          </p>
        </section>
      )}

      {error && (
        <div role="alert" className="rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-200">
          {error}
        </div>
      )}
      {notice && (
        <div role="status" className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
          {notice}
        </div>
      )}

      {state?.isOwner && (
        <form
          onSubmit={(e) => void invite(e)}
          className="rounded-2xl border border-subtle bg-white/[0.03] p-5"
        >
          <label className="block text-sm font-medium text-primary">הוספת חבר משפחה</label>
          <p className="mt-1 text-xs text-muted">
            יש להזין מספר טלפון של משתמש שכבר נרשם במערכת (פורמט +972…).
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <input
              required
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+972…"
              className="min-w-0 flex-1 rounded-lg border border-subtle bg-surface-overlay px-3 py-2 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
            />
            <Button variant="primary" type="submit" disabled={busy} loading={busy}>
              {busy ? "מוסיף…" : "הוספה"}
            </Button>
          </div>
        </form>
      )}

      {state?.owner && state.members.length > 0 && (
        <section>
          <h2 className="mb-2 text-sm font-bold text-primary">חברי המשפחה ({state.members.length}/{state.seats - 1})</h2>
          <ul className="space-y-2">
            {state.members.map((m) => (
              <li
                key={m.id}
                className="flex items-center justify-between rounded-xl border border-subtle bg-white/[0.03] px-4 py-3 text-sm"
              >
                <div>
                  <p className="font-bold text-primary">{m.name || "—"}</p>
                  <p className="text-xs text-muted">{m.phone}</p>
                </div>
                {state.isOwner && (
                  <Button variant="secondary" size="sm" onClick={() => void remove(m.id)}>
                    הסרה
                  </Button>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}

      <CitizenBottomNav active="hub" />
    </div>
  );
}
