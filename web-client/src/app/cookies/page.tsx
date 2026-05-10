import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "מדיניות עוגיות",
  description: "מדיניות עוגיות בסיסית עבור VETO Legal.",
};

export default function CookiesPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-16 text-right text-slate-100" dir="rtl">
      <p className="text-sm font-semibold text-[#C5A059]">VETO Legal</p>
      <h1 className="mt-3 font-frank text-4xl font-black">מדיניות עוגיות</h1>
      <div className="mt-8 space-y-6 rounded-2xl border border-white/10 bg-white/[0.04] p-6 leading-8 text-slate-300">
        <section>
          <h2 className="text-xl font-bold text-white">עוגיות חיוניות</h2>
          <p className="mt-2">
            נדרשות להתחברות, אבטחה, שמירת העדפות שפה, תפעול תשלומים והגנה מפני שימוש לרעה. לא ניתן לכבות אותן בלי
            לפגוע בשירות.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">מדידה ושיפור</h2>
          <p className="mt-2">
            יופעלו רק לאחר הסכמה. המטרה היא להבין ביצועים, תקלות וחוויית שימוש בלי למכור מידע אישי.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">שיווק</h2>
          <p className="mt-2">
            יופעל רק לאחר הסכמה מפורשת, אם וכאשר יתווספו קמפיינים שיווקיים או מדידת המרות.
          </p>
        </section>
        <p className="text-sm text-slate-400">
          ניתן לנקות את העדפות העוגיות דרך הגדרות הדפדפן. בהמשך יתווסף מרכז העדפות מלא מתוך החשבון.
        </p>
      </div>
      <Link href="/" className="mt-8 inline-flex rounded-xl bg-[#C5A059] px-5 py-3 text-sm font-bold text-slate-950">
        חזרה לדף הבית
      </Link>
    </main>
  );
}
