import type { Metadata } from "next";
import { LegalPageShell } from "@/components/legal/LegalPageShell";
import { CookiePreferencesCard } from "@/components/privacy/CookiePreferencesCard";

export const metadata: Metadata = {
  title: "מדיניות עוגיות | Cookies | VETO Legal",
  description: "מדיניות עוגיות בסיסית עבור VETO Legal.",
};

export default function CookiesPage() {
  return (
    <LegalPageShell titleKey="legalChrome.cookiesTitle" approved>
      <article className="space-y-8 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm leading-8 text-secondary shadow-sm md:p-8 md:text-base">
        <CookiePreferencesCard />
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
    </LegalPageShell>
  );
}
