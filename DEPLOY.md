# VETO — לינק קבוע לבדיקות (API ציבורי)

האפליקציה משתמשת ב-**Express + Socket.io** וארוח ארוך-זמן. **Vercel (Serverless)** לא מתאים כ-backend לפרויקט הזה.  
הפתרון המומלץ: **Render** (חינמי, URL קבוע מסוג `https://….onrender.com`) + אותו קוד ב-`backend/`.

## שלבים (פעם אחת)

1. **GitHub**  
   דחוף (push) את ה-repo (ללא `backend/.env` — כבר ב-`.gitignore`).

2. **Render**  
   - [Dashboard](https://dashboard.render.com) → **New** → **Blueprint**.  
   - בחר את ה-repo; Render יזהה את `render.yaml`.  
   - הגדר ב-**Environment** ערכים לסינכרון ידני (`sync: false`):
     - `MONGO_URI` — אותה מחרוזת Atlas כמו ב־`.env` מקומי.
     - `JWT_SECRET` — מחרוזת אקראית ארוכה (לא לשתף).

3. אחרי שה-Deploy ירוק, העתק את כתובת השירות, למשל:  
   `https://veto-api.onrender.com`

4. **Flutter** (מחשב או CI):

   ```bash
   flutter run --dart-define=VETO_API_BASE=https://veto-api.onrender.com
   ```

   אל תכלול `/api` ב־`VETO_API_BASE` — רק מקור (scheme + host).

## התנהגות מקומית (ללא שינוי)

- בלי `--dart-define=VETO_API_BASE` נשאר הלוגיקה הקיימת: `VETO_HOST`, tunnel, פורט 5001.

## הערות

- **Free tier** עלול להירדם אחרי חוסר שימוש; הבקשה הראשונה אחרי הפעלה מחדש עלולה לקחת ~30–60 שניות (`/health` עוזר לבדוק שחזר לפעילות).
- אם תרצה **Flutter Web** על Vercel — זה אפשרי בנפרד; ה-API נשאר על Render (או שירות דומה).
