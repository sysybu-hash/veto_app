# VETO · אפיון פונקציונלי · 2026

> מסמך אפיון לכל 27 המסכים. מבוסס על קריאת `frontend/lib/screens/**/*.dart` ועל המוקאפים ב-`design_mockups/2026/`. כל מסך מתועד ב-7 חתכים: מטרה · משתמש יעד · נתיב · רכיבים · API/Socket · מצבים · ניווט.

**עקרונות מנחים** (תקפים לכל המסכים — לא חוזרים בכל סעיף):
- שפות: he (RTL ברירת מחדל) · en · ru
- נגישות: text-scale 100/115/130%, ניגודיות גבוהה, prefers-reduced-motion, focus rings ברורים
- טיפוגרפיה: כותרות Frank Ruhl Libre · גוף Heebo
- צבעים: Navy 600 ראשי, Coral אדום `#D6243A` ל-SOS בלבד, Gold כאקסנט נדיר
- רספונסיביות: mobile-first, breakpoint דסקטופ ב-1024px

---

## קבוצה A · Auth & Entry (3 מסכים)

### A.01 · Splash Screen
- **מטרה:** מסך פתיחה ראשוני בעת טעינת האפליקציה.
- **משתמש יעד:** כל משתמש (אזרח/עו"ד/אדמין).
- **נתיב:** `/`
- **רכיבים:** קרסט VETO ענק (120px), שם המוצר בסריפי, taglineM 3 נקודות פועמות.
- **API/Socket:** ללא — הזמן הזה משמש לאתחול services + warm-up של ה-backend.
- **מצבים:** **Loading** (היחיד) · timer של 1.8s.
- **ניווט:** `pushReplacementNamed → /landing` בכל מקרה (LandingScreen מזהה auth state).

### A.02 · Landing Screen
- **מטרה:** דף הבית הציבורי, קונברציה למשתמש חדש או כניסה למשתמש קיים.
- **משתמש יעד:** מבקרים אנונימיים + משתמשים מחוברים (זיהוי ב-NavBar).
- **נתיב:** `/landing`
- **רכיבים:**
  - Top-bar: לוגו · ניווט (בית, תכונות, תמחור, איך זה עובד, צור קשר) · בורר שפה · CTA כניסה/הרשמה
  - Hero: eyebrow ("זמין 24/7"), כותרת ענקית בסריפי עם הדגשה Navy + קו זהב, body, 2 CTA (SOS + גלה עוד), proof points (4.9★, 3" ממוצע, +200 עו"ד), ויזואל "מכשיר-בתוך-מכשיר"
  - 3 features: הגנה מיידית · קשר ישיר · פרטיות מלאה
  - 4 stats: 24/7, Real, +3 שפות, Live
  - Stack 1-2-3: זיהוי מצב · שיחה עם AI · חיבור אנושי
  - Pricing: ₪19.90/חודש + 5 bullet points
  - CTA strip כהה (Navy 700→600 + zoom של זהב)
  - Footer: copyright + 4 קישורים
- **API:** ללא (סטטי).
- **מצבים:** **Default** · גרסה למשתמש מחובר (top-bar שונה).
- **ניווט:** CTA SOS → `/login` (אם מחובר → `/veto_screen`) · "לעבור לאשף" → `/login` או `/wizard_home`.

### A.03 · Login Wizard (3 שלבים)
- **מטרה:** הרשמה / כניסה.
- **משתמש יעד:** משתמש חדש או חוזר.
- **נתיב:** `/login`
- **רכיבים:**
  - **Step 1 · Role:** בחירה בין "אזרח" ו"עורך דין". 2 כרטיסים גדולים עם אייקון, כותרת, תיאור, ✓ ב-floating כשנבחר.
  - **Step 2 · Profile:** טופס שם + טלפון, או Google Sign-In. כפתור "שלח קוד".
  - **Step 3 · OTP:** 6 קופסאות ספרתיות, otp-target (טלפון), כפתור אמת + הדבק קוד + Resend (00:54 countdown).
  - Stepper תלת-שלבי גלוי תמיד.
  - בדסקטופ: עמודה כהה עם ערך + ציטוט.
- **API:** `POST /api/auth/sendOtp` · `POST /api/auth/verifyOtp` · Google OAuth.
- **מצבים:** **Loading** · **Error** (12 הודעות שגיאה ב-`_copy.he`) · **Success** (JWT נשמר) · **Resend** (countdown).
- **ניווט:** Success → `/veto_screen` (אזרח) · `/lawyer_dashboard` (עו"ד) · `/admin_settings` (אדמין).

---

## קבוצה B · Citizen Core (2 מסכים)

### B.04 · Citizen Home (VetoScreen)
- **מטרה:** מסך הבית של האזרח — לב המוצר.
- **משתמש יעד:** אזרח מחובר.
- **נתיב:** `/veto_screen`
- **רכיבים (Tab 0 = Wizard):**
  - Top-bar: שפה (שמאל) · קרסט+שם (מרכז) · נגישות + המבורגר (ימין) · LIVE badge בעת dispatch
  - Status pill: "מחובר · ממתין לאירוע" (או "Dispatching")
  - Hero SOS: אורב אדום 200px עם רינגים פועמים, "SOS" + "עזרה מיידית", פסקת חזון לידו, 3 pill-trust (תיעוד / כספת / 24/7)
  - 6 תרחישים: חקירה במשטרה, עצירת תנועה, סכסוך אזרחי, דיני עבודה, דיני משפחה, צרכנות
  - Scenario Detail Panel (פעיל): "מה הכי חשוב לדעת" (4 נקודות) + "פעולה ראשונה" (3 צעדים) + warning callout + 2 CTA
  - 6 זכויות מורחבות: כל זכות עם כותרת בסריפי, פסקת הסבר, callout דוגמה ישימה
- **Tab 1 (Chat):** AI assistant עם הצעות ניסוח · Tab 2 (Files): גישה מהירה לכספת · Tab 3 (Profile): פרופיל
- **Bottom nav:** 4 לשוניות (בית, צ'אט, קבצים, פרופיל)
- **Hamburger menu:** Admin (אם רלוונטי), בית, כספת, יומן, מחברת, מפה, הגדרות, פרופיל, התנתקות
- **API/Socket:** `POST /api/events/dispatch` · `socket: emergencyCreated/lawyerFound/noLawyers/vetoDispatched/vetoError/caseAlreadyTaken/sessionReady`
- **מצבים:** **Standby** · **Dispatching** (loading + LIVE badge) · **Found Lawyer** (push to `/call`) · **No Lawyers** (toast + retry) · **Admin Mode** (מציג adminSection)
- **ניווט:** `/call` (אחרי dispatch) · `/files_vault` · `/legal_calendar` · `/profile` · `/settings` · `/admin_settings` (אם admin) · `/login` (logout).

### B.05 · Wizard Shell (Onboarding)
- **מטרה:** הכרת המוצר ראשונית, איסוף העדפות.
- **משתמש יעד:** משתמש חדש (פעם אחת).
- **נתיב:** `/wizard_home`
- **רכיבים:**
  - רכבת התקדמות כהה משמאל (4 שלבים: תפקיד, תרחיש מרכזי, התראות, פרטיות)
  - תוכן בהיר מימין: שאלה גדולה בסריפי + 6 כרטיסי אופציה
  - שמירה אוטומטית (תווית "נשמר אוטומטית · לפני 4 שניות")
  - Footer: כפתור חזרה + "המשך"
  - Step 4: סיכום checklist ירוק + "סיים והתחל"
- **API:** `POST /api/users/onboarding` (שמירת העדפות)
- **מצבים:** **Step 1-4** · **Saved** · **Submitted** → `/veto_screen`
- **ניווט:** סיום → `/veto_screen` · "שמור וצא" → `/veto_screen`.

---

## קבוצה C · Lawyer Core (2 מסכים)

### C.06 · Lawyer Dashboard
- **מטרה:** מרכז התגובה של עורך הדין.
- **משתמש יעד:** עו"ד מחובר.
- **נתיב:** `/lawyer_dashboard`
- **רכיבים:**
  - Sidebar קבוע (240px בדסקטופ): תיקים (לוח בקרה, תיקים פעילים, שיחות, היסטוריה) · משרד (כספת, יומן, הגדרות) · אווטר עו"ד למטה
  - Top-bar: שלום + שם, **toggle זמינות** (ירוק/אפור), פעמון התראות, CTA "צ'אט פעיל"
  - 4 stat-cards: קריאות ממתינות, יעד תגובה, תיקים פעילים, דירוג
  - רשימת קריאות פעילות:
    - case-card LIVE (אדום, pulse-icon, timer, פרטי משתמש/תרחיש/שפה/ראיות, 3 CTA: קבל תיק קולי / צ'אט תחילה / דלג)
    - case-card ממתין (כתום)
  - Empty state: "אין כרגע קריאות פעילות"
- **API/Socket:** `socket: alert/caseAccepted/caseTaken/sessionReady` · `POST /api/events/:id/accept` · `POST /api/events/:id/reject`
- **מצבים:** **Online + Active** (יש קריאות) · **Online + Empty** · **Offline** · **In Call** (busy)
- **ניווט:** Accept → `/call` · Cards לתיק → `/chat` · sidebar items.

### C.07 · Lawyer Settings
- **מטרה:** הגדרות מקצועיות לעו"ד.
- **משתמש יעד:** עו"ד.
- **נתיב:** `/lawyer_settings`
- **רכיבים (4 כרטיסים):**
  - **תחומי התמחות:** chips (פלילי, תעבורה, אזרחי, עבודה, משפחה, צרכנות, מקרקעין, חוזים, חברות) — עד 3
  - **שעות זמינות:** רשימת ימים (א-ה / ו / שבת) עם שעות + ערוך + מצב כוננות
  - **שפות עבודה:** chips (עברית, אנגלית, רוסית, ערבית) עם רמה
  - **התראות:** Push, SMS גיבוי, שיחת טלפון לחירום
- **API:** `GET/PUT /api/lawyers/me/settings`
- **מצבים:** **Loaded** · **Saving** · **Saved** · **Error**
- **ניווט:** "שמור" → toast → נשאר בעמוד.

---

## קבוצה D · Communication (4 מסכים)

### D.08 · Chat Screen
- **מטרה:** תקשורת טקסט בין משתמשים (אזרח↔עו"ד) ועם AI.
- **משתמש יעד:** אזרח, עו"ד.
- **נתיב:** `/chat`
- **רכיבים:**
  - דסקטופ: sidebar שיחות (חיפוש, list עם unread badges) + thread
  - Mobile: thread בלבד (sidebar ב-back navigation)
  - Header: אווטר + שם + סטטוס "online · מקליד..."  + iconbtns (call, video)
  - בועות: them (לבן), me (Navy 600)
  - **AI cards** מובחנות: gradient כחול בהיר, תיוג "VETO AI · הצעת ניסוח"
  - Composer: attach, voice mic, textarea (גובה דינמי 44→140), כפתור שליחה
- **API/Socket:** `socket: message/typing/read` · `GET /api/chat/:userId`
- **מצבים:** **Loading** · **Active** · **Typing** · **Sending** · **Sent/Read** · **Voice Recording**
- **ניווט:** Header call/video → `/call` עם args.

### D.09 · Call Entry Screen
- **מטרה:** מסך מתווך בין dispatch לבין call (קולי/וידאו/chat-room).
- **משתמש יעד:** אזרח או עו"ד.
- **נתיב:** `/call`
- **רכיבים:**
  - Citizen view: "מחפש עו"ד..." עם 3 dots פועמים, פסקה "3 עורכי דין בקרבת מקום קיבלו את הקריאה", כפתור Cancel אדום
  - Lawyer view: "קריאת חירום נכנסת · LIVE" + פרטי האירוע + 3 כפתורים (דחה אדום / צ'אט / קבל ירוק ענק)
- **Logic:** branches based on `callType` argument: `'chat'` → CallScreen (WebRTC) · אחרת → AgoraCallScreen.
- **מצבים:** **Searching** · **Lawyer Found** · **Cancelled** · **Invalid Args** (→ `/veto_screen`).
- **ניווט:** Accept → CallScreen/AgoraCallScreen (push) · Cancel → `/veto_screen`.

### D.10 · Call Screen (WebRTC voice)
- **מטרה:** שיחה קולית מוצפנת.
- **משתמש יעד:** אזרח↔עו"ד.
- **רכיבים:**
  - רקע כהה (Navy 800/900) — חריג מהפלטה הבהירה
  - badge עליון "שיחה מוצפנת · עו"ד פלילי"
  - שם העו"ד בסריפי + תפקיד + timer (mono)
  - אווטר 140px עם pulse rings
  - Recording pill פועם: "מוקלט · נשמר בכספת המוצפנת שלך"
  - 4 footer-controls: השתק, רמקול, מצלמה (→ video), סיים (אדום ענק)
- **API/Socket:** WebRTC ICE (`webrtc_service.dart`) · recording (`call_recording_service.dart`).
- **מצבים:** **Connecting** · **Active** · **Muted** · **Recording** · **Ended**
- **ניווט:** סיים → `pushReplacementNamed('/veto_screen')` (או `/lawyer_dashboard`).

### D.11 · Agora Call Screen (video)
- **מטרה:** שיחת וידאו מוצפנת דרך Agora RTC.
- **רכיבים:**
  - Full-screen video של העו"ד
  - Self-view (120×160) בפינה הימנית-תחתונה
  - Top overlays עם backdrop-blur: timer + REC pill
  - 4 footer-controls: מיקרופון, מצלמה (טוגל), צ'אט-בצד, סיים
- **API:** `POST /api/calls/token` (Agora token) · `agora_service.dart`
- **מצבים:** **Joining** · **Active (with/without remote video)** · **Camera off** · **Network warning** · **Ended**
- **ניווט:** סיים → אותו כמו Call Screen.

---

## קבוצה E · Vault & Evidence (4 מסכים)

### E.12 · Files Vault
- **מטרה:** כספת אישית מוצפנת לקבצים.
- **נתיב:** `/files_vault`
- **רכיבים:**
  - Top-bar: ניווט + חיפוש + CTA "העלה קובץ"
  - Storage indicator (progress bar 24% של 10GB) עם "AES-256 בכל קובץ"
  - Tabs: הכל / מסמכים / שמע / וידאו / תמונות
  - גריד file-cards: אייקון בצבע לפי סוג (PDF=אדום, אודיו=ירוק, וידאו=סגול, תמונה=כתום), שם, גודל/זמן, badges (חתום, GPS, ראיה, תיעוד שיחה)
- **API:** `GET /api/vault/files` · `POST /api/vault/upload` · `vault_save_queue.dart` (offline queue) · `vault_payload_compress.dart` (gzip)
- **מצבים:** **Loading** · **Empty** · **Loaded** · **Uploading** (progress) · **Decryption error**
- **ניווט:** קובץ → file viewer modal · CTA העלה → file picker.

### E.13 · Shared Vault
- **מטרה:** כספת משותפת בין אזרח לעו"ד לתיק ספציפי.
- **נתיב:** `/shared_vault`
- **רכיבים:**
  - Header: "תיק #4521 · חקירה במשטרה · עו"ד שירה" + badge "מוצפן · 2 צדדים בלבד"
  - 2 טורים: "קבצים שלי" / "קבצים מעו"ד"
  - file-cards אופקיים (40px ico) עם סטטוס נקרא/לא נקרא · "חתום" CTA
  - callout: "נסגרת אוטומטית 30 ימים אחרי סגירת התיק"
- **API:** `GET /api/vault/shared/:caseId` · `POST /api/vault/shared/:caseId/upload`
- **מצבים:** **Loading** · **Active** · **Closed (read-only)** · **Sign required**
- **ניווט:** חזרה → previous · "חתום" → signing flow.

### E.14 · Evidence Camera
- **מטרה:** תיעוד ראיות בזמן אירוע (תמונה / וידאו / קול) עם GPS+timestamp.
- **נתיב:** Push from VetoScreen `_openCamera`
- **רכיבים:**
  - Full-screen camera view
  - Viewfinder עם 4 פינות זהב (B8895C)
  - Top: badge "מתעד · מצב ראייה משפטית" עם נקודה אדומה פועמת
  - GPS label + Timestamp בפינות
  - Bottom controls: 3 mode buttons (צילום/וידאו/קול), shutter ענק לבן (74px)
- **API:** `POST /api/events/:id/evidence` (multipart) · GPS via `geolocator` · Permissions via `permission_handler`.
- **מצבים:** **Initializing camera** · **Ready** · **Recording** · **Uploading** · **Saved**
- **ניווט:** סיים → חזרה ל-VetoScreen.

### E.15 · Maps Screen
- **מטרה:** מפה לאיתור עו"ד (לפני SOS) או אירועים.
- **נתיב:** `/maps`
- **רכיבים:**
  - Search bar + filter chips (פלילי / תעבורה / אזרחי / משפחה / ...)
  - Map (webview_flutter עם Google embed)
  - Pinים: אדום=אירוע, כחול=עו"ד זמין, אפור=לא זמין
  - Bottom card: בחירת עו"ד (אווטר + שם + תחום + מרחק + זמינות + CTA "צור קשר")
- **API:** `GET /api/lawyers/nearby?lat=&lng=&specialty=`
- **מצבים:** **Loading map** · **No results** · **Selected lawyer** · **GPS denied**
- **ניווט:** "צור קשר" → `/chat` או SOS.

---

## קבוצה F · Legal Tools (3 מסכים)

### F.16 · Legal Calendar
- **מטרה:** ניהול אירועים משפטיים.
- **נתיב:** `/legal_calendar`
- **רכיבים:**
  - Top-bar: ניווט + CTA "אירוע חדש"
  - Header: "דצמבר 2025" + arrows + tabs (יום/שבוע/חודש)
  - Cal grid 7×6: ימים בסריפי, אירועים בצבעים (אדום/כחול/זהב/ירוק)
  - Today highlight: עיגול Navy 600
  - Side card: "היום · 4 דצמבר" — אירועים מפורטים עם פס צבע
- **API:** `GET /api/calendar?from=&to=` · `POST /api/calendar/event`
- **מצבים:** **Loading** · **Loaded** · **Empty month** · **Saving event**.

### F.17 · Legal Notebook (Enterprise)
- **מטרה:** תיעוד אישי משפטי בזמן אמת — Markdown editor.
- **נתיב:** `/legal_notebook`
- **רכיבים:**
  - דסקטופ: sidebar רשימת פתקים (כותרת + preview + tm) + editor
  - Mobile: רשימה בלבד, edit במסך מלא
  - Toolbar: H1, B, I, list, checklist, attach, "שתף עם עו"ד" CTA
  - Editor: כותרת בסריפי 32px, meta (נוצר/עודכן/תגיות), תוכן בסריפי 16px / 1.85 line-height
  - תמיכה ב-blockquote (border Navy + רקע info), code (paper-2 background)
- **API:** `GET/POST/PUT /api/notebook/:noteId` · auto-save על debounce 800ms
- **מצבים:** **Loading** · **Editing** · **Saved** · **Sharing**.

### F.18 · Legal Document (Privacy / Terms)
- **מטרה:** תצוגת מסמכים משפטיים: פרטיות, תנאי שימוש.
- **נתיב:** `/privacy` · `/terms`
- **רכיבים:**
  - Top-bar: חזרה + tabs (פרטיות / תנאי שימוש)
  - Page: 780px רוחב, 60px padding, רקע נייר עדין
  - כותרת H1 בסריפי 32px במרכז + meta line + ירידות שורה רחבות (1.85)
  - תוכן: H2 כסעיפים, ul/ol עם spacing נדיב
  - אייקונים top-bar: שיתוף, סימון נקרא
- **API:** `GET /api/legal/privacy` · `GET /api/legal/terms` (sourced from CMS).
- **מצבים:** **Loading** · **Loaded** · **Print mode**.

---

## קבוצה G · Settings & Profile (2 מסכים)

### G.19 · Profile Screen
- **מטרה:** תצוגה וניהול פרטי חשבון.
- **נתיב:** `/profile`
- **רכיבים:**
  - Profile hero: אווטר 96px, שם בסריפי 28px, פרטי קשר, badges (פרימיום, חבר מאז, מאומת)
  - "סטטוס מנוי · פעיל עד" + CTA "חידוש"
  - 4 stats: תיקים פעילים, קבצים, ייעוצי AI, שיחות
  - Personal info: שם / טלפון / אימייל (row-items עם chevron)
- **API:** `GET /api/users/me` · `PATCH /api/users/me` · `GET /api/payments/subscription`
- **מצבים:** **Loaded** · **Editing** · **Saving**.

### G.20 · Settings Screen
- **מטרה:** הגדרות אישיות ומערכת.
- **נתיב:** `/settings`
- **רכיבים:**
  - Sidebar: חשבון (פרופיל, אבטחה, פרטיות) · העדפות (שפה, נגישות, התראות) · מנוי (תשלום, חשבוניות)
  - Sections (גוש מאוחד של row-items):
    - **שפה ואזור:** שפת ממשק, פורמט תאריך
    - **נגישות:** גודל טקסט (A/A+/A++), ניגודיות גבוהה (toggle), האטת אנימציות (toggle)
    - **התראות:** Push, SMS גיבוי, סיכום שבועי באימייל
    - **אבטחה:** הצפנת מכשיר (PIN/Biometric — badge פעיל), 2FA (toggle), התנתקות מכל המכשירים (אדום)
  - **אזור מסוכן** (border אדום): מחיקת חשבון, ייצוא וצא
- **API:** `GET/PATCH /api/users/me/preferences` · `POST /api/auth/logout-all`
- **מצבים:** **Loaded** · **Saving** · **Saved** (toast) · **Logout confirmation modal**.

---

## קבוצה H · Admin Console (7 מסכים)

> כל מסכי האדמין משתמשים במבנה משותף: **sidebar** קבוע + **top-bar** עם Production/Staging selector + **content area**. מובייל לא נתמך לאדמין (desktop-only).

### H.21 · Admin Dashboard
- **נתיב:** `/admin_dashboard`
- **רכיבים:**
  - Sidebar: סקירה (דשבורד, Logs) · משתמשים (כל המשתמשים, כל עו"ד, ממתינים) · מסחר (מנויים) · מערכת (הגדרות) · counts ליד כל פריט
  - Top-bar: עמוד פעיל + badge "3 התראות חיות" + Production selector + פעמון + הגדרות
  - 4 stat-cards: משתמשים פעילים, עו"ד רשומים, קריאות חירום היום, MRR (₪46.5K)
  - Chart 14 ימים (CSS bars — בקוד יוחלף ל-fl_chart)
  - "פעילות אחרונה" עם log-rows חיים
- **API:** `GET /api/admin/stats` · `socket: adminActivity`.

### H.22 · All Users
- **נתיב:** `/admin_users`
- **רכיבים:** filter-bar (search + סטטוס + מנוי) + table (שם, טלפון, הצטרף, סטטוס, מנוי, פעילות, actions menu) + pagination + "ייצא ל-CSV"
- **API:** `GET /api/admin/users?q=&status=&plan=&page=`.

### H.23 · All Lawyers
- **נתיב:** `/admin_lawyers`
- **רכיבים:** דומה ל-Users אבל עם עמודות: שם, תחום, זמין, תיקים השנה, דירוג + CTA "+ הוסף עו"ד"
- **API:** `GET /api/admin/lawyers`.

### H.24 · Pending Lawyers
- **נתיב:** `/admin_pending`
- **רכיבים:** רשימת בקשות. כל בקשה כרטיס: אווטר 64px, שם בסריפי 18px, פרטי רישיון/תחום/זמן הרשמה, badges מסמכים מצורפים (תעודת עו"ד, ת"ז), 3 CTA: פרטים / אשר (ירוק) / דחה (אדום). אם חסר מסמך → CTA disabled.
- **API:** `GET /api/admin/lawyers/pending` · `POST /api/admin/lawyers/:id/approve|reject`.

### H.25 · Emergency Logs
- **נתיב:** `/admin_logs`
- **רכיבים:**
  - Filter: היום / השבוע / חיפוש
  - Stream של log-rows: badge (CRITICAL/WARN/OK/ERROR) + תיאור + meta + timestamp (mono)
- **API:** `GET /api/admin/logs?level=&from=&to=` · live updates via socket.

### H.26 · Subscription Admin
- **נתיב:** `/admin_subscriptions`
- **רכיבים:** 3 stat cards (פעילים, חידוש %, ARPU) + רשימת תוכניות פעילות (פרימיום חודשי/שנתי/חינם) + "+ תוכנית חדשה"
- **API:** `GET /api/admin/subscriptions/stats` · `GET /api/admin/subscriptions/plans`.

### H.27 · Admin Settings (System)
- **נתיב:** `/admin_settings`
- **רכיבים (3 כרטיסים):**
  - **דיספאצ'ינג:** Timeout עו"ד (30s), רדיוס חיפוש (25 ק"מ), max עו"ד לקריאה (5)
  - **תקשורת:** Twilio SMS, Agora RTC, Firebase Push, Gemini AI — badges פעיל/לא פעיל
  - **תחזוקה (full-width):** מצב תחזוקה (toggle), איפוס cache (red button)
- **API:** `GET/PUT /api/admin/system/config`.

---

## גלריית מצבים משותפים

לכל מסך מוגדרים מצבים סטנדרטיים:

| מצב | טריגר | UI |
|------|-------|-----|
| **Loading** | API call | spinner מרכזי + "טוען..." |
| **Empty** | תוצאה ריקה | empty state עם icon + title + body + CTA |
| **Error** | API failure | callout danger + retry button |
| **Offline** | אין רשת | banner עליון + queue mode |
| **Success** | פעולה הצליחה | toast/snackbar בתחתית |
| **Confirming** | פעולה הרסנית | dialog עם 2 כפתורים |

---

## אינטגרציות חיצוניות (תקפות לכל הרלוונטיים)

| שירות | תפקיד | מסכים |
|--------|--------|--------|
| **Twilio** | SMS OTP | Login |
| **Google Identity** | Sign-In | Login |
| **Firebase FCM** | Push Notifications | כל מקום |
| **Agora RTC** | Video calls | Agora Call Screen |
| **WebRTC** | Voice calls + chat-room | Call Screen |
| **Google Maps** | מפה (webview embed) | Maps Screen |
| **Gemini AI** | AI assistant + ניסוחים | Chat, Citizen scenarios |
| **PayPal/Apple/Google Pay** | תשלום | Profile, Settings, Subscription Admin |
| **Cloudinary** | אחסון מדיה | Vault upload |
