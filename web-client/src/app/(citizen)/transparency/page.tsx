"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Bot, FileText, MessageCircle, ShieldCheck } from "lucide-react";
import { fetchTransparencyLogs, type TransparencyLog } from "@/api/advancedApi";
import { CitizenBottomNav } from "@/components/citizen/CitizenBottomNav";
import {
  btnSecondaryGlass,
  citizenBottomSafe,
  glassPanel,
  glassPanelNested,
} from "@/lib/vetoGlass";

export default function TransparencyPage() {
  const [logs, setLogs] = useState<TransparencyLog[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void fetchTransparencyLogs()
      .then((items) => {
        if (!cancelled) setLogs(items);
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "לא ניתן לטעון לוגים.");
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <>
    <div
      className={`mx-auto w-full max-w-5xl px-4 py-10 text-end ${citizenBottomSafe}`}
      dir="rtl"
    >
      <section className={`${glassPanel} p-6`}>
        <p className="text-sm font-black text-brand-text">AI Transparency Center</p>
        <h1 className="mt-2 font-frank text-3xl font-black text-primary">מרכז שקיפות AI</h1>
        <p className="mt-2 max-w-3xl text-sm leading-7 text-secondary">
          כאן מוצגות פעולות שבהן AI סייע במערכת. כל פלט AI הוא כלי עזר בלבד ודורש בדיקה אנושית לפני הסתמכות משפטית.
        </p>

        <div className="mt-6 grid gap-3 md:grid-cols-3">
          <TrustCard icon={Bot} title="גילוי שימוש" body="המערכת מסמנת מתי AI השתתף בפעולה." />
          <TrustCard icon={ShieldCheck} title="בדיקה אנושית" body="פלט משפטי אינו מחליף עורך דין מוסמך." />
          <TrustCard icon={FileText} title="לוג מינימלי" body="נשמר מידע תפעולי בלי לשמור תוכן רגיש שלא לצורך." />
        </div>

        <div className={`${glassPanelNested} mt-6 p-4`}>
          <div className="flex items-center justify-between gap-3">
            <h2 className="text-lg font-black text-primary dark:text-primary">פעולות אחרונות</h2>
            <Link href="/privacy-rights" className={`px-4 py-2 text-sm font-bold ${btnSecondaryGlass}`}>
              זכויות פרטיות
            </Link>
          </div>
          {error && <p className="mt-4 text-sm text-red-600 dark:text-red-300">{error}</p>}
          {!error && logs.length === 0 && (
            <p className="mt-4 text-sm text-secondary">אין עדיין פעולות AI מתועדות.</p>
          )}
          <div className="mt-4 space-y-3">
            {logs.map((log) => (
              <article
                key={log._id}
                className="rounded-2xl border border-subtle bg-surface-raised p-4 dark:bg-white/[0.03]"
              >
                <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                  <div className="flex items-start gap-3">
                    <MessageCircle className="mt-0.5 h-5 w-5 text-brand-text" aria-hidden />
                    <div>
                      <p className="font-black text-primary dark:text-primary">{log.action}</p>
                      <p className="mt-1 text-xs text-muted">
                        מקור: {log.source} · {new Intl.DateTimeFormat("he-IL", { dateStyle: "short", timeStyle: "short" }).format(new Date(log.createdAt))}
                      </p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2 text-xs">
                    {log.produced_output && <span className="rounded-full bg-emerald-500/15 px-2 py-1 text-emerald-200">נוצר פלט</span>}
                    {log.used_fallback && <span className="rounded-full bg-amber-500/15 px-2 py-1 text-amber-200">Fallback</span>}
                    {log.requires_lawyer_review && <span className="rounded-full bg-white/10 px-2 py-1 text-primary">דורש בדיקה</span>}
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>
    </div>
    <CitizenBottomNav active="hub" />
    </>
  );
}

function TrustCard({ icon: Icon, title, body }: { icon: typeof Bot; title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-subtle bg-surface-raised p-4">
      <Icon className="h-5 w-5 text-veto-gold-dark dark:text-brand-text" aria-hidden />
      <p className="mt-3 font-black text-primary">{title}</p>
      <p className="mt-1 text-sm leading-6 text-secondary dark:text-secondary">{body}</p>
    </div>
  );
}
