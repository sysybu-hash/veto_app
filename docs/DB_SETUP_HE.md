# הגדרת מסד הנתונים לאתר (Next.js + Prisma)

מדריך פשוט בעברית. למסמך באנגלית עם הקשר נוסף ראו [DEPLOY.md](../DEPLOY.md).

## מה צריך
חשבון חינמי ב‑Neon (מסד Postgres בענן): <https://console.neon.tech>

## מה לעשות

1. התחבר/י ל‑Neon וצור/י פרויקט חדש (אפשר שם `veto`).

2. בתוך הפרויקט, לחצי על **Connection string** או **Connect** והעתיקו את כתובת ה‑PostgreSQL (מתחילה בדרך כלל ב‑`postgresql://`).

3. פתח/י את הקובץ בשם `.env` שנמצא בתיקייה:

   ```text
   veto_legal\.env
   ```

   (זה אותו תיק שבו נמצא גם `backend/` ו‑`web-client/`).

4. מצא/י את השורה:

   ```dotenv
   DATABASE_URL=
   ```

   והדבק/י אחרי סימן השווה את מחרוזת החיבור שהעתקת מ‑Neon. דוגמה (בלי סיסמה אמיתית):

   ```dotenv
   DATABASE_URL=postgresql://USER:PASSWORD@ep-xxxxx.region.aws.neon.tech/neondb?sslmode=require
   ```

5. שמרו את הקובץ.

6. בחלון PowerShell בתיקיית `veto_legal` הריצו פעם אחת:

   ```powershell
   npm run db:push
   ```

   (זה יוצר את הטבלאות במסד.)

   אם מופיע שגיאה על `localhost` במקום Neon — ייתכן שב‑Windows מוגדר משתנה סביבה `DATABASE_URL` ישן. הפרויקט כבר מריץ `db:push` דרך סקריפט שדורס זאת מקובץ `.env` — אם עדיין יש בעיה, מחקו `DATABASE_URL` מ"משתני סביבה" במחשב.

7. להרצת האתר לפיתוח:

   ```powershell
   npm run dev:web
   ```

## הערות

- אם משהו לא עובד, שלחו למפתח צילום מסך של השגיאה (בלי להדביק סיסמה).
- אל תשתפו את קובץ `.env` ואל תעלו אותו לאינטרנט — שם סיסמאות.
