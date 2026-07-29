# 🚀 VETO — מדריך Deploy מלא
## Render (Backend) + Vercel (Frontend Web)

---

## הכנה לפרודקשן — מה נוסף (2026-07)

תוכנית מלאה נמצאת ב-[docs/](docs/) (ר' `SOS_MVP_DECISIONS.md`, `DOMAIN_SOURCE_OF_TRUTH.md`, `LEGAL_REVIEW_PACKAGE.md`). שינויים שכבר יושמו בקוד:

- **⚠️ Service Worker לא נבנה כלל (תוקן 2026-07)**: `next build` (ברירת מחדל, Next.js 16) משתמש ב-Turbopack; `@ducanh2912/next-pwa` נתלה רק ב-hook של webpack ולכן היה **no-op שקט** — `/sw.js` החזיר 404 בפרודקשן החי, ומשמעות מעשית: **התראות Push ל-SOS לעורכי דין (`worker/index.ts`) כנראה לא עבדו כלל** מזמן שה-build עבר ל-Next 16. תוקן: `package.json` `build` משתמש עכשיו ב-`next build --webpack` (ר' `web-client/next.config.mjs`). **אחרי כל deploy — לוודא `curl -I https://<domain>/sw.js` מחזיר 200, לא 404.**
  - כחלק מהתיקון גם צומצם `cacheOnFrontEndNav`/`aggressiveFrontEndNavCaching` (היו `true`, עכשיו `false`) — הם שמרו HTML/RSC של ניווטים בקאש, מה שיצר תרחיש של HTML ישן + JS חדש (React hydration error #418) בטאבים שנשארו פתוחים מעבר ל-deploy. משתמשים עם מצב תקוע: hard refresh / "Clear site data".
- **CORS**: `*.vercel.app` הוסר כברירת מחדל — חובה `CORS_ALLOWED_ORIGINS` בפרודקשן. ר' [backend/ENV_GUIDE.md](backend/ENV_GUIDE.md#web-client-nextjs-על-vercel--cors).
- **PayPal webhook**: השרת מסרב לעלות בפרודקשן אם `PAYPAL_CLIENT_ID` מוגדר בלי `PAYPAL_WEBHOOK_ID`.
- **OTP**: rate limiting ייעודי (keyed by phone) על `/api/auth/verify-otp`.
- **Health check** (`GET /health`): פינג אמיתי ל-Mongo/Redis, לא רק `readyState`.
- **SOS**: כשל Ably כבר לא מוחק את רשומת ה-`SosEvent` — מסומן `PENDING_DELIVERY` + Sentry alert.
- **CI** (`.github/workflows/ci.yml`): נוספו jobs ל-secret scanning (gitleaks, כל היסטוריית git), `npm audit` (report-only כרגע — יש vulnerabilities קיימים שדורשים טיפול ייעודי), ו-Playwright E2E (report-only, artifact מועלה).
- **Keepalive** (`.github/workflows/keepalive.yml`): פינג `/health` כל 14 דק' — אלטרנטיבה חינמית לשדרוג Render.
- **Logging**: `pino` מובנה (`backend/src/lib/logger.js`) + `pino-http` ללוגים מובנים לכל בקשה; **כל** `console.log/error/warn` ב-`backend/src` הומר.
- **404 גלובלי**: תגובת JSON אחידה לכל נתיב לא מוכר.
- **אינדקסים**: נוספו אינדקסים מורכבים ל-`EmergencyEvent` ו-`VaultFile` (האחרון לא היה מאונדקס בכלל לפי `user_id`).
- **`npm audit fix`** (ללא `--force`) הורץ בשני הפרויקטים ואומת (build+lint+tests+boot מקומי אמיתי): **backend** 32→16 פרצות, **הקריטית היחידה (`websocket-driver`) נסגרה**. **web-client** 23→21.
  - **נותר, דורש `--force` (לא בוצע — סיכון שבירה, לא טופל אוטומטית):**
    - backend: שרשרת טרנזיטיבית של `firebase-admin`/`@google-cloud/*` (moderate/high) — שדרוג `firebase-admin` ישיר עצמו כשמוכן.
    - web-client: `next` יידרש לעלות ל-`16.2.12` (מחוץ לפין המדויק `16.2.6` שנבחר בכוונה — ר' `web-client/AGENTS.md`), ו-`@ducanh2912/next-pwa` יירד ל-`10.2.6` (breaking change, נמוך מהפין הנוכחי `^10.2.9`). לפני שדרוג: לבדוק release notes + להריץ build+E2E מלא.

---

## ארכיטקטורת Deploy

```
┌─────────────────────────────────────┐     ┌──────────────────────────────────────┐
│  VERCEL (Frontend)                  │     │  RENDER (Backend)                    │
│  Next.js — תיקיית `web-client/`     │────▶│  Node.js + Express + Socket.io       │
│  (דומיין לפי הפרויקט ב-Vercel)      │     │  https://veto-app-new.onrender.com   │
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
> **ווב פרודקשן:** Vercel בונה את **`web-client`** (Next.js). ארטיפקט Flutter ב־`frontend/build/web/` הוא **legacy**; ראו [web-client/.env.example](web-client/.env.example) למשתני `NEXT_PUBLIC_*`.

---

## חלק א׳ — Render (Backend API)

### אפשרות 1: Blueprint (מומלץ — אוטומטי)

1. פתח [dashboard.render.com](https://dashboard.render.com)
2. **New → Blueprint**
3. בחר את ה-repo ו-branch `main`
4. Render יקרא את `render.yaml` ויצור שירות `veto_legal`
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

> **שירות API אחד בפרוד:** אם יש שני Web Services (למשל שם ישן `veto-app-new` + שירות חדש), זה **לא** נפתר בקוד בלבד. ב־[Render Dashboard](https://dashboard.render.com) בחר שירות **אחד** שמייצג את ה־API, שמור עליו את כל ה־Environment, והתאם אליו את **כל** המקורות: `VETO_API_BASE` ב־CI, `PUBLIC_API_BASE` (אם מוגדר), וברירת ה־host ב־`AppConfig` — ראו [ENV_GUIDE — Render, URL](backend/ENV_GUIDE.md#9-render).

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

### ⚠️ אבטחה — `ALLOW_DEV_LOGIN` חייב להיות כבוי בפרודקשן

**נמצא ב-2026-07-29:** משתנה הסביבה `ALLOW_DEV_LOGIN=1` מוגדר כרגע גם על שרת ה-Render
של הפרודקשן החי. זה הופך את `POST /api/auth/dev-login`
(`backend/src/controllers/auth.controller.js`) לפעיל שם — כל מי שיודע את שם
המשתמש/סיסמה הקבועים בברירת המחדל (`***REDACTED***` / `***REDACTED***`, וגם ניתנים
לדריסה ע"י `DEV_LOGIN_USERNAME`/`DEV_LOGIN_PASSWORD`) יכול לקבל טוקן JWT תקף לכל
תפקיד (`admin`/`lawyer`/`user`) **בלי שום אימות אמיתי**. השם/הסיסמה הקבועים גם
מופיעים כברירת מחדל בקוד (`auth.controller.js`) ובקובץ ה-E2E fixture
(`web-client/e2e/fixtures/auth.ts`) — שניהם ב-git history הציבורי.

**פעולה נדרשת (טרם בוצעה — הוחלט להשאיר לטיפול נפרד):** להסיר את `ALLOW_DEV_LOGIN`
מ-Render Environment בפרודקשן (Dashboard → Environment), ולשקול להחליף את
`DEV_LOGIN_USERNAME`/`DEV_LOGIN_PASSWORD` בברירת מחדל אקראית/סוד ייעודי כדי
שהערך שכבר דלף ב-git history לא יישאר שמיש גם בסביבות עתידיות שיפעילו את הדגל בטעות.

### Free Tier — שינה אחרי חוסר שימוש

Render Free נכנס לשינה אחרי ~15 דקות. הבקשה הראשונה לוקחת 30–60 שניות.  
לשמירה על זמינות: הגדר **Cron Job** שמפעיל `/health` כל 14 דקות, או שדרג ל-Starter ($7/חודש).

### שיחות וידאו (Agora) — סדר deploy מומלץ

1. **Render (backend)** — לפרוס תחילה כשיש שינוי ב־`agoraToken.service.js` (ייצור UID ייחודי לטוקן) או בנתיבי טוקן. אם ה־API בפרוד עדיין ישן, הלקוח עלול לקבל `UID_CONFLICT`.
2. **Next.js (`web-client`)** — `git push` ל־`main` מפעיל CI שבונה ומעלה ל־**Vercel** (או פריסה אוטומטית דרך חיבור Git ל-Vercel). ודא ש־`NEXT_PUBLIC_AGORA_APP_ID` (ואופציונלי משתנים נוספים) מוגדרים ב-Vercel.
3. **Flutter Web (אופציונלי)** — אם עדיין בונים `frontend/build/web/` — commit נפרד; לא מחליף את פריסת `web-client`.

פרטי בדיקה ידנית בין דפדפנים: [docs/CALL_QA_MATRIX.md](docs/CALL_QA_MATRIX.md).

---

## חלק ב׳ — Vercel (Frontend Web)

### Next.js — `web-client` (הפריסה הנוכחית)

האפליקציה ב-Next.js נמצאת ב־**`web-client/`** (שורש ה-repo), **לא** בתוך `frontend/`.

ב־[Vercel Project Settings → General](https://vercel.com/) עדכן:

| שדה | ערך נכון |
|-----|-----------|
| **Root Directory** | `web-client` |

**אל** תגדיר `frontend/web-client` — התיקייה הזו **לא קיימת** ב-repo. אם הוגדרה שם, תקבל:

`The provided path "…/frontend/web-client" does not exist`

Framework זוהה בדרך־כלל כ־**Next.js** אוטומטית. Build: `npm run build` (ברירת מחדל).

**משתני סביבה לדוגמה** (ב־Vercel → Environment Variables):

- `NEXT_PUBLIC_API_ORIGIN` — מקור ה־API (למשל `https://veto-app-new.onrender.com`, בלי `/api`).
- `NEXT_PUBLIC_VAPID_PUBLIC_KEY` — אם משתמשים ב־Web Push (חלק מזהות הזוג של `VAPID` בשרת).
- `NEXT_PUBLIC_AGORA_APP_ID` — אם יש שיחות Agora מהדפדפן.

#### GitHub Actions → Vercel

ב־`main`, אחרי `backend-ci`, job **`deploy-vercel`**:
1. בונה מקומית ב־**`web-client/`** (`npm ci`, `npm run build`) — לוודא שהקוד עובר build.
2. מריץ **`vercel deploy --prod` משורש ה-repo** (לא מתוך `web-client/`). ב־Vercel מוגדר **Root Directory = `web-client`** — אם מריצים את ה-CLI מתוך `web-client`, Vercel מחבר פעמיים את הנתיב ומקבלים שגיאת `web-client/web-client`.  
נדרשים Secrets ב-repo: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

אם ב-Vercel מופעל גם **Deploy מחיבור Git** לאותו branch, ייתכן **שני** deploys לכל push — כדאי לבחור שיטה אחת או לכבות את הכפול.

#### דוגמת משתנים מקומיים

ראו [web-client/.env.example](web-client/.env.example).

---

### Flutter Web (legacy, קפוא) — `frontend/build/web`

> ⚠️ **`frontend/` קפוא — אין לפתח כאן.** ר' [frontend/README.md](frontend/README.md). ההוראות הבאות נשמרות רק לצורך תחזוקת הארטיפקט הקיים (אם עדיין מוגש איפשהו), לא לפיתוח פעיל. הלקוח הפעיל היחיד הוא `web-client/`. תחליף המובייל העתידי הוא `mobile/` (Expo, WIP — ר' [mobile/README.md](mobile/README.md)), לא `frontend/`.

Flutter Web בנוי מראש ל-`frontend/build/web/` (**כלול ב-git אם נשמר שם ארטיפקט**).  
Vercel מגיש את התיקייה הזו ישירות — **אין צורך ב-build step** במודל הישן.

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
> ב-Release builds: אם לא מגדירים `--dart-define`, הברירת מחדל היא `https://veto-app-new.onrender.com` (ולהתאים ל-**Public URL** ב-Render).

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
| Vercel מציג 404 | ודא Output Directory = `build/web` (Flutter) או Root = `web-client` (Next.js) |
| `frontend/web-client` does not exist | ב־Vercel שנה **Root Directory** ל־`web-client` (לא תחת `frontend`) |
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
