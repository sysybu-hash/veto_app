# חוברת סקירה לעורכי דין — VETO Legal

## קובץ מוכן
- `VETO_Legal_Lawyer_Briefing.pdf` — חוברת מכובדת בעברית עם צילומי מסך חיים מהאתר
- עותק נוסף נוצר גם על שולחן העבודה: `Desktop/VETO_Legal_Lawyer_Briefing.pdf`

> **ה-PDF ותיקיית `screenshots/` אינם ב-git** — הם פלט בנייה (כ-7.5MB בינאריים)
> ונוצרים מחדש מהפקודות שלמטה. מה שכן נשמר בגיט הוא המקור: `brochure.html`,
> סקריפטי הבנייה, ונכסי המותג ב-`assets/`.

## רענון צילומים + PDF
מתוך `web-client/`:

```bash
node --input-type=module ../docs/lawyer-brochure/capture-screens.mjs
# או השימוש בסקריפט המקומי:
node scripts/build-lawyer-brochure-pdf.mjs
```

להפעלת לכידת המסכים מתוך `web-client` (שם מותקן Playwright), העתיקו את לוגיקת `capture-screens.mjs` להרצה עם import מ־`playwright` כמו ב־`scripts/build-lawyer-brochure-pdf.mjs`.

## מקור
- אתר חי: https://web-nine-gamma-76.vercel.app
- עריכת תוכן: `brochure.html`
