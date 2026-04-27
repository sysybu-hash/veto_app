# 🚀 VETO — מדריך Deploy מלא
## Render (Backend) + Vercel (Frontend Web)

---

## ארכיטקטורת Deploy

```
┌─────────────────────────────────────┐     ┌──────────────────────────────────────┐
│  VERCEL (Frontend)                  │     │  RENDER (Backend)                    │
│  Flutter Web — Static Site          │────▶│  Node.js + Express + Socket.io       │
│  https://veto-app.vercel.app        │     │  https://veto-app-new.onrender.com   │
└─────────────────────────────────────┘     └──────────────────────────────────────┘
                                                          │
                                            ┌─────────────┴──────────────┐
                                            │  MongoDB Atlas (Database)   │
                                            │  Cloudinary (Recordings)    │
                                            │  Gemini AI (Transcription)  │
                                            └────────────────────────────┘
```

---

## שלב 0 — לפני הכל: Push ל-GitHub

```bash
# ודא שאין סודות ב-repo
npm run check:git-secrets

# Push
git add .
git commit -m "chore: prepare for production deploy"
git push origin main
```

> ⚠️ `backend/.env` כבר ב-`.gitignore` — לא יעלה ל-GitHub.  
> **מפה לפירוט משתנים + לינקים (כולל מסלול בלי Firebase):** [backend/ENV_GUIDE.md](backend/ENV_GUIDE.md) ו־[backend/.env.example](backend/.env.example).  
> ✅ `frontend/build/web/` **כן** עולה (הוחרג מה-gitignore) — Vercel יגיש אותו ישירות.

---

## חלק א׳ — Render (Backend API)

### אפשרות 1: Blueprint (מומלץ — אוטומטי)

1. פתח [dashboard.render.com](https://dashboard.render.com)
2. **New → Blueprint**
3. בחר את ה-repo ו-branch `main`
4. Render יקרא את `render.yaml` ויצור שירות `veto-app-new`
5. בסיום הצג ← **Environment** ← הוסף ידנית את המשתנים הסודיים:

| משתנה | ערך |
|---|---|
| `MONGO_URI` | `mongodb+srv://user:pass@cluster/dbname?retryWrites=true&w=majority` |
| `JWT_SECRET` | מחרוזת אקראית ארוכה (מינימום 64 תווים) |
| `GOOGLE_CLIENT_SECRET` | מ-Google Cloud Console |
| `GEMINI_API_KEY` | מ-Google AI Studio |
| `GEMINI_MODEL` | אופציונלי — ברירת מחדל בקוד: `gemini-3.1-pro-preview`; ליציבות מלאה: `gemini-2.5-flash` |
| `CLOUDINARY_CLOUD_NAME` | מ-Cloudinary Dashboard |
| `CLOUDINARY_API_KEY` | מ-Cloudinary Dashboard |
| `CLOUDINARY_API_SECRET` | מ-Cloudinary Dashboard |
| `VAPID_PRIVATE_KEY` | `npx web-push generate-vapid-keys` |
| `SENTRY_DSN` | אופציונלי |

6. **Save Changes → Manual Deploy**

### אפשרות 2: Web Service ידני

Settings של השירות:

| שדה | ערך |
|---|---|
| **Root Directory** | `backend` |
| **Build Command** | `npm ci --legacy-peer-deps` |
| **Start Command** | `npm start` |
| **Health Check Path** | `/health` |

### בדיקה אחרי Deploy

```
GET https://veto-app-new.onrender.com/health
```

תגובה תקינה:
```json
{ "status": "ok", "db": "connected", "socket": true }
```

### טיפ: OTP בפיתוח (בלי SMS)

ב-Render Environment הוסף:
```
RETURN_OTP_IN_JSON = 1
```
תגובת `/api/auth/request-otp` תכלול את ה-OTP בשדה `otp`.  
**הסר בפרודקשן** כשמחברים ספק SMS.

### Free Tier — שינה אחרי חוסר שימוש

Render Free נכנס לשינה אחרי ~15 דקות. הבקשה הראשונה לוקחת 30–60 שניות.  
לשמירה על זמינות: הגדר **Cron Job** שמפעיל `/health` כל 14 דקות, או שדרג ל-Starter ($7/חודש).

---

## חלק ב׳ — Vercel (Flutter Web Frontend)

Flutter Web בנוי מראש ל-`frontend/build/web/` (**כולל ב-git**).  
Vercel מגיש את התיקייה הזו ישירות — **אין צורך ב-build step**.

### אפשרות 1: Vercel CLI (מהיר)

```bash
# התקן Vercel CLI
npm i -g vercel

# Deploy מתוך תיקיית frontend
cd frontend
vercel --prod
```

בשאלות:
- **Root Directory:** `.` (frontend)
- **Build Command:** *(ריק — לא נדרש)*
- **Output Directory:** `build/web`
- **Override?** `Yes`

### אפשרות 2: Vercel Dashboard

1. [vercel.com/new](https://vercel.com/new) → **Import Git Repository**
2. בחר את ה-repo
3. **Root Directory:** `frontend` (חשוב: כל הקבצים `scripts/vercel-assert.cjs` ו-`vercel.json` ב־`frontend` חייבים לעלות; לא להפנות `buildCommand` ל-`../scripts/…` — מחוץ ל־Root Vercel לא מעלה)
4. **Build & Output Settings** → Override (או השאר כמו ב-`frontend/vercel.json`):
   - Build Command: `node scripts/vercel-assert.cjs` (רק בודק שקיים `build/web` אחרי build מקומי/CI)
   - Output Directory: `build/web`
5. **Deploy**

URL שיתקבל: `https://veto-app-xxxx.vercel.app`

### בדיקה

- פתח את ה-URL — אמור לעלות מסך Landing
- Navigation לנתיבים כמו `/login` ולרענן דף — אמור לעבוד (SPA routing)

### עדכון Frontend (אחרי שינויי קוד)

```bash
# בנה מחדש
cd frontend
flutter build web --release

# Push ל-GitHub — Vercel יעשה redeploy אוטומטי
git add build/web
git commit -m "feat: rebuild web"
git push
```

---

## חלק ג׳ — Flutter Mobile (iOS / Android)

לאחר Deploy של הבאקנד:

```bash
cd frontend

# Android (debug)
flutter run -d android --dart-define=VETO_API_BASE=https://veto-app-new.onrender.com

# Android (release APK)
flutter build apk --release --dart-define=VETO_API_BASE=https://veto-app-new.onrender.com

# iOS (Simulator)
flutter run -d ios --dart-define=VETO_API_BASE=https://veto-app-new.onrender.com
```

> `VETO_API_BASE` — רק origin בלי `/api` (נוסף אוטומטית).  
> ב-Release builds: אם לא מגדירים `--dart-define`, הברירת מחדל היא `https://veto-app-new.onrender.com`.

### Windows + נתיב עם רווח (`VETO App\`)

```powershell
# פתרון: subst מיפוי Drive
subst V: "C:\נתיב\מלא\VETO App"
cd V:\frontend
flutter build web --release
```

---

## חלק ד׳ — משתני סביבה מקומיים

העתק והגדר:

```bash
cp backend/.env.example backend/.env
# ערוך backend/.env עם הערכים האמיתיים
```

משתנים נדרשים לפיתוח מקומי:

```env
PORT=5001
NODE_ENV=development
MONGO_URI=mongodb+srv://...
JWT_SECRET=your_secret_here
GEMINI_API_KEY=...
# GEMINI_MODEL=gemini-3-flash-preview
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
RETURN_OTP_IN_JSON=1
```

---

## פתרון בעיות

| בעיה | פתרון |
|---|---|
| `MONGO_URI is missing` | הוסף MONGO_URI ב-Render Environment |
| `Cannot find module` | ודא Root Directory = `backend` |
| `WebSocket connection failed` | בדוק שה-URL ב-app_config.dart מצביע ל-Render |
| Vercel מציג 404 | ודא Output Directory = `build/web` |
| `flutter_webrtc` לא עובד | דרוש HTTPS — Render ו-Vercel מספקים TLS אוטומטי |
| Render ישן (cold start) | הוסף `/health` ping כל 14 דקות או שדרג plan |

---

## סיכום URLs

| שירות | URL |
|---|---|
| **Backend API** | `https://veto-app-new.onrender.com/api` |
| **Health Check** | `https://veto-app-new.onrender.com/health` |
| **Frontend Web** | `https://veto-app-xxxx.vercel.app` |
| **Socket.io** | `https://veto-app-new.onrender.com` (WebSocket upgrade) |
