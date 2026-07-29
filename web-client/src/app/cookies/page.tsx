import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

export const metadata: Metadata = {
  title: "מדיניות עוגיות",
  description: "מדיניות עוגיות בסיסית עבור VETO Legal.",
};

export default function CookiesPage() {
  return (
    <main
      className="mx-auto w-full max-w-4xl px-5 py-16 text-end text-primary"
      dir="rtl"
    >
      <div className="flex justify-end">
        <VetoBrandLogo className="h-9 w-auto sm:h-10" />
      </div>
      <h1 className="mt-3 font-frank text-4xl font-black">מדיניות עוגיות</h1>
      <div className="mt-8 space-y-6 rounded-2xl border border-subtle bg-surface-raised-2 p-6 leading-8 text-secondary shadow-sm">
        <section>
          <h2 className="text-xl font-bold text-primary">עוגיות חיוניות</h2>
          <p className="mt-2">
            נדרשות להתחברות, אבטחה, שמירת העדפות שפה, תפעול תשלומים והגנה מפני שימוש לרעה. לא ניתן לכבות אותן בלי
            לפגוע בשירות.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-primary">מדידה ושיפור</h2>
          <p className="mt-2">
            יופעלו רק לאחר הסכמה. המטרה היא להבין ביצועים, תקלות וחוויית שימוש בלי למכור מידע אישי.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-primary">שיווק</h2>
          <p className="mt-2">
            יופעל רק לאחר הסכמה מפורשת, אם וכאשר יתווספו קמפיינים שיווקיים או מדידת המרות.
          </p>
        </section>
        <p className="text-sm text-secondary">
          ניתן לנקות את העדפות העוגיות דרך הגדרות הדפדפן. בהמשך יתווסף מרכז העדפות מלא מתוך החשבון.
        </p>
      </div>
      <Link href="/" className="mt-8 inline-flex rounded-xl bg-veto-gold px-5 py-3 text-sm font-bold text-primary">
        חזרה לדף הבית
      </Link>
    </main>
  );
}
