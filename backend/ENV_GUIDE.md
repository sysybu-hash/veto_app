# הדרכת ENV ל-VETO (Render / מקומי) — **בלי Firebase / FCM**

**סדר טעינה בשרת (Node):** `backend/.env` → `backend/.env.local` (אם קיים, דורס).  
**לא** נטען: `.env` או `.env.local` **בשורש** הפרויקט (כאשר `backend/.env` קיים). הערכים ל-API ב־`backend/.env` בלבד.

המקור בקוד: [`.env.example`](.env.example) + `render.yaml` (בשורש הפרויקט) + שימושי `process.env` ב־`src/`.

**לא ממלאים במסלול "בלי Firebase"**

- `FIREBASE_SERVICE_ACCOUNT` — לא (שליחת FCM דרך `firebase-admin` לא מופעלת).
- אין צורך ב־`flutterfire`, `google-services.json` או `GoogleService-Info.plist` **ל־FCM**.

---

## 1) ליבה (MONGO, JWT, שרת)

### `MONGO_URI`

- **מאיפה:** MongoDB Atlas (האפליקציה בנויה על Mongoose + MongoDB, לא Postgres/Neon).
- **לינקים:** [התחלה — Atlas](https://www.mongodb.com/docs/atlas/getting-started/) · [Build a Cluster](https://www.mongodb.com/docs/atlas/tutorial/create-new-cluster/) · [Connect — Drivers — `mongodb+srv://...`](https://www.mongodb.com/docs/atlas/driver-connection/)
- **קצר:** Create Project → Cluster (Free) → Network Access (למשל `0.0.0.0/0` לבדיקות) → Database User → Connect → Drivers → העתק מחרוזת. סיסמאות עם תווים מיוחדים: URL-encode.

### `JWT_SECRET`

- **יצירה (מקומי, בלי commit):**  
  `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`

### `JWT_EXPIRES_IN`

- לרוב `30d` (ברירת מחדל ב־`auth.middleware`).

### `PORT` / `NODE_ENV`

- **מקומי:** `PORT=5001` · `NODE_ENV=development`
- **Render:** `PORT` בדרך כלל אוטומטי; `NODE_ENV=production`

---

## 2) Google OAuth (אם Google Sign-In פעיל)

- `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`
- [Google Cloud — Credentials](https://console.cloud.google.com/apis/credentials) · [OAuth 2.0 client (Web)](https://support.google.com/cloud/answer/6158849?hl=he)

### Google Calendar (סנכרון אירועים — OAuth נפרד)

לא משתמשים ב־`GOOGLE_CLIENT_ID` של Sign-In אלא בלקוח OAuth ייעודי עם scope **Calendar events**.

- `GOOGLE_CALENDAR_CLIENT_ID` / `GOOGLE_CALENDAR_CLIENT_SECRET` — OAuth 2.0 Client (Web או Desktop לפי איך שפותחים את ה־consent).
- `GCAL_OAUTH_REDIRECT_URI` — חייב להתאים בדיוק ל־Authorized redirect URIs ב־GCP, למשל  
  `https://<api-host>/api/integrations/gcal/callback` או מקומית  
  `http://localhost:5001/api/integrations/gcal/callback`.
- אופציונלי: `GCAL_OAUTH_SUCCESS_REDIRECT` — אחרי חיבור מוצלח, הפניה (HTTPS) לדף באפליקציה.
- אופציונלי: `GCAL_TOKEN_ENC_KEY` — מפתח ארוך ל־AES-256-GCM על ה־refresh token; אם חסר, נגזר מ־`JWT_SECRET` (פחות מומלץ בפרוד).
- Worker: `npm run cron:gcal-sync` (Cron / Render Job כל ~5–15 דקות). דורש `MONGO_URI` ואותם סודות OAuth.
- אופציונלי: `GCAL_SYNC_LOOKAHEAD_DAYS` — חלון יבוא עתידי (ברירת מחדל 120).

**מדיניות קונפליקטים (בקוד):** יבוא מעדכן לפי `googleEventId`; אירוע מקור VETO (`syncSource: veto`) לא נדרס מגוגל אם `updatedAt` מקומי חדש מ־`updated` של גוגל. יצוא דוחף אירועים שאין להם מראה בגוגל או ש־`updatedAt > syncedAt`. מחיקה ב־VETO מנסה למחוק גם בגוגל אם היה `googleEventId`.

---

## 3) Gemini (AI + ניתוח כספת)

- `GEMINI_API_KEY` — [Google AI Studio — API key](https://aistudio.google.com/apikey)
- אופציונלי: `GEMINI_MODEL` (למשל `gemini-2.5-flash`)
- אופציונלי: `VAULT_ANALYSIS_MAX_BYTES` (גודל מקסימלי לניתוח קבצים; ברירת מחדל בקוד ~20MB)

### Agora RTC (שיחות)

- `AGORA_APP_ID` — **אותו** App ID כמו ב-Flutter, קבוע `kAgoraAppIdPlaceholder` ב-`frontend/lib/services/agora_service.dart`.
- `AGORA_APP_CERTIFICATE` — מ-Console (Primary certificate). אם ריק, השרת שולח `agoraToken` ריק ו-`agoraUid: 0` (התאמה לפרויקט שמאפשר join רק לפי App ID; אם ב-Agora הופעל **App Certificate** וחובה token — חייבים למלא. הטוקן נבנה ב-`agoraToken.service.js` ב-`session_ready`.

### Agora Cloud Recording + AWS S3 (הקלטה מלאה בדפדפן)

בלי הבלוק הזה, שיחות **web** נשארות עם מיקרופון מקומי בלבד; עם הבלוק — מיקס מלא (אודיו/וידאו) דרך שרת Agora → קובץ ב-S3 → השרת מעלה ל-Cloudinary ותמלול כרגיל.

**מקור בקוד:** `backend/src/services/agoraCloudRecording.service.js` · `call.controller.js` (נתיבי `cloud-recording/*`).

#### א) Agora Console — להפעיל Cloud Recording

1. היכנס ל-[Agora Console](https://console.agora.io/v2) → **Project Management** (ניהול פרויקטים).
2. בחר את **אותו פרויקט** כמו `AGORA_APP_ID` של VETO → אייקון עריכה.
3. מצא **Cloud Recording** → **Enable** → אשר (**Apply**).
4. [מדריך רשמי (Prerequisites)](https://docs.agora.io/en/cloud-recording/get-started/getstarted) — ודא שהשירות מופעל לפני בדיקות.

#### ב) Agora Console — Customer ID + Secret (RESTful — לא App Certificate)

1. ב-Console: **Developer Toolkit** → **RESTful API**.
2. **Add a secret** → **OK** → **Download** את `key_and_secret.txt` (מורידים **פעם אחת** — לשמור במקום בטוח).
3. ממלאים ב-Render / `.env`:
   - `AGORA_RESTFUL_CUSTOMER_ID` = ה-**Customer ID** (המפתח בקובץ).
   - `AGORA_RESTFUL_CUSTOMER_SECRET` = ה-**Customer Secret** (הסוד בקובץ).

[אימות REST (Basic Auth)](https://docs.agora.io/en/cloud-recording/reference/restful-authentication)

#### ג) דומיין REST של Agora

- `AGORA_RESTFUL_DOMAIN` — ברירת מחדל בקוד: `https://api.sd-rtn.com`.
- אם מתקבלות שגיאות רשת/אזור, נסה `https://api.agora.io` (כמו בדוגמאות curl הרשמיות).

#### ד) AWS — Bucket + משתמש IAM

1. [AWS Console](https://console.aws.amazon.com/s3/) → **Create bucket** — בחר **Region** (למשל `us-east-1`). שם bucket גלובלי ייחודי.
2. **IAM** → **Users** → **Create user** — סוג: programmatic access → צור **Access key** (שומרים `Access key ID` + `Secret access key`).
3. **Attach policy** מותאמת (inline או מנוהלת) — לפחות על ה-bucket של VETO:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": [
        "arn:aws:s3:::החלף-בשם-ה-bucket",
        "arn:aws:s3:::החלף-בשם-ה-bucket/*"
      ]
    }
  ]
}
```

- **Agora** משתמשת ב-`accessKey` / `secretKey` שאתה שולח ב-`start` כדי **לכתוב** ל-S3 מהשרתים שלהם.
- **Render (Node)** משתמש באותם מפתחות (דרך `@aws-sdk/client-s3`) כדי **לקרוא** את ה-MP4 ולהעלות ל-Cloudinary — אותו משתמש IAM חייב להרשות גם קריאה.

חסימת גישה ציבורית ל-bucket: אין צורך ב-public read; הגישה היא עם מפתחות.

#### ה) `AGORA_CR_S3_REGION_NUM` — לא אותו מספר כמו ב-AWS!

זהו **קוד אזור של Agora** ל-`vendor=1` (Amazon S3), לא שם ה-region של AWS.

| אזור AWS (דוגמה) | `AGORA_CR_S3_REGION_NUM` |
|------------------|--------------------------|
| us-east-1        | **0**                    |
| us-east-2        | 1                        |
| us-west-2        | 3                        |
| eu-west-1        | 4                        |
| eu-central-1     | 7                        |

טבלה מלאה: [Third-party cloud storage regions (region-vendor)](https://docs.agora.io/en/cloud-recording/reference/region-vendor)

#### ו) משתני סביבה ב-Render (סיכום)

| משתנה | דוגמה / הערה |
|--------|----------------|
| `AGORA_RESTFUL_CUSTOMER_ID` | מ-Console → RESTful API |
| `AGORA_RESTFUL_CUSTOMER_SECRET` | מ-`key_and_secret.txt` |
| `AGORA_RESTFUL_DOMAIN` | אופציונלי; ברירת מחדל `https://api.sd-rtn.com` |
| `AGORA_CR_S3_BUCKET` | שם ה-bucket |
| `AGORA_CR_S3_ACCESS_KEY` | AWS Access Key ID |
| `AGORA_CR_S3_SECRET_KEY` | AWS Secret Access Key |
| `AGORA_CR_S3_REGION_NUM` | מספר מטבלת Agora (למשל `0` ל-`us-east-1`) |
| `AGORA_CR_AWS_REGION` | שם AWS כמו ב-console, למשל `us-east-1` (ל-SDK) |

חובה גם (כבר קיים לשיחות): `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`, Cloudinary, `GEMINI_API_KEY`.

#### ז) איך לוודא שזה עובד

1. אחרי שמירת משתנים ב-Render — **Manual Deploy** (או המתנה ל-deploy) כדי שהסביבה תיטען.
2. מהמחשב (עם JWT או דרך האפליקציה): `GET /api/calls/:eventId/cloud-recording/status` → אמור להחזיר `"configured": true`.
3. שיחת web מלאה → בסיום, בלוגים של השרת לא אמורה להופיע שגיאת `[agora-cloud-recording] finalize failed`; ב-Mongo לאירוע אמור להתעדכן `recording_url`.

#### ח) תקלות נפוצות

- **`503` על start/stop** — חסר אחד מהמשתנים, או `AGORA_CR_S3_REGION_NUM` לא מספר תקין / לא תואם לאזור ה-bucket.
- **`query` 404 אחרי start** — לעיתים token, storageConfig, או Cloud Recording לא הופעל לפרויקט. ראו [Common errors](https://docs.agora.io/en/cloud-recording/reference/common-errors.md).
- **הקלטה לא מגיעה ל-S3** — בדוק IAM (PutObject), `region`/`vendor`, ושה-bucket באותו חשבון AWS כמו המפתחות.

---

## 4) Cloudinary (העלאות / כספה / ראיות)

- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
- [Cloudinary Console](https://cloudinary.com/console) · [מציאת API Key](https://cloudinary.com/documentation/finding_cloud_credentials)

---

## 5) VAPID (Web Push בדפדפן — לא Firebase)

- `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` (מומלץ `mailto:...` אמיתי)
- **יצירה:** `npx web-push generate-vapid-keys` — [web-push CLI](https://github.com/web-push-libs/web-push#command-line)

---

## 6) אופציונלי — יומן, iCal, מייל

- `PUBLIC_API_BASE` או `VETO_PUBLIC_BASE` — **origin** מלא בלי `/api` (למשל `https://your-app.onrender.com`) לבניית `webcalUrl` ב־API היומן.
- **SMTP** (אם רוצה מייל + ICS): `SMTP_HOST`, `SMTP_PORT`, `SMTP_FROM`, ולעיתים `SMTP_USER`, `SMTP_PASS`, `SMTP_SECURE`  
  - [Resend SMTP](https://resend.com/docs/send-with-smtp) · [SendGrid SMTP](https://docs.sendgrid.com/for-developers/sending-email/getting-started-smtp)

### Cron (תזכורות יומן)

- `npm run cron:calendar` (דורש `MONGO_URI` זהה)
- אופציונלי: `CALENDAR_REMINDER_WINDOW_MIN` (בדקות; ראו `scripts/cron-calendar-reminders.js`)
- על Render: בדרך כלל **Cron Job** נפרד או שירות worker שמפעיל את הסקריפט.

---

## 7) אופציונלי — PayPal, Sentry, TURN, Twilio, OTP

- PayPal: [developer.paypal.com](https://developer.paypal.com/)
- Sentry: [sentry.io](https://sentry.io/) — DSN ל־Node
- TURN / ICE: `WEBRTC_ICE_SERVERS_JSON` או `TURN_*` (ראו `call.controller.js`)
- Twilio + `RETURN_OTP_IN_JSON` — ראו `auth.controller.js` (אל תשאיר `RETURN_OTP_IN_JSON` בפרודקשן)

---

## 8) רק NotebookLM Enterprise (GCP) — לא FCM

- `GCP_PROJECT_ID` או `GOOGLE_CLOUD_PROJECT`
- `GOOGLE_NOTEBOOKLM_SA_JSON` — **מחרוזת JSON אחת** (תוכן קובץ service account)  
- [תיעוד המוצר](https://cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs) · [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) → Create key → JSON
- אופציונלי: `NOTEBOOKLM_ENT_URL` (ברירה בקוד: `https://notebooklm.cloud.google.com`)

---

## 9) Render

- [Render Dashboard](https://dashboard.render.com/) → Web Service → **Environment**  
- **Secrets:** `MONGO_URI`, `JWT_SECRET`, `GOOGLE_CLIENT_SECRET`, `GEMINI_API_KEY`, Cloudinary, `VAPID_PRIVATE_KEY`, SMTP password, `GOOGLE_NOTEBOOKLM_SA_JSON` (אם בשימוש).

### Flutter Web (Vercel) + CORS / 404

- אם בדפדפן מופיע `blocked by CORS` או `GET .../health ... 404` / `x-render-routing: no-server` ב־`curl`:
  1. **ודאו** ב־[Render](https://dashboard.render.com) → השירות → **Public URL** (למשל `veto-app-new.onrender.com`). **לא** מניחים ש־`veto-legal` או שם ה־Blueprint = הדומיין — `curl` ל־**ה־URL שמופיע בדשבורד** (`…/health` → 200, `"app":"VETO"`).
  2. `VETO_API_BASE` / [app_config.dart](../frontend/lib/config/app_config.dart) / `package.json` `build:web` — **אותו origin** כמו ב־Dashboard.
  3. אחרי שינוי: `npm run build:web` מהשורש + commit ל־`frontend/build/web` + deploy ב־Vercel.

### URL אחד, שירות אחד (פרודקשן)

- **הדומיין הציבורי** של API מופיע ב־**Render → Web Service** תחת **Settings** (Default **onrender.com** hostname) או **Custom Domains**.  
  ה־`PUBLIC_API_BASE` / `VETO_PUBLIC_BASE` (אם בשימוש), **GitHub Actions** `VETO_API_BASE` (ב־[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) — job `deploy-vercel`), וה־`AppConfig` ב־[app_config.dart](../frontend/lib/config/app_config.dart) חייבים **לאותו origin** כמו **Public URL** ב־Render (למשל `https://veto-app-new.onrender.com` — בלי `/api`). שם השירות ב־Render (למשל `veto_legal`) **לא** תמיד שווה לתת־הדומיין ב־`onrender.com` — תמיד לבדוק ב־Dashboard.
- **ללא שני “Live”** לאותו מוצר: אם יש **שני** Web Services שמייצרים API (למשל שריט ישן + Blueprint מ־`render.yaml`), בחר אחד לפרוד, העתק env, וכבה/מחק את השני — אחרת לקוחות/בניית web עלולה לפנות ל־**URL הלא־נכון**.

---

## 10) Neon

- VETO משתמש ב־**MongoDB (Atlas)**, לא ב־**Neon (Postgres)**. אין מיפוי ישיר ביניהם בלי מיגרציית DB.

---

תבנית שדות מעודכנת: ראו קובץ [`.env.example`](.env.example) ב־`backend/`.
