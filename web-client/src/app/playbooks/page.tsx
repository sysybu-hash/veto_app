import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";
import { PLAYBOOKS } from "@/lib/playbooks";

export const metadata: Metadata = {
  title: "מדריכי חירום | VETO Legal",
  description:
    "מדריכי התמצאות ראשונית למצבי חירום משפטיים בישראל — מעצר, תעבורה ומשפחה. מידע כללי בלבד.",
};

export default function PlaybooksIndexPage() {
  const approved = isLegalCommerciallyApproved();

  return (
    <div className="min-h-screen text-primary">
      <main
        className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12"
        dir="rtl"
      >
        <div className="mb-8 flex flex-wrap gap-3">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-xl bg-veto-gold px-5 py-2.5 text-sm font-bold text-primary transition hover:opacity-90"
          >
            חזרה לדף הבית
          </Link>
          <Link
            href="/login?redirect=%2Fhub"
            className="inline-flex items-center justify-center rounded-xl border border-subtle bg-surface-raised px-5 py-2.5 text-sm font-bold text-primary transition hover:border-veto-gold"
          >
            התחברות ל־SOS
          </Link>
        </div>

        <header className="mb-8 text-center md:text-right">
          <div className="mb-4 flex justify-center md:justify-end">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            מדריכי חירום
          </h1>
          <p className="mt-3 text-sm leading-7 text-secondary md:text-base">
            התמצאות ראשונית למצבים נפוצים. בחרו מדריך — ואם נדרש ליווי עו״ד,
            התחברו והפעילו SOS.
          </p>
          <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
            <strong>מידע כללי בלבד — אינו ייעוץ משפטי.</strong> במצב חירום מסכן
            חיים התקשרו ל־100.
            {!approved
              ? " נוסח המדריכים ממתין גם לאישור משפטי סופי (טיוטת מוצר)."
              : null}
          </p>
        </header>

        <ul className="space-y-3">
          {PLAYBOOKS.map((p) => (
            <li key={p.id}>
              <Link
                href={`/playbooks/${p.id}`}
                className="block rounded-2xl border border-subtle bg-surface-raised-2 p-5 shadow-sm transition hover:border-veto-gold"
              >
                <h2 className="text-lg font-bold text-primary">{p.titleHe}</h2>
                <p className="mt-1 text-sm text-secondary">{p.subtitleHe}</p>
                <span className="mt-3 inline-block text-xs font-bold text-veto-gold">
                  לפתיחת המדריך ←
                </span>
              </Link>
            </li>
          ))}
        </ul>

        <p className="mt-8 text-center text-sm text-muted">
          ראו גם{" "}
          <Link href="/terms" className="font-semibold underline">
            תנאי שימוש
          </Link>{" "}
          ו־
          <Link href="/contact" className="font-semibold underline">
            צור קשר
          </Link>
          .
        </p>
      </main>
    </div>
  );
}
