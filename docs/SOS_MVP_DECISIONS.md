# החלטות MVP — SOS, תמלול וכספת

## נכנס ל-MVP (ביישום הנוכחי)
- בחירת התמחות אזרח לפני `start_veto`.
- שליחת `specialization` לבק-אנד בפורמט נתמך.
- בחירת סוג שיחה (`video` / `audio` / `chat`) לפני `session_ready`.
- תאימות ניתוב ב־`/settings` למסך מונוליתי לוגי עם `?tab=...`.

## נדחה לשלב הבא (סגור כהחלטת מוצר — 2026-08-04)
- **צ׳אט במקביל לשיחת וידאו (דו-ערוצי מלא)** — נשאר מחוץ ל-MVP; SidePanel ב-CallShell מספיק לטקסט בזמן שיחה. לא ליישם ערוץ נפרד עד אחרי יציבות hangup/summary.
- ניהול הרשאות granular לקובצי תמלול/הקלטה לכל עו״ד.
- ייצוא מובנה ל־PDF/הדפסה מתוך UI.
- קישור אוטומטי דו-כיווני בין כל אירוע SOS לפריטי כספת ברמת UI מלאה.

## הערות אימות
- מודל `EmergencyEvent` כבר כולל שדות לתמלול/הקלטה (`recording_url`, `call_transcript`, `transcript_language`).
- בקרת הרשאות owner/lawyer נשארת תלויה בבקרי הקריאה/כתיבה ב־`call.controller.js`.

## ארכיטקטורת SOS — שתי מערכות, לא כפילות (הובהר 2026-07)
קיימות שתי רשומות SOS במקביל, בכוונה — לא באג ולא כפילות:

1. **`EmergencyEvent` (MongoDB, `backend/src/models/EmergencyEvent.js`)** — הרשומה הקנונית: נוצרת ב-`event.controller.js` (`EmergencyEvent.create(...)`), מכילה חיוב, שיוך עו״ד, כספת, תמלול/הקלטה, וכל לוגיקת ה-dispatch (`backend/src/socket/dispatch.socket.js`). זהו ה-source of truth.
2. **`SosEvent` (Postgres/Neon דרך Prisma, `web-client/prisma/schema.prisma`)** — שכבת התראה בזמן אמת בלבד (תור למסך עו״ד/לוח בקרה), מתפרסמת דרך Ably (`web-client/src/app/actions/sos.ts`). ה-`eventId` שלה **חייב להיות זהה** ל-`EmergencyEvent._id` מ-Mongo (ר' תיעוד `TriggerSosOptions.eventId` בקוד) — זו לא רשומה עצמאית אלא אינדקס-שכפול לצורך push מהיר ללקוח דרך Ably, כי ה-backend הראשי לא חשוף ל-Ably.

**מסקנה תפעולית**: אם Ably נופל, ה-`SosEvent` (השכבה המשנית) לא מתפרסם בזמן אמת — אך ה-`EmergencyEvent` הקנוני עדיין נוצר בבקאנד דרך `dispatch.socket.js` (Socket.io), כך שהאירוע עצמו לא אבד. התיקון ב-P0-6 (`sos.ts`) מוודא שגם רשומת ה-Postgres המשנית לא נמחקת בכשל Ably (מסומנת `PENDING_DELIVERY` + Sentry alert), כדי שאפשר יהיה לפייל matched/reconcile מול ה-Mongo event ידנית אם צריך.
