import type { Metadata } from "next";
import { LegalPageShell } from "@/components/legal/LegalPageShell";
import { isLegalCommerciallyApproved } from "@/lib/legalMode";

export const metadata: Metadata = {
  title: "הצהרת נגישות | Accessibility | VETO Legal",
  description:
    "הצהרת הנגישות של VETO Legal — רמת התאמה, אמצעי נגישות, מגבלות ידועות ודרכי פנייה.",
};

/**
 * Accessibility statement. Required by the Israeli equal-rights accessibility
 * regulations (IS 5568 / WCAG 2.0 AA) and expected under EN 301 549 for the
 * EU European Accessibility Act.
 *
 * The conformance measures listed below are the ones actually implemented and
 * verified in CI (see e2e/specs/a11y.spec.ts and scripts/check-contrast.mjs).
 * This page deliberately does NOT claim an external audit — add that claim only
 * once a certified auditor has signed off, together with their name and date.
 */
export default function AccessibilityPage() {
  return (
    <LegalPageShell
      titleKey="legalChrome.accessibilityTitle"
      approved={isLegalCommerciallyApproved()}
    >
      <article className="space-y-8 rounded-2xl border border-subtle bg-surface-raised-2 p-6 text-sm leading-8 text-secondary shadow-sm md:p-8 md:text-base">
        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            המחויבות שלנו
          </h2>
          <p className="mt-2">
            VETO Legal היא מערכת חירום משפטית. אנחנו רואים בנגישות תנאי בסיס —
            אדם במצוקה חייב להיות מסוגל להגיע לעורך דין ללא מכשול, בכל אמצעי
            קלט ובכל טכנולוגיה מסייעת.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            רמת ההתאמה
          </h2>
          <p className="mt-2">
            האתר נבנה במטרה לעמוד בתקן הישראלי ת&quot;י 5568 ברמה AA, המבוסס על
            הנחיות <strong className="text-primary">WCAG 2.1 ברמה AA</strong>,
            ובהתאמה ל־EN 301 549 האירופי.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            אמצעי הנגישות שיושמו
          </h2>
          <ul className="mt-2 list-disc space-y-1 pe-5">
            <li>ניווט מלא במקלדת בכל הרכיבים האינטראקטיביים, עם סימון מיקוד ברור.</li>
            <li>מבנה כותרות סמנטי, תגיות ARIA ותוויות לשדות טפסים.</li>
            <li>
              יחסי ניגודיות של 4.5:1 לפחות לטקסט, במצב בהיר ובמצב כהה כאחד —
              נבדק אוטומטית בכל בנייה.
            </li>
            <li>תמיכה מלאה ב־RTL, ובשלוש שפות: עברית, אנגלית ורוסית.</li>
            <li>כיבוד העדפת המערכת להפחתת אנימציות ולמצב כהה.</li>
            <li>טקסט חלופי לתמונות ולסמלים נושאי משמעות.</li>
          </ul>
        </section>

        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            מגבלות ידועות
          </h2>
          <p className="mt-2">
            חדר השיחה בווידאו נשען על רכיבי צד שלישי שנגישותם אינה בשליטתנו
            המלאה. אנו פועלים לצמצם פערים אלה. אם נתקלתם בתוכן שאינו נגיש —
            נשמח שתדווחו, ונטפל בפנייה בהקדם.
          </p>
        </section>

        {/* תקנה 35 לתקנות שוויון זכויות לאנשים עם מוגבלות מחייבת שם ופרטי
            התקשרות של רכז נגישות. כתובת המייל למטה מספקת את ערוץ הפנייה;
            הוסיפו כאן גם את שם הרכז ברגע שימונה. */}
        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            פניות בנושא נגישות
          </h2>
          <p className="mt-2">
            נשמח לקבל דיווח על כל מכשול נגישות. ניתן לפנות אלינו במייל ישירות
            לקבוצת הפיתוח בכתובת{" "}
            <a
              className="font-bold text-brand-text underline underline-offset-2"
              href="mailto:YB@BSD-YBM.CO.IL"
            >
              YB@BSD-YBM.CO.IL
            </a>
            , או דרך{" "}
            <a
              className="font-bold text-brand-text underline underline-offset-2"
              href="/contact"
            >
              עמוד צור קשר
            </a>
            . בפנייה מומלץ לציין את כתובת העמוד, תיאור התקלה והטכנולוגיה המסייעת
            שבה השתמשתם — כך נוכל לשחזר ולתקן מהר יותר.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            כיצד נבדקה הנגישות
          </h2>
          <p className="mt-2">
            הנגישות נבדקת אוטומטית בכל גרסה של האתר, ולא באופן חד־פעמי: סריקת
            axe-core רצה על כל עמודי האתר — הציבוריים והמאובטחים — במצב בהיר
            ובמצב כהה, ובדיקת יחסי ניגודיות רצה על כל צמדי הצבעים של מערכת
            העיצוב. גרסה שנמצאת בה הפרה אינה נפרסת.
          </p>
          <p className="mt-2">
            הבדיקות האוטומטיות אינן תחליף לבדיקה אנושית, ואינן מכסות כל תרחיש.
            אם נתקלתם במכשול — הפנייה שלכם היא הדרך המהירה ביותר שנדע עליו.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-primary md:text-xl">
            עדכון אחרון
          </h2>
          <p className="mt-2">5 באוגוסט 2026</p>
        </section>
      </article>
    </LegalPageShell>
  );
}
