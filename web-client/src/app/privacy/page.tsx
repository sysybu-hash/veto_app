import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "מדיניות פרטיות",
  description: "מדיניות פרטיות בסיסית עבור VETO Legal.",
};

export default function PrivacyPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-16 text-right text-slate-100" dir="rtl">
      <p className="text-sm font-semibold text-[#C5A059]">VETO Legal</p>
      <h1 className="mt-3 font-frank text-4xl font-black">מדיניות פרטיות</h1>
      <div className="mt-8 space-y-6 rounded-2xl border border-white/10 bg-white/[0.04] p-6 leading-8 text-slate-300">
        <p>
          VETO נבנית כמערכת Legal OS שמטפלת במידע רגיש. אנחנו אוספים מידע רק לצורך מתן השירות:
          אימות משתמשים, חיבור לעורך דין, ניהול כספת ראיות, תשלומים, מנויים ותיעוד פעולות אבטחה.
        </p>
        <section>
          <h2 className="text-xl font-bold text-white">מידע שנשמר</h2>
          <p className="mt-2">
            פרטי חשבון, טלפון, אימייל, תפקיד, סטטוס מנוי, קריאות SOS, מסמכים שהמשתמש יוצר או שומר,
            ותיעוד טכני שנדרש לאבטחה ולתפעול. הקלטות או תמלולים נשמרים רק כחלק מהשירות ובכפוף לבחירת המשתמש וההרשאות.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">זכויות משתמש</h2>
          <p className="mt-2">
            משתמשים יכולים לבקש גישה, תיקון, מחיקה, הגבלת עיבוד או ייצוא מידע אישי. בקשות מחיקה ייבדקו מול חובות
            שמירה, מניעת הונאה, תיעוד משפטי ואבטחת מידע.
          </p>
        </section>
        <section>
          <h2 className="text-xl font-bold text-white">עיבוד מחוץ לאיחוד האירופי</h2>
          <p className="mt-2">
            השירות עשוי להשתמש בספקי ענן, תשלומים ובינה מלאכותית. לפני הפעלה מלאה באירופה יש לאשר משפטית את הסכמי
            העיבוד, העברת המידע ומנגנוני האבטחה מול כל ספק.
          </p>
        </section>
        <p className="text-sm text-slate-400">
          הנוסח הוא תשתית מוצרית ראשונית ואינו מחליף מדיניות פרטיות משפטית חתומה.
        </p>
      </div>
      <Link href="/" className="mt-8 inline-flex rounded-xl bg-[#C5A059] px-5 py-3 text-sm font-bold text-slate-950">
        חזרה לדף הבית
      </Link>
    </main>
  );
}
