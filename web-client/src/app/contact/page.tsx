import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { getSupportEmail, getSupportWhatsapp } from "@/lib/env";

export const metadata: Metadata = {
  title: "צור קשר | VETO Legal",
  description: "ערוצי תמיכה ויצירת קשר עם VETO Legal.",
};

export default function ContactPage() {
  const email = getSupportEmail();
  const waDigits = getSupportWhatsapp();
  const waHref = waDigits ? `https://wa.me/${waDigits}` : "";

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
          <p className="mt-3 text-sm leading-7 text-secondary md:text-base">
            לשאלות על השירות, תמיכה טכנית או בקשות פרטיות — השתמשו בערוצים למטה.
            לפניות דחופות במצב חירום משפטי השתמשו בכפתור ה-SOS באפליקציה לאחר
            התחברות.
          </p>
        </header>

        <div className="space-y-4 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm shadow-sm md:p-8 md:text-base">
          {email ? (
            <a
              href={`mailto:${email}`}
              className="block rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              אימייל תמיכה: {email}
            </a>
          ) : (
            <p className="rounded-xl border border-subtle bg-surface-sunken px-4 py-3 text-secondary">
              כתובת התמיכה תפורסם בקרוב. בינתיים ניתן לעיין במדיניות הפרטיות
              ובתנאי השימוש.
            </p>
          )}

          {waHref ? (
            <a
              href={waHref}
              target="_blank"
              rel="noopener noreferrer"
              className="block rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
            >
              WhatsApp לתמיכה
            </a>
          ) : null}

          <Link
            href="/privacy-rights"
            className="block rounded-xl border border-subtle bg-surface-sunken px-4 py-3 font-semibold text-primary transition hover:border-veto-gold"
          >
            בקשות זכויות פרטיות
          </Link>

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
