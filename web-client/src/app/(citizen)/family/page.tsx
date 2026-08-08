"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Clock, Trash2, UserPlus, Users } from "lucide-react";
import { authFetch, apiUrl } from "@/api/apiClient";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { citizenBottomSafe } from "@/lib/vetoGlass";
import { getJwt } from "@/lib/authToken";
import { Button } from "@/components/ui/primitives/Button";

type Member = { id: string; name: string; phone: string };
type Invite = { id: string; phone: string; expiresAt: string; smsSent: boolean };

type FamilyState = {
  isOwner: boolean;
  owner: { id: string; name: string; phone: string; expiry: string | null } | null;
  members: Member[];
  invites: Invite[];
  seats: number;
  seatsUsed: number;
  seatsFree: number;
};

async function fetchFamily(): Promise<FamilyState | null> {
  const r = await authFetch(apiUrl("/api/users/family"), { method: "GET" });
  if (!r.ok) return null;
  return (await r.json()) as FamilyState;
}

function fmtDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return new Intl.DateTimeFormat("he-IL", { dateStyle: "short" }).format(new Date(iso));
  } catch {
    return iso;
  }
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
      setState(await fetchFamily());
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

  /** Shared handler so every action reports the same way. */
  const run = async (
    fn: () => Promise<Response>,
    onOk: (body: Record<string, unknown>) => string,
  ) => {
    setBusy(true);
    setError(null);
    setNotice(null);
    try {
      const r = await fn();
      const body = (await r.json().catch(() => ({}))) as Record<string, unknown>;
      if (!r.ok) throw new Error((body.error as string) || `הפעולה נכשלה (${r.status})`);
      setNotice(onOk(body));
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "הפעולה נכשלה");
    } finally {
      setBusy(false);
    }
  };

  const add = (e: React.FormEvent) => {
    e.preventDefault();
    const value = phone.trim();
    if (!value) return;
    void run(
      () =>
        authFetch(apiUrl("/api/users/family/invite"), {
          method: "POST",
          body: JSON.stringify({ phone: value }),
        }),
      (body) => {
        setPhone("");
        const notified = body.notified as { sms?: boolean } | undefined;
        if (body.kind === "linked") {
          return notified?.sms
            ? "צורף למנוי, ונשלחה לו הודעה."
            : "צורף למנוי. לא הצלחנו לשלוח הודעה — כדאי לעדכן אותו.";
        }
        return notified?.sms
          ? "המספר עדיין לא רשום — נשלחה הזמנה, והצירוף יקרה אוטומטית עם ההרשמה."
          : "המספר עדיין לא רשום — המקום שמור. לא הצלחנו לשלוח הודעה, כדאי לעדכן אותו.";
      },
    );
  };

  const removeMember = (m: Member) => {
    if (
      !window.confirm(
        `להסיר את ${m.name || m.phone} מהמנוי?\nהגישה שלו לשירות תיפסק מיד, והוא יקבל על כך הודעה.`,
      )
    ) {
      return;
    }
    void run(
      () => authFetch(apiUrl(`/api/users/family/${m.id}`), { method: "DELETE" }),
      () => "החבר הוסר מהמנוי.",
    );
  };

  const cancelInvite = (inv: Invite) => {
    if (!window.confirm(`לבטל את ההזמנה ל-${inv.phone}? המקום יתפנה.`)) return;
    void run(
      () => authFetch(apiUrl(`/api/users/family/invite/${inv.id}`), { method: "DELETE" }),
      () => "ההזמנה בוטלה והמקום התפנה.",
    );
  };

  const isOwner = state?.isOwner ?? false;
  const full = (state?.seatsFree ?? 0) <= 0;

  return (
    <>
      <div className={`mx-auto w-full max-w-2xl px-4 py-8 ${citizenBottomSafe}`}>
        <h1 className="font-frank text-2xl font-bold text-primary">מנוי משפחתי</h1>
        <p className="mt-2 text-sm text-muted">
          עד {state?.seats ?? 4} אנשים, כולל בעל המנוי. לכל אחד חשבון נפרד — הכספת,
          השיחות והמסמכים של כל אחד נשארים פרטיים.
        </p>

        {error ? (
          <p
            role="alert"
            className="mt-4 rounded-2xl border border-danger-border bg-danger-soft px-4 py-3 text-sm font-semibold text-danger-on-soft"
          >
            {error}
          </p>
        ) : null}
        {notice ? (
          <p
            role="status"
            className="mt-4 rounded-2xl border border-success-border bg-success-soft px-4 py-3 text-sm font-semibold text-success-on-soft"
          >
            {notice}
          </p>
        ) : null}

        {!state?.owner ? (
          <section className="mt-6 rounded-2xl border border-subtle bg-surface-raised/80 p-5">
            <p className="text-sm text-secondary">
              אין לך מנוי משפחתי פעיל.
            </p>
            <Link href="/plans" className="mt-3 inline-block">
              <Button type="button">למסלולים</Button>
            </Link>
          </section>
        ) : (
          <>
            <section className="mt-6 rounded-2xl border border-subtle bg-surface-raised/80 p-5">
              <h2 className="flex items-center gap-2 text-sm font-black text-primary">
                <Users className="h-4 w-4" aria-hidden />
                {state.seatsUsed} מתוך {state.seats} מקומות בשימוש
              </h2>
              <p className="mt-1 text-xs text-muted">
                בעל המנוי: {state.owner.name || state.owner.phone}
                {state.owner.expiry ? ` · בתוקף עד ${fmtDate(state.owner.expiry)}` : ""}
              </p>
              {!isOwner ? (
                <p className="mt-3 text-xs text-muted">
                  רק בעל המנוי יכול להוסיף או להסיר משתמשים.
                </p>
              ) : null}
            </section>

            {isOwner ? (
              <section className="mt-4 rounded-2xl border border-subtle bg-surface-raised/80 p-5">
                <h2 className="flex items-center gap-2 text-sm font-black text-primary">
                  <UserPlus className="h-4 w-4" aria-hidden />
                  הוספת אדם למנוי
                </h2>
                <p className="mt-1 text-xs text-muted">
                  הזינו מספר טלפון. אם הוא כבר רשום — יצורף מיד. אם לא — נשמור לו
                  מקום ונשלח הזמנה, והצירוף יקרה מעצמו כשיירשם.
                </p>
                <form onSubmit={add} className="mt-3 flex flex-col gap-2 sm:flex-row">
                  <label className="sr-only" htmlFor="family-phone">
                    מספר טלפון להוספה
                  </label>
                  <input
                    id="family-phone"
                    type="tel"
                    inputMode="tel"
                    dir="ltr"
                    placeholder="050-123-4567"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    disabled={busy || full}
                    className="min-h-[44px] flex-1 rounded-xl border border-subtle bg-surface-raised-2 px-3 text-sm text-primary"
                  />
                  <Button type="submit" disabled={busy || full || !phone.trim()}>
                    הוספה
                  </Button>
                </form>
                {full ? (
                  <p className="mt-2 text-xs font-bold text-warning-on-soft">
                    כל המקומות תפוסים. בטלו הזמנה ממתינה או הסירו משתמש כדי לפנות מקום.
                  </p>
                ) : null}
              </section>
            ) : null}

            {state.members.length > 0 ? (
              <section className="mt-4 rounded-2xl border border-subtle bg-surface-raised/80 p-5">
                <h2 className="text-sm font-black text-primary">
                  משתמשים במנוי ({state.members.length})
                </h2>
                <ul className="mt-3 space-y-2">
                  {state.members.map((m) => (
                    <li
                      key={m.id}
                      className="flex items-center justify-between gap-3 rounded-xl border border-subtle bg-surface-raised-2 px-3 py-2"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-bold text-primary">
                          {m.name || "—"}
                        </p>
                        <p dir="ltr" className="text-xs text-muted">
                          {m.phone}
                        </p>
                      </div>
                      {isOwner ? (
                        <Button
                          variant="secondary"
                          size="sm"
                          disabled={busy}
                          onClick={() => removeMember(m)}
                        >
                          <Trash2 className="h-4 w-4" aria-hidden />
                          הסרה
                        </Button>
                      ) : null}
                    </li>
                  ))}
                </ul>
              </section>
            ) : null}

            {isOwner && state.invites.length > 0 ? (
              <section className="mt-4 rounded-2xl border border-warning-border bg-warning-soft p-5">
                <h2 className="flex items-center gap-2 text-sm font-black text-warning-on-soft">
                  <Clock className="h-4 w-4" aria-hidden />
                  ממתינים להרשמה ({state.invites.length})
                </h2>
                <p className="mt-1 text-xs text-warning-on-soft">
                  המקום שמור להם. ברגע שיירשמו עם המספר הזה הם יצורפו אוטומטית.
                </p>
                <ul className="mt-3 space-y-2">
                  {state.invites.map((inv) => (
                    <li
                      key={inv.id}
                      className="flex items-center justify-between gap-3 rounded-xl bg-surface-raised-2 px-3 py-2"
                    >
                      <div className="min-w-0">
                        <p dir="ltr" className="text-sm font-bold text-primary">
                          {inv.phone}
                        </p>
                        <p className="text-xs text-muted">
                          {inv.smsSent ? "הזמנה נשלחה" : "ההזמנה לא נשלחה — עדכנו אותו"}
                          {" · בתוקף עד "}
                          {fmtDate(inv.expiresAt)}
                        </p>
                      </div>
                      <Button
                        variant="secondary"
                        size="sm"
                        disabled={busy}
                        onClick={() => cancelInvite(inv)}
                      >
                        ביטול
                      </Button>
                    </li>
                  ))}
                </ul>
              </section>
            ) : null}
          </>
        )}
      </div>
      <CitizenBottomNav active="settings" />
    </>
  );
}
