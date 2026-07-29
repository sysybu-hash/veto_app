import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";
import { authGlassPanel, btnPrimaryDark } from "@/lib/vetoGlass";

export const metadata: Metadata = {
  title: "מדיניות פרטיות | VETO Legal",
  description: "מדיניות הפרטיות של פלטפורמת VETO Legal.",
};

export default function PrivacyPage() {
  return (
    <div data-surface="ink" className="min-h-screen bg-veto-ink text-primary">
      <main
        className="mx-auto w-full max-w-3xl px-4 py-8 md:px-6 md:py-12"
        dir="rtl"
      >
        <div className="mb-8">
          <Link
            href="/"
            className={`inline-flex items-center justify-center rounded-xl px-5 py-2.5 text-sm font-bold transition hover:opacity-90 ${btnPrimaryDark}`}
          >
            חזרה לדף הבית
          </Link>
        </div>

        <header className="mb-8 text-center md:text-right">
          <div className="mb-4 flex justify-center md:justify-end">
            <VetoBrandLogo className="h-9 w-auto sm:h-10" />
          </div>
          <h1 className="font-display text-3xl font-bold text-primary md:text-4xl">
            מדיניות פרטיות
          </h1>
          <p className="mt-3 text-sm text-muted">
            עדכון אחרון לצורכי תיעוד מוצרי — יש לקבל אישור משפטי ופרטיות (DPO)
            לפני פרסום מסחרי סופי.
          </p>
        </header>

        <article
          className={`space-y-10 p-6 text-sm text-slate-300 md:p-8 md:text-base ${authGlassPanel}`}
        >
          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">1. מבוא</h2>
            <p>
              מדיניות זו מסבירה כיצד VETO Legal (&quot;אנחנו&quot;, &quot;המערכת&quot;)
              אוספת, משתמשת, מאחסנת ומגנה על מידע אישי ובהיקף השירות. אנו מחויבים
              לשקיפות ולמינימיזציה של נתונים — תוך מתן שירות חירום ומשפטי איכותי.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              2. איזה מידע אנו אוספים
            </h2>
            <ul className="list-inside list-disc space-y-2 marker:text-veto-gold">
              <li>
                <strong className="text-primary">פרטי זיהוי וחשבון:</strong> שם,
                מספר טלפון, דוא״ל (אם סופק), תפקיד (אזרח/עורך דין/מנהל), העדפות
                שפה והגדרות חשבון.
              </li>
              <li>
                <strong className="text-primary">מיקום גיאוגרפי:</strong> בעת
                הפעלת מצבי חירום (למשל SOS) או כאשר המשתמש מאשר — נאסף מיקום
                לצורך תיאום עם עורך דין ושירותי שדה. המיקום אינו נאסף לצורכי פרופיל
                שיווקי.
              </li>
              <li>
                <strong className="text-primary">נתוני שימוש וטכניים:</strong>{" "}
                יומני גישה, מזהי מכשיר, כתובת IP (לצורכי אבטחה ומניעת הונאה),
                אירועי מערכת ומדדי ביצועים — לשם שיפור השירות ויציבות התשתית.
              </li>
              <li>
                <strong className="text-primary">תוכן משתמש:</strong> מסמכים,
                קבצים, הודעות צ&apos;אט ופניות תמיכה שהועלו במסגרת השירות, בכפוף
                להרשאות והגדרות הכספת.
              </li>
            </ul>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              3. בסיסים משפטיים ומטרות עיבוד
            </h2>
            <p>
              העיבוד מבוצע לצורך ביצוע חוזה (מתן השירות), אינטרסים לגיטימיים
              (אבטחה, שיפור מוצר), עמידה בחובות חוקיות, ובמקרים מסוימים — הסכמה
              מפורשת (למשל התראות או תכונות אופציונליות). איננו משתמשים במידע
              לפרופיל שיווקי חיצוני ללא בסיס חוקי מתאים.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              4. חיסיון עו״ד–לקוח והצפנה מקצה לקצה (E2EE)
            </h2>
            <p>
              שיחות הווידאו והקול במערכת עשויות להיות מוגנות בהצפנה מקצה לקצה
              (E2EE), בהתאם לתצורת המוצר והספקים הטכנולוגיים.{" "}
              <strong className="text-primary">
                VETO אינה צופה, אינה מאזינה ואינה מנתחת את תוכן השיחות המוגנות
                בחיסיון עו״ד–לקוח
              </strong>{" "}
              במסגרת התכונה הזו, בכפוף לדין החל, להגדרות המוצר ולחריגים טכניים
              מוגבלים (למשל מטא-דאטה לצורך חיבור השיחה או עמידה בצו שיפוטי).
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              5. הקלטות, תמלולים וכספת (Vault)
            </h2>
            <p>
              אם המשתמש בחר במפורש בהקלטה או בתיעוד, והרשאות המערכת מאפשרות זאת,
              הקבצים עשויים להישמר בכספת מאובטחת (Vault) או באחסון מוצפן,{" "}
              <strong className="text-primary">
                בנגישות מוגבלת למשתמש ולעורך הדין המטפל באירוע — בכפוף להרשאות,
                להסכמות ולדין
              </strong>
              . VETO אינה משתמשת בתוכן ההקלטות לצורכי שיווק. שמירת חומר רגיש היא
              באחריות המשתמש לנהל הרשאות וסיסמאות בצורה נאותה.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              6. שיתוף מידע וצדדים שלישיים
            </h2>
            <p>
              <strong className="text-primary">
                המידע לא יימכר ולא יועבר לצד ג&apos; למטרות שיווקיות של צדדים
                חיצוניים.
              </strong>{" "}
              שיתוף יתבצע רק ככל הנדרש לתפעול השירות — לדוגמה ספקי ענן, תשלומים,
              אימות זהות, תמיכה טכנית ואבטחה — ובהתאם להסכמי עיבוד (DPA) ולתקן
              האבטחה המקובל. ייתכן מסירת מידע לפי צו שיפוטי חוקי או דרישת רגולטור,
              לאחר בדיקה משפטית.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              7. אבטחה ושמירת מידע
            </h2>
            <p>
              אנו מיישמים אמצעי אבטחה ארגוניים וטכנולוגיים (הרשאות, הצפנה במעבר
              ובמנוחה ככל הניתן, ניטור, גיבויים). אין מערכת חסינה ב־100% — במקרה
              של דליפה נפעל בהתאם לדין להודעה ולתיקון.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              8. זכויות נושאי מידע
            </h2>
            <p>
              בכפוף לדין החל (לרבות תקנות הגנת הפרטיות, התשמ&quot;א–1981, וחוקים
              בינלאומיים כאשר רלוונטי), ניתן לבקש גישה, תיקון, מחיקה, הגבלת עיבוד
              או העברת נתונים. בקשות יטופלו בתוך פרקי זמן סבירים, בכפוף לאימות
              זהות ולמגבלות חוקיות (שמירה לצורך הליכים, מניעת הונאה וכו׳).
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              9. העברה בינלאומית וספקי שירות
            </h2>
            <p>
              חלק מספקי התשתית עשויים לאחסן מידע מחוץ לישראל או לאיחוד האירופי.
              במקרה כזה נפעל להבטחת מנגנונים חוקיים להעברה (הסכמים, סעיפי הגנה
              מתאימים) ככל שנדרש.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              10. שינויים במדיניות ויצירת קשר
            </h2>
            <p>
              מדיניות זו עשויה להתעדכן. שינוי מהותי יפורסם בממשק השירות. לשאלות
              בנוגע לפרטיות ניתן לפנות דרך ערוצי התמיכה המפורסמים באתר או
              ביישומון.
            </p>
          </section>

          <p className="border-t border-subtle pt-6 text-xs leading-relaxed text-muted">
            מסמך זה נועד לשקיפות מוצרית. אין במסמך משום ייעוץ משפטי אישי; לשאלות
            ספציפיות על זכויותיכם מול VETO מומלץ לפנות לייעוץ משפטי עצמאי.
          </p>
        </article>
      </main>
    </div>
  );
}
