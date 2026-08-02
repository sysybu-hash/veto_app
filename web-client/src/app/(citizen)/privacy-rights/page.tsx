"use client";

import { useEffect, useState } from "react";
import { Download, Eraser, FilePenLine } from "lucide-react";
import {
  createPrivacyRequest,
  fetchPrivacyRequests,
  type PrivacyRequest,
} from "@/api/advancedApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import {
  btnSecondaryGlass,
  citizenBottomSafe,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";
import { LinkButton } from "@/components/ui/primitives/LinkButton";

const actions = [
  { type: "export", title: "ייצוא מידע", body: "בקשה לקבלת עותק מהמידע האישי.", icon: Download },
  { type: "delete", title: "מחיקת מידע", body: "בקשה למחיקת מידע בכפוף לחובות שמירה.", icon: Eraser },
  { type: "correct", title: "תיקון מידע", body: "בקשה לתקן פרט אישי שגוי.", icon: FilePenLine },
] as const;

export default function PrivacyRightsPage() {
  const [requests, setRequests] = useState<PrivacyRequest[]>([]);
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const refresh = () => {
    void fetchPrivacyRequests().then(setRequests).catch(() => setRequests([]));
  };

  useEffect(refresh, []);

  const submit = async (type: PrivacyRequest["type"]) => {
    setBusy(type);
    setMessage(null);
    try {
      await createPrivacyRequest(type, note);
      setNote("");
      setMessage("הבקשה נשלחה ותופיע ברשימה.");
      refresh();
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "שליחת הבקשה נכשלה.");
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
      <section className={`${glassPanel} p-6`}>
        <p className="text-sm font-black text-veto-gold">EU Compliance Mode</p>
        <h1 className="mt-2 font-frank text-3xl font-black text-primary">זכויות פרטיות</h1>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-secondary">
          ניתן לשלוח בקשות ייצוא, מחיקה או תיקון מידע. הבקשות ייבדקו מול חובות שמירת ראיות, תשלומים ואבטחת מידע.
        </p>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="הערה אופציונלית לבקשה"
          className="mt-5 min-h-28 w-full rounded-2xl border border-subtle bg-surface-raised p-4 text-sm text-primary outline-none focus:ring-2 focus:ring-veto-gold"
        />
        <div className="mt-4 grid gap-3 md:grid-cols-3">
          {actions.map((action) => {
            const Icon = action.icon;
            return (
              <button
                key={action.type}
                type="button"
                onClick={() => void submit(action.type)}
                disabled={busy !== null}
                className={`${btnSecondaryGlass} p-4 text-end disabled:opacity-50`}
              >
                <Icon className="h-5 w-5 text-veto-gold" aria-hidden />
                <span className="mt-3 block font-black text-primary dark:text-primary">
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
          <p className="mt-4 rounded-2xl border border-subtle bg-surface-sunken px-4 py-3 text-sm text-primary dark:bg-white/10 dark:text-primary">
            {message}
          </p>
        )}

        <div className={`${glassPanelNested} mt-6 p-4`}>
          <h2 className="text-lg font-black text-primary dark:text-primary">בקשות אחרונות</h2>
          <div className="mt-4 space-y-3">
            {requests.length === 0 && (
              <p className="text-sm text-secondary">אין בקשות פתוחות.</p>
            )}
            {requests.map((request) => (
              <div
                key={request._id}
                className="flex items-center justify-between gap-3 rounded-2xl border border-subtle bg-surface-raised p-4 dark:bg-white/[0.03]"
              >
                <div>
                  <p className="font-black text-primary dark:text-primary">{request.type}</p>
                  <p className="text-xs text-secondary">
                    {new Intl.DateTimeFormat("he-IL", {
                      dateStyle: "short",
                      timeStyle: "short",
                    }).format(new Date(request.createdAt))}
                  </p>
                </div>
                <span className="rounded-full bg-veto-gold/15 px-3 py-1 text-xs font-bold text-veto-gold-light">{request.status}</span>
              </div>
            ))}
          </div>
        </div>
        <LinkButton href="/transparency" variant="primary" size="md" className="mt-5">
          מרכז שקיפות AI
        </LinkButton>
      </section>
    </main>
    <CitizenBottomNav active="settings" />
    </>
  );
}
