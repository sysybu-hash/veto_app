# VETO — לינק קבוע לבדיקות (API ציבורי)

האפליקציה משתמשת ב-**Express + Socket.io** וארוח ארוך-זמן. **Vercel (Serverless)** לא מתאים כ-backend לפרויקט הזה.  
הפתרון המומלץ: **Render** (חינמי, URL קבוע מסוג `https://….onrender.com`) + אותו קוד ב-`backend/`.

## שלבים (פעם אחת)

1. **GitHub**  
   דחוף (push) את ה-repo (ללא `backend/.env` — כבר ב-`.gitignore`).

2. **Render** (מומלץ: Blueprint)  
   - [Dashboard](https://dashboard.render.com) → **New** → **Blueprint**.  
   - בחר את ה-repo; Render קורא את `render.yaml` (שירות **`veto-app`**, `rootDir: backend`).  
   - ב-**Environment** חובה:
     - `MONGO_URI` — כמו ב־`backend/.env` (Atlas).
     - `JWT_SECRET` — מחרוזת סודית ארוכה.
   - **בדיקת התחברות Web בלי SMS:** הוסף `RETURN_OTP_IN_JSON` = `1` — אז תשובת `request-otp` תכלול את ה-OTP (להסיר כשמחברים SMS).

3. **אם כבר יש Web Service ו־Failed deploy** (למשל יצרת מ-GitHub בלי Blueprint):  
   **Settings** של השירות:
   - **Root Directory:** `backend`  
   - **Build Command:** `npm ci`  
   - **Start Command:** `npm start`  
   או השאר **Root Directory ריק** ואז:
   - **Build Command:** `npm run render-build`  
   - **Start Command:** `npm run render-start`  
   ואז **Save** → **Manual Deploy** → **Clear build cache & deploy**.

4. אחרי Deploy ירוק, הכתובת לרוב:  
   `https://veto-app.onrender.com`  
   בדיקה: `https://veto-app.onrender.com/health`

5. **Flutter**:

   - **בניית release / פרודקשן** (`flutter build web` וכו'): ברירת המחדל היא כבר `https://veto-app.onrender.com` — אין חובה ב־`--dart-define`.
   - **בדיקה מ־debug מול Render:**

   ```bash
   cd frontend
   flutter run -d chrome --dart-define=VETO_API_BASE=https://veto-app.onrender.com
   ```

   אל תכלול `/api` ב־`VETO_API_BASE` — רק מקור (scheme + host); הנתיב `/api` נוסף אוטומטית ל־REST.

   **Windows + נתיב עם רווח** (למשל `...\VETO App\`): בניית Web נכשלת בגלל hook של `objective_c`. פתרונות:
   - הרץ: `powershell -ExecutionPolicy Bypass -File "...\VETO App\scripts\flutter-web.ps1"` (ממפה `V:` ב־`subst` ומריץ מ־`V:\frontend`), או
   - העבר את הפרויקט לתיקייה **בלי רווח** (למשל `C:\dev\veto-app`), או
   - `subst V: "C:\מלא\נתיב\VETO App"` ואז `cd V:\frontend` ו־`flutter run ...`.

## התנהגות לפי מצב

- **Debug / profile** בלי `VETO_API_BASE`: `VETO_HOST`, tunnel (`loca.lt`), או `localhost:5001` לפי ההגדרות ב־`app_config.dart`.
- **Release**: אם לא הוגדר `VETO_API_BASE`, משתמשים ב־`https://veto-app.onrender.com` (קבוע `kDefaultRenderOrigin`).

## אם עדיין נכשל

- **Logs** ב-Render: חפש `MONGO_URI is missing` או `Cannot find module` — הראשון = חסר env; השני = build לא רץ מתוך `backend` או לא השתמשת ב־`render-build`.

## הערות

- **Free tier** עלול להירדם אחרי חוסר שימוש; הבקשה הראשונה אחרי הפעלה מחדש עלולה לקחת ~30–60 שניות (`/health` עוזר לבדוק שחזר לפעילות).
- אם תרצה **Flutter Web** על Vercel — זה אפשרי בנפרד; ה-API נשאר על Render (או שירות דומה).
