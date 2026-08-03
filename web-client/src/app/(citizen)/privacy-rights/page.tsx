"use client";

import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { Download, Eraser, FilePenLine, LogIn } from "lucide-react";
import {
  createPrivacyRequest,
  fetchPrivacyRequests,
  type PrivacyRequest,
} from "@/api/advancedApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import { LinkButton } from "@/components/ui/primitives/LinkButton";
import { getJwt } from "@/lib/authToken";
import {
  btnSecondaryGlass,
  citizenBottomSafe,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";

const actions = [
  {
    type: "export" as const,
    title: "ייצוא מידע",
    body: "בקשה לקבלת עותק מהמידע האישי השמור אצלנו.",
    icon: Download,
  },
  {
    type: "delete" as const,
    title: "מחיקת מידע",
    body: "בקשה למחיקה — בכפוף לחובות שמירה, תשלומים ואבטחה.",
    icon: Eraser,
  },
  {
    type: "correct" as const,
    title: "תיקון מידע",
    body: "בקשה לתקן פרט אישי שגוי או לא מעודכן.",
    icon: FilePenLine,
  },
] as const;

const TYPE_HE: Record<PrivacyRequest["type"], string> = {
  export: "ייצוא",
  delete: "מחיקה",
  correct: "תיקון",
};

const STATUS_HE: Record<string, string> = {
  pending: "ממתין לטיפול",
  open: "פתוח",
  in_progress: "בטיפול",
  completed: "הושלם",
  rejected: "נדחה",
  closed: "נסגר",
};

function statusLabel(status: string): string {
  const key = status.toLowerCase();
  return STATUS_HE[key] ?? status;
}

function mapPrivacyError(raw: string): string {
  if (/not authenticated/i.test(raw)) {
    return "יש להתחבר כדי לשלוח בקשת פרטיות.";
  }
  if (/failed to fetch|networkerror/i.test(raw)) {
    return "לא ניתן להתחבר לשרת כרגע. נסו שוב בעוד רגע.";
  }
  return raw;
}

export default function PrivacyRightsPage() {
  const [authed, setAuthed] = useState<boolean | null>(null);
  const [requests, setRequests] = useState<PrivacyRequest[]>([]);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const refresh = useCallback(() => {
    if (!getJwt()) {
      setAuthed(false);
      setRequests([]);
      return;
    }
    setAuthed(true);
    void fetchPrivacyRequests()
      .then(setRequests)
      .catch(() => setRequests([]));
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const submit = async (type: PrivacyRequest["type"]) => {
    if (!getJwt()) {
      setMessage("יש להתחבר כדי לשלוח בקשה.");
      setAuthed(false);
      return;
    }
    setBusy(type);
    setMessage(null);
    try {
      await createPrivacyRequest(type, note);
      setNote("");
      setMessage("הבקשה נשלחה בהצלחה ותופיע ברשימה למטה.");
      refresh();
    } catch (e) {
      const raw = e instanceof Error ? e.message : "שליחת הבקשה נכשלה.";
      setMessage(mapPrivacyError(raw));
    } finally {
      setBusy(null);
    }
  };

  return (
    <>
      <main
        className={`mx-auto w-full max-w-5xl px-4 py-10 text-end ${citizenBottomSafe}`}
        dir="rtl"
      >
        <section className={`${glassPanel} p-6 md:p-8`}>
          <p className="text-sm font-bold text-veto-gold">זכויות מידע · פרטיות</p>
          <h1 className="mt-2 font-display text-3xl font-bold text-primary">
            זכויות פרטיות
          </h1>
          <p className="mt-3 max-w-3xl text-sm leading-7 text-secondary md:text-base">
            כאן ניתן להגיש בקשות לייצוא, מחיקה או תיקון מידע אישי הקשור לחשבון
            VETO שלכם. הבקשות נבדקות מול חובות שמירת ראיות, חיובים, ואבטחת מידע —
            בהתאם למדיניות הפרטיות.
          </p>
          <p className="mt-2 text-xs text-muted">
            למידע נוסף ראו את{" "}
            <Link href="/privacy" className="font-semibold text-veto-gold underline">
              מדיניות הפרטיות
            </Link>{" "}
            ואת{" "}
            <Link href="/contact" className="font-semibold text-veto-gold underline">
              עמוד צור קשר
            </Link>
            .
          </p>

          {authed === false && (
            <div className="mt-6 rounded-2xl border border-veto-gold/40 bg-veto-gold/10 px-4 py-4 text-sm text-primary">
              <p className="font-semibold">נדרשת התחברות</p>
              <p className="mt-1 text-secondary">
                כדי להגיש בקשת פרטיות ולראות בקשות קודמות — יש להיכנס לחשבון.
              </p>
              <Link
                href="/login?redirect=%2Fprivacy-rights"
                className="mt-3 inline-flex items-center gap-2 rounded-xl bg-veto-gold px-4 py-2.5 text-sm font-bold text-primary"
              >
                <LogIn className="h-4 w-4" aria-hidden />
                התחברות והמשך
              </Link>
            </div>
          )}

          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="הערה אופציונלית לבקשה (למשל: איזה פרט לתקן)"
            disabled={authed === false}
            className="mt-5 min-h-28 w-full rounded-2xl border border-subtle bg-surface-raised p-4 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold disabled:opacity-60"
          />

          <div className="mt-4 grid gap-3 md:grid-cols-3">
            {actions.map((action) => {
              const Icon = action.icon;
              return (
                <button
                  key={action.type}
                  type="button"
                  onClick={() => void submit(action.type)}
                  disabled={busy !== null || authed === false}
                  className={`${btnSecondaryGlass} p-4 text-end disabled:opacity-50`}
                >
                  <Icon className="h-5 w-5 text-veto-gold" aria-hidden />
                  <span className="mt-3 block font-bold text-primary">
                    {action.title}
                  </span>
                  <span className="mt-1 block text-sm leading-6 text-secondary">
                    {action.body}
                  </span>
                </button>
              );
            })}
          </div>

          {message && (
            <p
              className="mt-4 rounded-2xl border border-subtle bg-surface-sunken px-4 py-3 text-sm text-primary"
              role="status"
            >
              {message}
            </p>
          )}

          <div className={`${glassPanelNested} mt-6 p-4`}>
            <h2 className="text-lg font-bold text-primary">בקשות אחרונות</h2>
            <div className="mt-4 space-y-3">
              {authed === false && (
                <p className="text-sm text-secondary">
                  לאחר התחברות יוצגו כאן הבקשות שלכם.
                </p>
              )}
              {authed && requests.length === 0 && (
                <p className="text-sm text-secondary">אין בקשות פתוחות.</p>
              )}
              {requests.map((request) => (
                <div
                  key={request._id}
                  className="flex items-center justify-between gap-3 rounded-2xl border border-subtle bg-surface-raised p-4"
                >
                  <div>
                    <p className="font-bold text-primary">
                      {TYPE_HE[request.type] ?? request.type}
                    </p>
                    <p className="text-xs text-secondary">
                      {new Intl.DateTimeFormat("he-IL", {
                        dateStyle: "short",
                        timeStyle: "short",
                      }).format(new Date(request.createdAt))}
                    </p>
                    {request.note ? (
                      <p className="mt-1 text-xs text-muted">{request.note}</p>
                    ) : null}
                  </div>
                  <span className="rounded-full bg-veto-gold/15 px-3 py-1 text-xs font-bold text-veto-gold">
                    {statusLabel(request.status)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-5 flex flex-wrap gap-3">
            <LinkButton href="/transparency" variant="primary" size="md">
              מרכז שקיפות AI
            </LinkButton>
            <LinkButton href="/contact" variant="secondary" size="md">
              צור קשר
            </LinkButton>
          </div>
        </section>
      </main>
      <CitizenBottomNav active="settings" />
    </>
  );
}
