# בדיקות קבלה (E2E) — VETO Web

מסמך זה משלים את תוכנית המוצר: זרימות שיש **לאמת ידנית** (או עם כלי E2E חיצוני) לפני שחרור.

## סביבה

- **Backend**: `PORT=5001`, MongoDB זמין, משתני PayPal מוגדרים לפי `payment.controller`.
- **Web**: `web-client` עם `NEXT_PUBLIC_API_URL` (או מקביל) מצביע על אותו API.
- **Prisma**: לאחר שינוי סכימה (`Evidence.sourceEmergencyEventId`) — `prisma db push` או מיגרציה against Neon.

## רשימת בדיקות

### 1. הצטרפות → OTP → Onboarding → Hub

1. `/register` — יצירת חשבון אזרח (טלפון + פרטים לפי הטופס).
2. קבלת OTP (ב־dev: לוג backend).
3. `/login` — אימות OTP.
4. אם `onboarding_completed` חסר — הפניה ל־`/onboarding`; השלם ושמור.
5. וודא גישה ל־`/hub` ללא לולאת הפניות.

### 2. Billing (PayPal)

1. משתמש אזרח **לא** פטור מתשלום — `/settings?tab=billing` (או `/settings/billing`).
2. יצירת הזמנה → מעבר ל־PayPal (sandbox) → אישור.
3. חזרה ל־`/payments/return?token=…` — capture מצליח.
4. רענון מסך Billing — `is_subscribed` / תאריך תואמים ל־`GET /api/users/me`.
5. וודא שלא ניתן ל־capture עם JWT של משתמש אחר (בדיקת אבטחה).

### 3. SOS — אירוע אחד ותור

1. מה־Hub — בחר התמחות תקפה ו־`callType` (וידאו/קול/צ׳אט).
2. אחרי `emergency_created` — אותו `eventId` (Mongo) בשימוש ב־Ably/Prisma (`triggerSosAlert`).
3. כעורך דין — תור מציג את האירוע; `accept_case` (socket) ואז claim — ללא כפילויות/אירוע יתום.

### 4. כספת — תוצרי SOS

1. לאחר שיחה עם הקלטה/תמלול (כשקיים ב־`EmergencyEvent`), משתמש אזרח:
   - `/vault` — «סנכרן מ־SOS» או סנכרון אוטומטי בטעינה.
2. רשומות `Evidence` עם אותו `sourceEmergencyEventId` לא משוכפלות.
3. מחיקה/צפייה — לפי בעלות (owner); עו״ד משויך — הרחבה עתידית לפי RFC.

### 5. הגדרות — נתיבים

1. `/settings/profile`, `?tab=notifications`, `?tab=security`, `?tab=billing`.
2. `/settings/notifications`, `/settings/security`, `/settings/billing` — מפנים לטאב המתאים ב־`SettingsShell`.
3. שמירה גלובלית רק היכן רלוונטי (פרופיל/התראות).

## הערות CI

- `npm run lint` ב־`web-client` עלול להיכשל בגלל כללי `react-hooks/set-state-in-effect` בקבצים שלא חלק מהשינוי האחרון; לתקן בהדרגה או להתאים את הכלל.
