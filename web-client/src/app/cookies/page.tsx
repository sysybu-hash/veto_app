import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

export const metadata: Metadata = {
  title: "מדיניות עוגיות | VETO Legal",
  description: "מדיניות עוגיות בסיסית עבור VETO Legal.",
};

export default function CookiesPage() {
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
            מדיניות עוגיות
          </h1>
          <p className="mt-3 text-sm text-muted">
            ההעדפות נשמרות בדפדפן וניתנות לשינוי דרך באנר העוגיות או ניקוי
            localStorage.{" "}
            <Link href="/contact" className="font-semibold text-primary underline">
              צור קשר
            </Link>
          </p>
        </header>

        <article className="space-y-8 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm leading-8 text-secondary shadow-sm md:p-8 md:text-base">
          <section>
            <h2 className="text-lg font-bold text-primary md:text-xl">עוגיות חיוניות</h2>
            <p className="mt-2">
              נדרשות להתחברות, אבטחה, שמירת העדפות שפה, תפעול תשלומים והגנה מפני
              שימוש לרעה. לא ניתן לכבות אותן בלי לפגוע בשירות.
            </p>
          </section>
          <section>
            <h2 className="text-lg font-bold text-primary md:text-xl">מדידה ושיפור</h2>
            <p className="mt-2">
              יופעלו רק לאחר הסכמה מפורשת בקטגוריית &quot;מדידה ושיפור&quot;. כיום
              משתמשים ב־
              <strong className="text-primary"> PostHog</strong> לניתוח שימוש
              וביצועים (pageviews, אירועי מוצר). אין טעינת PostHog לפני הסכמה;
              בביטול הסכמה המדידה מופסקת.
            </p>
          </section>
          <section>
            <h2 className="text-lg font-bold text-primary md:text-xl">שיווק</h2>
            <p className="mt-2">
              יופעל רק לאחר הסכמה מפורשת, אם וכאשר יתווספו קמפיינים שיווקיים או
              מדידת המרות.
            </p>
          </section>
        </article>
      </main>
    </div>
  );
}
