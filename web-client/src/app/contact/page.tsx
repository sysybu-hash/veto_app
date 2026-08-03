import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { ContactForm } from "@/components/contact/ContactForm";
import { getSupportEmail, getSupportWhatsapp } from "@/lib/env";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";

export const metadata: Metadata = {
  title: "צור קשר | VETO Legal",
  description:
    "תמיכה, פרטיות, מנויים והצטרפות עורכי דין — ערוצי יצירת קשר עם VETO Legal.",
};

export default function ContactPage() {
  const email = getSupportEmail();
  const waDigits = getSupportWhatsapp();
  const waHref = waDigits ? `https://wa.me/${waDigits}` : "";
  const approved = isLegalCommerciallyApproved();

  return (
    <div className="min-h-screen text-primary">
      <main
        className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12"
        dir="rtl"
      >
        <div className="mb-8">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-xl bg-veto-gold px-5 py-2.5 text-sm font-bold text-primary transition hover:opacity-90"
          >
            חזרה לדף הבית
          </Link>
        </div>

        <header className="mb-8 text-center md:text-right">
          <div className="mb-4 flex justify-center md:justify-end">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            צור קשר
          </h1>
          {!approved && (
            <p className="mt-3 rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-sm text-amber-900 dark:text-amber-100">
              <strong>טיוטת מוצר</strong> — ערוצי התמיכה והנוסחים המשפטיים
              ממתינים להשלמה ואישור סופי.
            </p>
          )}
          <p className="mt-3 text-sm leading-7 text-secondary md:text-base">
            לשאלות על השירות, תמיכה טכנית, מנויים או בקשות פרטיות — השתמשו
            בטופס או בערוצים למטה.{" "}
            <strong className="text-primary">
              במצב חירום מסכן חיים חייגו 100.
            </strong>{" "}
            לליווי עו״ד דחוף — התחברו והפעילו SOS באפליקציה.
          </p>
        </header>

        <div className="mb-6 grid gap-3 sm:grid-cols-2">
          {email ? (
            <a
              href={`mailto:${email}`}
              className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm font-semibold text-primary shadow-sm transition hover:border-veto-gold"
              dir="ltr"
            >
              <span className="mb-1 block text-xs font-bold text-muted" dir="rtl">
                אימייל תמיכה
              </span>
              {email}
            </a>
          ) : (
            <div className="rounded-2xl border border-dashed border-subtle bg-surface-raised-2 px-4 py-4 text-sm text-secondary shadow-sm">
              <span className="mb-1 block text-xs font-bold text-muted">
                אימייל תמיכה
              </span>
              יפורסם לאחר הגדרת כתובת רשמית. ניתן לשלוח פנייה בטופס — ההודעה
              תועתק לשליחה ידנית.
            </div>
          )}

          {waHref ? (
            <a
              href={waHref}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm font-semibold text-primary shadow-sm transition hover:border-veto-gold"
            >
              <span className="mb-1 block text-xs font-bold text-muted">
                WhatsApp
              </span>
              פתיחת שיחה עם התמיכה
            </a>
          ) : (
            <div className="rounded-2xl border border-subtle bg-surface-raised-2 px-4 py-4 text-sm text-secondary shadow-sm">
              <span className="mb-1 block text-xs font-bold text-muted">
                זמני מענה
              </span>
              פניות תמיכה — בימי עסקים, לרוב תוך 1–2 ימי עסקים. בקשות פרטיות —
              לפי מדיניות הפרטיות.
            </div>
          )}
        </div>

        <ContactForm supportEmail={email} />

        <div className="mt-6 space-y-3 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm shadow-sm md:p-8">
          <h2 className="text-lg font-bold text-primary">קישורים שימושיים</h2>
          <div className="grid gap-2 sm:grid-cols-2">
            <Link
              href="/privacy-rights"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              בקשות זכויות פרטיות
            </Link>
            <Link
              href="/playbooks"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              מדריכי חירום
            </Link>
            <Link
              href="/register/lawyer"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              הצטרפות עורכי דין
            </Link>
            <Link
              href="/pricing"
              className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              מחירים ומנויים
            </Link>
          </div>
          <div className="flex flex-wrap gap-4 border-t border-subtle pt-4 text-xs font-semibold text-muted md:text-sm">
            <Link href="/privacy" className="hover:text-primary">
              מדיניות פרטיות
            </Link>
            <Link href="/terms" className="hover:text-primary">
              תנאי שימוש
            </Link>
            <Link href="/cookies" className="hover:text-primary">
              מדיניות עוגיות
            </Link>
          </div>
        </div>
      </main>
    </div>
  );
}
