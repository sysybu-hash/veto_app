# VETO — מקור אמת לדומיינים (RFC קצר)

מסמך זה נועד לנעול **מקור אמת יחיד** לכל דומיין מרכזי בין Backend (Node+Mongo), Web (Next+Prisma/Neon) ולקוחות — ולמנוע דריפט.

## Billing / מנויים

| שדה / מצב | מקור אמת | הערות |
|------------|-----------|--------|
| `is_subscribed`, `subscription_expiry` | **MongoDB `User`** | מתעדכן אחרי `POST /api/payments/capture` (מנוי בלבד), לאחר אימות JWT |
| פטור מתשלום | **MongoDB `User`** + לוגיקה ב־`verify-otp` → `is_payment_exempt` (מנהל / עו״ד / `manually_added`) | ה־Web משתמש בערך מהפרופיל / תגובת התחברות |
| יצירת הזמנת PayPal | **`payment.controller` + PayPal API** | return/cancel URLs לפי `WEB_APP_URL` (או `FRONTEND_URL`) |
| סטטוס תשלום לפני capture | **PayPal order** | הלקוח מחזיר `token` (מזהה order) לדף `/payments/return` |

## SOS / חירום

| ישות | מקור אמת | הערות |
|------|-----------|--------|
| מצב האירוע, עורך דין משויך, `room_id`, `call_type` | **MongoDB `EmergencyEvent`** | נוצר ב־`start_veto`; `accept_case` / `citizen_chose_session` מעדכנים כאן |
| מזהה ציבורי של אירוע SOS על ה-wire | **`EmergencyEvent._id` (מחרוזת)** | אותו מזהה חייב לשמש ב־Socket.io, ב־Prisma `SosEvent.eventId`, ובכל רכישת אירוע |
| תור Ably + שורת `SosEvent` (Prisma) | **משני / מסונכרן** | נוצר אחרי `emergency_created` מהשרת עם `eventId` ממונגו; לא ליצור UUID נפרד בצד לקוח |
| קבלת תיק (לעו״ד) | **`accept_case` (Socket)** | אטומי במונגו; לאחר מכן מסונכרן ל־Prisma + Ably דרך `claimSosEvent` |

## Vault / כספת (Prisma)

| נתון | מקור אמת | הערות |
|------|-----------|--------|
| רשומות `Evidence` | **PostgreSQL (Prisma)** | בעלות לפי `ownerId` ↔ משתמש עם `externalId` = Mongo user id |
| הקלטה / תמלול שיחת חירום | **MongoDB `EmergencyEvent`** (`recording_url`, `call_transcript`, …) | מסונכרן לכספת כ·**Evidence** עם `sourceEmergencyEventId` למניעת כפילויות |
| ACL קריאה/מחיקה בכספת | **בעלות Prisma** | מחיקה לטובת הבעלים בלבד (שכבת עו״ד משותפת — הרחבה עתידית) |

**פער ידוע (זוהה 2026-07):** `deleteEvidence` (`web-client/src/app/actions/vault.ts`) מוחק קובץ מרוחק (Cloudinary/legacy storage) דרך `LEGACY_API_URL`/`LEGACY_API_TOKEN`. אם המשתנים לא מוגדרים, **רק שורת ה-Postgres נמחקת** — הקובץ עצמו נשאר יתום באחסון בלי שום עקבה. נוסף לוג אזהרה (`console.warn`) בקוד; יש להחליט: (א) לוודא `LEGACY_API_URL` מוגדר תמיד בפרוד, או (ב) להחליף למנגנון מחיקה ישיר מול Cloudinary API (ללא תלות בשירות legacy) — ר' `backend/ENV_GUIDE.md`.

## הצטרפות / Onboarding

| שדה | מקור אמת | הערות |
|-----|-----------|--------|
| `onboarding_completed` | **MongoDB `User`** | נשמר ב־`PUT /api/users/me`; אחרי התחברות ראשונה (אזרח) מפנים ל־`/onboarding` אם `false` |

## חוזי API חשופים ל־Web

- `GET/PUT /api/users/me` — פרופיל, הגדרות, מנוי, `onboarding_completed`, `is_payment_exempt` (כשמוחזר מהשרת).
- `POST /api/payments/subscription` | `POST /api/payments/capture` (עם JWT) | דף `/payments/return`.

---
*עודכן כחלק מתוכנית המנויים וההצטרפות — שינוי מקור האמת דורש עדכון מסמך זה.*
