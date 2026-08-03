# חבילת סקירה משפטית — טקסטים המוצגים למשתמש

**מטרה:** לפני שהמערכת יוצאת לפרודקשן אמיתי עם משתמשי קצה, כל הטקסטים המשפטיים/הסכמתיים הבאים חייבים לעבור סקירת עו״ד. העמודים החיים מציגים באנר **"טיוטת מוצר — לא לפרסום מסחרי סופי"** עד לאישור.

זהו מסמך ניתוב בלבד (לא מעתיק את כל הטקסט) — לכל פריט יש path + מספור הסעיפים הקיים בקוד, כדי שעו״ד יוכל לפתוח את הקובץ/העמוד ולעבור סעיף-סעיף.

## כתובות חיות (אחרי deploy)

החלף את הבסיס ב-`NEXT_PUBLIC_SITE_URL` שלך:

| עמוד | Path בקוד | URL |
|------|-----------|-----|
| תנאי שימוש | `web-client/src/app/terms/page.tsx` | `{SITE}/terms` |
| מדיניות פרטיות | `web-client/src/app/privacy/page.tsx` | `{SITE}/privacy` |
| מדיניות עוגיות | `web-client/src/app/cookies/page.tsx` | `{SITE}/cookies` |
| צור קשר | `web-client/src/app/contact/page.tsx` | `{SITE}/contact` |
| זכויות פרטיות | `(citizen)/privacy-rights` | `{SITE}/privacy-rights` |

**פרטי ארגון (מ-env, לא בקוד):**

| שדה | משתנה |
|-----|--------|
| אימייל תמיכה / DPO זמני | `NEXT_PUBLIC_SUPPORT_EMAIL` |
| WhatsApp תמיכה | `NEXT_PUBLIC_SUPPORT_WHATSAPP` |
| שם חברה / כתובת רשמית | למלא כאן אחרי אישור: **\[\[COMPANY_LEGAL_NAME\]\]** / **\[\[REGISTERED_ADDRESS\]\]** |
| DPO | **\[\[DPO_NAME_OR_EMAIL\]\]** |

## Checklist לפני הסרת באנר טיוטה

- [ ] עו״ד אישר `/terms` (כל הסעיפים)
- [ ] עו״ד / DPO אישר `/privacy`
- [ ] `/cookies` תואם ל-CookieConsent + PostHog בפועל
- [ ] הסכמת הקלטה בשיחה (`ConsentBanner`) אושרה
- [ ] Disclaimer למחולל מסמכי AI אושר
- [ ] פרטי חברה / DPO / אימייל תמיכה סופיים ב-env ובמסמך זה
- [ ] הוחלף באנר הטיוטה בתאריך עדכון אמיתי ב-`terms` ו-`privacy`
- [ ] תאריך אישור משפטי תועד למטה

**תאריך אישור משפטי:** _טרם_
**שם מאשר:** _טרם_

---

## 1. תנאי שימוש — `web-client/src/app/terms/page.tsx`
דף חי: `/terms`. סעיפים כולל יצירת קשר → `/contact`:
1. מבוא והסכמה
2. מהות השירות — פלטפורמה טכנולוגית בלבד
3. אחריות משפטית ויחסי עו״ד–לקוח **(קריטי)**
4. מצבי חירום וסכנת חיים **(קריטי — SOS)**
5. חובות המשתמש
6. תשלומים, מנויים וביטול עסקה
7. קניין רוחני
8. הגבלת אחריות
9. שינויים בתנאים וסיום שירות
10. יצירת קשר

## 2. מדיניות פרטיות — `web-client/src/app/privacy/page.tsx`
דף חי: `/privacy`. כולל קישור ל-`/contact` ו-`/privacy-rights`.
סעיפים 1–10 כפי שבקוד — במיוחד E2EE, הקלטות, מעבדי-משנה (Cloudinary, Gemini, Agora, Ably, PayPal, **PostHog** אחרי הסכמה).

## 3. מדיניות עוגיות — `web-client/src/app/cookies/page.tsx`
דף חי: `/cookies`. קטגוריות: חיוניות, מדידה (PostHog), שיווק. חייב להתאים ל-`CookieConsent.tsx` + `PostHogAnalytics.tsx`.

## 4. הסכמת הקלטת ענן בשיחה — `ConsentBanner.tsx` + i18n `call.v2.consent.*`

## 5. מחרוזות i18n עם ניסוח משפטי
`web-client/src/lib/i18n/locales/{he,en,ru}.ts`

## 6. הפקת מסמכים משפטיים אוטומטית (AI)
`web-client/src/app/api/generate-document/route.ts` ו-`backend/src/services/legalDocumentEngine.service.js`

## 7. Legacy — `frontend/lib/screens/legal_document_screen.dart`
Flutter קפוא — **לא** לכלול בסבב הסקירה הנוכחי. SoT הוא `web-client/`.

---

## המלצה תהליכית
1. לשלוח לעו״ד את ה-URL-ים בסעיף "כתובות חיות" + סעיפים 1–4.
2. אחרי אישור — לעבור על ה-checklist למעלה ולהסיר באנרי טיוטה.
3. לתעד תאריך אישור במסמך זה.

*אין לראות במסמך זה ייעוץ משפטי — הוא רשימת ניתוב טכנית בלבד.*
