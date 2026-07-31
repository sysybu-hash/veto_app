import type { Metadata } from "next";
import Link from "next/link";
import { VetoBrandLogo } from "@/components/brand/VetoBrandLogo";

export const metadata: Metadata = {
  title: "תנאי שימוש | VETO Legal",
  description: "תקנון ותנאי שימוש בפלטפורמת VETO Legal.",
};

export default function TermsPage() {
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
            תקנון ותנאי שימוש
          </h1>
          <p className="mt-3 text-sm text-muted">
            עדכון אחרון לצורכי תיעוד מוצרי — יש לקבל אישור משפטי לפני פרסום
            מסחרי סופי.
          </p>
        </header>

        <article className="space-y-10 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm text-secondary shadow-sm md:p-8 md:text-base">
          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">1. מבוא והסכמה</h2>
            <p>
              ברוכים הבאים ל־VETO Legal (&quot;המערכת&quot;, &quot;השירות&quot;,
              &quot;אנחנו&quot;). השימוש באתר, ביישומון ובשירותים הנלווים כפוף
              לתנאים המפורטים להלן. על ידי הרשמה, כניסה או שימוש בשירות — אתם
              מאשרים כי קראתם והבנתם את התנאים וכי הם מחייבים אתכם.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              2. מהות השירות — פלטפורמה טכנולוגית בלבד
            </h2>
            <p>
              VETO היא <strong className="text-primary">פלטפורמה טכנולוגית</strong>{" "}
              המאפשרת קישור בין משתמשים לבין עורכי דין רשומים, לרבות תיאום שיחות
              וידאו/קול, ניהול מסמכים וכלים משלימים.{" "}
              <strong className="text-primary">
                VETO אינה משרד עורכי דין, אינה מחזיקה ברישיון לשכה ואינה מעניקה
                ייעוץ משפטי מטעמה.
              </strong>{" "}
              כל תוכן משפטי, חוות דעת או הכוונה מקצועית מסופקים אך ורק על ידי עורך
              הדין העצמאי המעורב באירוע — ולא על ידי VETO.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              3. אחריות משפטית ויחסי עו״ד–לקוח
            </h2>
            <p>
              <strong className="text-primary">
                האחריות הבלעדית לייעוץ המשפטי, לדיוק המידע ולשיקול הדעת המקצועי
                חלה על עורך הדין המייעץ בשיחה או בערוץ התקשורת במערכת.
              </strong>{" "}
              VETO אינה צד ליחסי עו״ד–לקוח ואינה אחראית לתוצאות הליכים, להחלטות
              משפטיות או ליישום המלצות. המשתמש מצהיר כי יפנה לעורך דין נוסף או
              לערכאות במידת הצורך, וכי אינו סומך על השירות כתחליף לליווי משפטי
              מלא כאשר נדרש.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              4. מצבי חירום וסכנת חיים
            </h2>
            <p>
              המערכת נועדה לסיוע משפטי ראשוני ולתיאום עם עורכי דין, ואינה מהווה
              קו חירום רפואי, ביטחוני או משטרתי.{" "}
              <strong className="text-primary">
                במקרה של סכנת חיים, אלימות מיידית או איום בטיחותי — יש לפנות תחילה
                לכוחות הביטחון, להצלה או למוקדי חירום הרלוונטיים (למשל משטרה,
                מגן דוד אדום)
              </strong>
              , ולא להסתמך על VETO כערוץ יחיד.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              5. חובות המשתמש והתנהגות מקובלת
            </h2>
            <p>
              המשתמש מתחייב למסור פרטים נכונים, שלא להתחזות לאחר, שלא להעלות או
              לשתף תוכן בלתי חוקי, ולא לעשות שימוש לרעה בתשתית (לרבות ניסיונות
              פריצה, ספאם או הפרעה לשירות). עורכי דין נדרשים לספק פרטי זיהוי
              מקצועיים נכונים ולפעול בהתאם לכללי לשכת עורכי הדין ולדין החל.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              6. תשלומים, מנויים וביטול עסקה
            </h2>
            <p>
              השימוש במערכת עשוי להיות כרוך בתשלום בהתאם למסלול, לחבילה או לשירות
              שנרכשו, כפי שמוצג בעת הרכישה. עיבוד תשלומים עשוי להתבצע באמצעות ספקי
              סליקה חיצוניים, והתנאים המסחריים שלהם חלים בנוסף לתנאים אלה.{" "}
              <strong className="text-primary">
                ביטול עסקה, זיכויים והחזרים יתבצעו בהתאם להוראות חוק הגנת הצרכן,
                התשמ&quot;א–1981, ולמדיניות הביטולים המפורסמת בממשק הרכישה
              </strong>
              , ככל שהדין חל על העסקה.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              7. קניין רוחני
            </h2>
            <p>
              זכויות היוצרים, הסימנים המסחריים, עיצוב הממשק, הקוד, התיעוד והמסדים
              השייכים ל־VETO Legal שמורים לה בלבד, אלא אם צוין אחרת בכתב. אין
              להעתיק, לשכפל, לבצע הנדסה לאחור או לעשות שימוש מסחרי ללא הסכמה מפורשת.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              8. הגבלת אחריות
            </h2>
            <p>
              השירות ניתן &quot;כמות שהוא&quot; (AS IS), בכפוף לשיפורים ולתחזוקה
              שוטפת. במידה המרבית המותרת בדין, VETO לא תהיה אחראית לנזקים עקיפים,
              תוצאתיים, אובדן רווח או אובדן מידע שאינם נגרמו במישרין מתוך רשלנות
              כבדה מוכחת. אחריות כלפי המשתמש תוגבל, ככל שהדין מאפשר, לסכומים
              ששולמו בפועל עבור השירות בתקופה הרלוונטית.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">
              9. שינויים בתנאים וסיום שירות
            </h2>
            <p>
              אנו רשאים לעדכן את תנאי השימוש מעת לעת. שינוי מהותי יפורסם בממשק
              או בערוץ התקשורת המתאים. המשך שימוש לאחר פרסום עשוי להוות הסכמה
              לנוסח המעודכן. שמורה לנו הזכות להשעות או לסיים גישה במקרה של הפרת
              תנאים או סיכון לאבטחה.
            </p>
          </section>

          <section className="space-y-3 leading-relaxed">
            <h2 className="text-lg font-bold text-primary md:text-xl">10. יצירת קשר</h2>
            <p>
              לשאלות בנוגע לתנאי השימוש ניתן לפנות דרך ערוצי התמיכה המפורסמים
              באתר או ביישומון. לעניינים משפטיים רשמיים יש לפנות לכתובת שתפורסם
              על ידי החברה.
            </p>
          </section>

          <p className="border-t border-subtle pt-6 text-xs leading-relaxed text-muted">
            מסמך זה מהווה מסגרת מוצרית. אין במסמך זה כדי ליצור יחסי עו״ד–לקוח עם
            VETO, ואין להסתמך עליו כייעוץ משפטי אישי. יש להתייעץ עם עורך דין לפני
            קבלת החלטות משפטיות.
          </p>
        </article>
      </main>
    </div>
  );
}
