import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "תנאי שימוש",
  description: "תנאי שימוש בסיסיים עבור VETO Legal.",
};

export default function TermsPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-16 text-right text-slate-100" dir="rtl">
      <p className="text-sm font-semibold text-[#C5A059]">VETO Legal</p>
      <h1 className="mt-3 font-frank text-4xl font-black">תנאי שימוש</h1>
      <div className="mt-8 space-y-6 rounded-2xl border border-white/10 bg-white/[0.04] p-6 leading-8 text-slate-300">
        <p>
          VETO מספקת תשתית טכנולוגית לחיבור מהיר בין אזרחים לעורכי דין, כספת ראיות וכלי מסמכים. השירות אינו מחליף
          ייעוץ משפטי פרטני מעורך דין מוסמך.
        </p>
        <section>
          <h2 className="text-xl font-bold text-white">שימוש אחראי</h2>
          <p className="mt-2">
            המשתמש מתחייב למסור מידע נכון, לא להעלות תוכן בלתי חוקי, לא להתחזות לאחר, ולא להשתמש בשירות כדי לפגוע
            באחרים או לשבש מערכות.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">עורכי דין</h2>
          <p className="mt-2">
            עורכי דין נדרשים להזדהות, למסור מספר רישיון ותחומי התמחות, ולהמתין לאישור מנהל לפני קבלת קריאות. אישור
            במערכת אינו מהווה המלצה משפטית או התחייבות לזמינות.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">תשלומים ומנויים</h2>
          <p className="mt-2">
            מנויים, ייעוצים ודקות נוספות מחויבים לפי המחירים שמוצגים באתר בזמן הרכישה. תשלומי PayPal מנוהלים אצל
            PayPal, והסטטוס במערכת מתעדכן לאחר אישור התשלום או webhook.
          </p>
        </section>
        <p className="text-sm text-slate-400">
          הנוסח הוא תשתית מוצרית ראשונית ונדרש אישור משפטי לפני פרסום מסחרי מלא.
        </p>
      </div>
      <Link href="/" className="mt-8 inline-flex rounded-xl bg-[#C5A059] px-5 py-3 text-sm font-bold text-slate-950">
        חזרה לדף הבית
      </Link>
    </main>
  );
}
