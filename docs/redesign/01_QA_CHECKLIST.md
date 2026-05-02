# VETO · QA Checklist · 2026

> רשימת בדיקות מקיפה לכל 27 המסכים. לכל מסך 8-15 פריטים: golden path, edge cases, RTL, i18n, נגישות, responsiveness, error states.
> **שיטת בדיקה:** ✅ עבר · ❌ נכשל · ⏸ לא רלוונטי. הריצו לפני כל release.

---

## בדיקות אופקיות (חלות על כל מסך)

| # | בדיקה |
|---|--------|
| H1 | המסך נטען ב-<2 שניות בחיבור 4G |
| H2 | RTL מלא בעברית — אין טקסט גלוש שמאלה, אייקונים מיושרים |
| H3 | LTR מלא באנגלית — מתחלף ב-AppLanguage תקין |
| H4 | תרגום מלא ל-3 שפות (he/en/ru) — אין מפתחות מודלקים |
| H5 | נגישות: Tab navigation עובר על כל הרכיבים האינטראקטיביים |
| H6 | נגישות: text-scale 130% לא שובר את הלייאוט |
| H7 | נגישות: ניגודיות ≥ 4.5:1 לכל הטקסטים (WCAG AA) |
| H8 | prefers-reduced-motion מבטל את כל האנימציות |
| H9 | Focus rings ברורים על כל focusable element |
| H10 | Mobile (≤640px) ו-Desktop (≥1024px) שניהם תקינים |
| H11 | Tablet breakpoint (640-1024px) — לפחות לא שבור |
| H12 | Dark mode (אם נשמר) — קונטרסט תקין |
| H13 | Browser back/forward עובד נכון |
| H14 | Deep link מהקליפבורד (URL ישיר) טוען את המסך |
| H15 | Offline state — הודעה ברורה + queue אם רלוונטי |

---

## A. Auth & Entry

### A.01 · Splash Screen
- [ ] מופיע מיד עם פתיחת האפליקציה (ללא flash שחור)
- [ ] אנימציה: fade+scale חלקה על הקרסט
- [ ] 3 נקודות פועמות (אינדיקציה שמשהו קורה)
- [ ] timer של ~1.8s — לא קצר מדי, לא ארוך מדי
- [ ] מעבר אוטומטי ל-/landing
- [ ] אין button שאפשר ללחוץ עליו (מסך הכרזה בלבד)
- [ ] tagline בכל אחת מ-3 השפות
- [ ] dispose נקי (אין memory leak של Timer)

### A.02 · Landing Screen
- [ ] Hero CTA "לחץ SOS" → `/login` (אם לא מחובר)
- [ ] Hero CTA SOS → `/veto_screen` (אם מחובר כאזרח)
- [ ] Hero CTA SOS → `/lawyer_dashboard` (אם מחובר כעו"ד)
- [ ] Top-bar ניווט פעיל (anchor scrolling — תכונות, תמחור)
- [ ] בורר שפה משנה את כל הדף
- [ ] 3 features cards מוצגות באותו גובה (grid alignment)
- [ ] Stats grid 4 תאים בדסקטופ, 2×2 במובייל
- [ ] Pricing CTA → `/login` (signup mode)
- [ ] Footer קישורים → `/privacy`, `/terms`
- [ ] Hero "מכשיר-בתוך-מכשיר" SOS אנימציה רצה (rings)
- [ ] CTA strip תחתון עם רקע כהה — קונטרסט תקין

### A.03 · Login Wizard
- [ ] **Step 1**: בחירת תפקיד מסומנת ויזואלית (✓ floating)
- [ ] **Step 1**: לחיצה על "המשך" בלי בחירה — error toast
- [ ] **Step 2**: ולידציית טלפון (8-10 ספרות, ישראלי)
- [ ] **Step 2**: שם חובה — error אם ריק
- [ ] **Step 2**: Google Sign-In פותח popup — חוזר עם success/cancel
- [ ] **Step 3**: 6 קופסאות OTP — auto-focus ל-next, paste מכל מקום
- [ ] **Step 3**: countdown "Resend (00:54)" עובד, ב-00:00 נפתח לחיצה
- [ ] **Step 3**: error handling — 7 הודעות שונות (otpInvalid, otpRateLimited, etc.)
- [ ] Stepper מציג 1/2/3 עם ✓ לשלבים שהושלמו
- [ ] חזרה (←) שומר את הנתונים שהוזנו
- [ ] Success → ניווט נכון לפי תפקיד (citizen/lawyer/admin)
- [ ] OTP rate limit (10 דקות) — UI מוצג במלואו
- [ ] בעיה ברשת — banner offline + retry

---

## B. Citizen Core

### B.04 · Citizen Home (VetoScreen)
- [ ] Status pill מציג סטטוס נכון (Connected/Dispatching/LIVE)
- [ ] **SOS לחיצה ראשונה** מפעילה dispatch (loading + LIVE badge)
- [ ] **SOS לחיצה שניה במהלך dispatch** — מנוטרלת
- [ ] Socket `emergencyCreated` → `_activeEventId` נשמר
- [ ] Socket `lawyerFound` → push ל-`/call`
- [ ] Socket `noLawyers` → toast + reset state
- [ ] Socket `caseAlreadyTaken` → notification
- [ ] בחירת תרחיש → רשימת זכויות מתעדכנת
- [ ] תרחיש פעיל מציג scenario-detail panel
- [ ] "הזעק עו"ד פלילי עכשיו" → אותו flow כמו SOS
- [ ] **Tab Chat (1)**: AI conversation עם history
- [ ] **Tab Files (2)**: גישה מהירה לכספת
- [ ] **Tab Profile (3)**: פרופיל
- [ ] Hamburger menu: 9 פריטים (אדמין מותנה ב-role)
- [ ] LIVE voice (Gemini Live) — מיקרופון מאקסס תקין
- [ ] STT result handler (Web bridge) פועל
- [ ] שינוי שפה משנה את כל הטקסט (כולל תרחישים, זכויות, hint mic)
- [ ] Background painter (RepaintBoundary) לא גורם לrebuild ב-tab change

### B.05 · Wizard Shell
- [ ] רכבת ההתקדמות מתעדכנת בכל שלב
- [ ] שמירה אוטומטית אחרי שינוי — toast "נשמר"
- [ ] "שמור וצא" → `/veto_screen` עם השינויים שמורים
- [ ] חזרה לשלב קודם — הנתונים נטענים
- [ ] Step 4 (סיכום) מציג את כל הבחירות נכון
- [ ] "סיים והתחל" → POST onboarding API + נווט
- [ ] Mobile: stepper הופך לדוטים בלבד
- [ ] Validation: לא ניתן להתקדם בלי בחירה

---

## C. Lawyer Core

### C.06 · Lawyer Dashboard
- [ ] **Toggle זמינות** ירוק=זמין/אפור=לא זמין — switch UI נכון
- [ ] Toggle off → POST availability=false → אין יותר alerts
- [ ] Stats cards מתעדכנים בזמן אמת
- [ ] Socket `alert` → case-card חדש מופיע עם pulse
- [ ] **Accept** → POST `/api/events/:id/accept` → push ל-`/call`
- [ ] **Reject** → POST `/api/events/:id/reject` → הקריאה נעלמת מהרשימה
- [ ] **Case taken by other** (`caseTakenSub`) → הקריאה נעלמת
- [ ] Timer של LIVE case רץ נכון (mm:ss)
- [ ] Empty state כשאין קריאות + יש זמינות = מציג "אין כעת קריאות פעילות"
- [ ] Empty state כשאין קריאות + אין זמינות = מציג CTA "הפעל זמינות"
- [ ] Sidebar navigation תקין
- [ ] התראות Push בולטות גם כשהאפליקציה ברקע
- [ ] Mobile: sidebar הופך ל-hamburger

### C.07 · Lawyer Settings
- [ ] בחירת עד 3 תחומי התמחות — chip 4 → toast "מקסימום 3"
- [ ] שעות זמינות: ניתן לערוך כל יום בנפרד
- [ ] שבת = "לא זמין" (default)
- [ ] מצב כוננות = פעיל אפילו בשעות לא-זמין (callout warning)
- [ ] שפות עבודה: לפחות שפה אחת חובה
- [ ] התראות: כל 3 הסוגים ניתן להפעיל/כבות עצמאית
- [ ] "שמור שינויים" → PUT API → toast success
- [ ] שינוי לא נשמר → confirmation dialog על exit

---

## D. Communication

### D.08 · Chat Screen
- [ ] **Send message** → מופיע מיד בבועה me (optimistic)
- [ ] **Send failed** → אינדיקציית error + retry
- [ ] **Receive message** → socket `message` → bubble them
- [ ] **Typing indicator** → "מקליד..." מופיע בהדר
- [ ] **Read receipts** → ✓✓ כחולים
- [ ] **AI card** מובחן ויזואלית מבועות עו"ד
- [ ] Composer textarea גובה דינמי (44 → 140)
- [ ] Voice mic מתחיל הקלטה — UI אדום
- [ ] Attach → file picker + העלאה לכספת
- [ ] Empty state אם אין שיחות
- [ ] Sidebar (desktop) — חיפוש מסנן בזמן אמת
- [ ] Unread badges עדכניים
- [ ] Day separators בכרונולוגיה ("היום", "אתמול", date)
- [ ] שמירת history אחרי refresh (קריאת `/api/chat/:userId`)
- [ ] Long press על bubble → copy / forward / delete

### D.09 · Call Entry Screen
- [ ] callType missing → push ל-`/veto_screen` (fallback)
- [ ] callType='chat' → render CallScreen
- [ ] callType='audio'/'video' → render AgoraCallScreen
- [ ] Searching state: 3 dots + "3 עורכי דין קיבלו..."
- [ ] Cancel button (אזרח) → cleanup + חזרה ל-veto_screen
- [ ] Lawyer side: 3 כפתורים ענקיים (דחה/צ'אט/קבל)
- [ ] קבל מתחבר תוך 3 שניות

### D.10 · Call Screen (Voice)
- [ ] Recording indicator פועם בלי ירידת FPS
- [ ] Timer רץ (mm:ss) משניית החיבור
- [ ] Mute toggle: UI מתעדכן + audio stream ב-mute
- [ ] Speaker toggle: עובר ל-loudspeaker / ear
- [ ] Camera toggle: עובר ל-Agora video flow
- [ ] End call → confirmation → `pushReplacementNamed('/veto_screen')`
- [ ] Network drop: auto-reconnect 3 attempts + UI banner
- [ ] In-call STT (אם פעיל): טקסט מופיע בכספת אחרי שיחה
- [ ] Background mode (אפליקציה לא בפוקוס): השיחה ממשיכה

### D.11 · Agora Call Screen
- [ ] טוקן Agora תקף — חידוש אוטומטי
- [ ] Self-view בפינה — לא חוסם controls
- [ ] Camera flip (front/back במובייל)
- [ ] Network warning (איכות נמוכה) → toast
- [ ] Remote camera off → placeholder עם אווטר
- [ ] End call → אותו flow כמו voice
- [ ] תמיכה ב-orientation change (landscape בטאבלט)

---

## E. Vault & Evidence

### E.12 · Files Vault
- [ ] Storage indicator מציג נכון GB מנוצל מתוך מנוי
- [ ] Tab filter (הכל/מסמכים/שמע/וידאו/תמונות) עובד
- [ ] חיפוש בשם קובץ — תוצאות בזמן אמת
- [ ] Upload progress visible (multi-file)
- [ ] Upload נכשל → retry queue (vault_save_queue.dart)
- [ ] Compression (gzip) פועלת לקבצים גדולים
- [ ] Click על file → preview modal (image / pdf / audio player / video player)
- [ ] Long press → menu (rename / delete / share with lawyer)
- [ ] Empty state עם CTA "העלה קובץ"
- [ ] Decryption error → "Failed to decrypt — נסה שוב"
- [ ] Mobile: גריד 2 עמודות במקום 3-4

### E.13 · Shared Vault
- [ ] טעינה לפי `caseId` נכון
- [ ] שני הצדדים רואים את אותם קבצים
- [ ] סטטוס "נקרא ע"י עו"ד" מתעדכן
- [ ] חתימה על מסמך → דורש אימות (PIN/Biometric) → status="חתום"
- [ ] תיק סגור → read-only mode (אין העלאה)
- [ ] סוגר אוטומטית 30 יום אחרי סגירה — קבצים מועברים ל-personal vault

### E.14 · Evidence Camera
- [ ] **הרשאות**: Camera + Mic + Location מבוקשות בכניסה
- [ ] שלילת הרשאה → מסך הסבר עם CTA "פתח הגדרות"
- [ ] GPS lock לפני צילום (לא תוצג GPS אם no fix)
- [ ] Timestamp רץ בזמן אמת
- [ ] Mode toggle: צילום/וידאו/קול
- [ ] Shutter: צילום → compress → upload
- [ ] Recording video: timer + red dot
- [ ] Recording audio: waveform animation
- [ ] Network failure → save locally + retry queue
- [ ] תיוג "מצב ראייה משפטית" + GPS+timestamp נשרפים על המדיה (watermark)

### E.15 · Maps Screen
- [ ] WebView Google Maps נטען (mobile/desktop)
- [ ] Pinים נכונים: אדום=אירוע, כחול=זמין, אפור=לא זמין
- [ ] לחיצה על pin → bottom card עם פרטי עו"ד
- [ ] חיפוש כתובת → map פינים מתעדכנים
- [ ] Filter chips (תחום) → סינון מיידי
- [ ] GPS denied → banner + CTA "אפשר מיקום"
- [ ] "צור קשר" → `/chat` עם lawyerId
- [ ] Zoom level שומר על pinים גלויים

---

## F. Legal Tools

### F.16 · Legal Calendar
- [ ] חודש נוכחי = default
- [ ] arrows קודם/הבא משנים את החודש
- [ ] tabs (יום/שבוע/חודש) — חודש הוא default
- [ ] today highlight — Navy circle נכון
- [ ] event color-coded (אדום/כחול/זהב/ירוק)
- [ ] לחיצה על תא → modal "אירועים ביום X"
- [ ] CTA "+ אירוע חדש" → form modal
- [ ] Side card "היום" מציג רק events של today
- [ ] Empty month — מסך מוצג בלי שגיאה
- [ ] Mobile: weekly view במקום monthly

### F.17 · Legal Notebook
- [ ] רשימת פתקים נטענת ממוינת לפי updated DESC
- [ ] בחירת פתק → editor מתמלא
- [ ] עריכה → auto-save על debounce 800ms → "נשמר" badge
- [ ] toolbar: B/I/H1/list/checklist/attach פועלים
- [ ] paste image → upload לכספת + תצוגה inline
- [ ] "שתף עם עו"ד" → modal בחירת עו"ד מהשיחות
- [ ] "+" → פתק חדש ריק עם title default
- [ ] Long press בפתק → delete confirmation
- [ ] Search bar (אם קיים) — full-text search
- [ ] Mobile: רשימה במסך אחד, edit במסך מלא

### F.18 · Legal Document
- [ ] Tabs פרטיות / תנאי שימוש מתחלפים
- [ ] תוכן נטען מ-API (לא hardcoded)
- [ ] Print mode (אם זמין) — preview מודפס
- [ ] שיתוף (icon top-bar) → share sheet
- [ ] גלילה חלקה גם בטקסט ארוך
- [ ] Anchor links (#section1) עובדים
- [ ] Mobile: padding 24px במקום 60px

---

## G. Settings & Profile

### G.19 · Profile
- [ ] Hero מציג שם, טלפון, אימייל אמיתיים מ-API
- [ ] Avatar = ראשי תיבות (אם אין תמונה)
- [ ] Stats מספרים אמיתיים (4 קווים)
- [ ] CTA "חידוש מנוי" → payment flow
- [ ] Row items עריכה (שם/טלפון/אימייל) → modal עריכה
- [ ] שינוי טלפון → דורש OTP חדש
- [ ] שינוי אימייל → email verification
- [ ] Logout → confirmation → `/login`

### G.20 · Settings
- [ ] Sidebar מציג section פעיל
- [ ] שינוי שפה → app reload mid-session, לא צריך restart
- [ ] גודל טקסט (A/A+/A++) → מחיל מיד
- [ ] Toggle ניגודיות גבוהה → הפעלה מיד
- [ ] Toggle Push → דורש הרשאה אם לא ניתנה
- [ ] Toggle SMS גיבוי → אינדיקציה שעלות SMS על המשתמש
- [ ] 2FA toggle → מעבר ל-setup wizard
- [ ] **התנתקות מכל המכשירים** → confirmation → POST + redirect ל-/login
- [ ] **מחיקת חשבון** → 2 confirmations + סיסמה → 7 ימים grace period
- [ ] **ייצא וצא** → ZIP file (כל הנתונים) → email/download

---

## H. Admin Console

### H.21 · Admin Dashboard
- [ ] Sidebar counts מתעדכנים בזמן אמת
- [ ] 4 stat-cards שורש = data אמיתי
- [ ] Chart 14 ימים מציג trend
- [ ] tabs (שבוע/חודש/שנה) משנים תקופה
- [ ] "פעילות אחרונה" — live updates (socket adminActivity)
- [ ] Production/Staging selector → switching environments
- [ ] לחיצה על log row → drill-down ל-event
- [ ] רק admin role יכול לגשת (other → redirect)

### H.22 · All Users
- [ ] Search ב-name/phone/email
- [ ] Filter סטטוס (פעיל/מושעה)
- [ ] Filter מנוי (פרימיום/חינם)
- [ ] Pagination 50 per page
- [ ] Click על row → user detail panel
- [ ] Actions menu (3-dots): edit / suspend / delete / impersonate
- [ ] Impersonate → opens new session as user (אזהרה ויזואלית)
- [ ] CSV export → download מסונן

### H.23 · All Lawyers
- [ ] טבלה דומה ל-Users
- [ ] עמודה "זמין" עם נקודה צבעונית
- [ ] לחיצה על row → lawyer detail עם תיקים שטופלו
- [ ] CTA "+ הוסף עו"ד" → form (manual register)
- [ ] Filter לפי תחום

### H.24 · Pending Lawyers
- [ ] רשימת בקשות נטענת
- [ ] כל בקשה כרטיס עם מסמכים מצורפים
- [ ] צפייה במסמכים → modal עם image/PDF
- [ ] **אשר** → POST → toast → לעבר ל-All Lawyers
- [ ] **דחה** → confirmation + סיבה → POST
- [ ] חסר מסמך → CTA disabled + tooltip
- [ ] Empty state כשאין בקשות

### H.25 · Emergency Logs
- [ ] Stream live updates (socket)
- [ ] Filter levels (CRITICAL/WARN/OK/ERROR)
- [ ] Date range picker
- [ ] Search by user/lawyer/scenario
- [ ] Click on row → full event JSON
- [ ] Export logs → CSV/JSON

### H.26 · Subscription Admin
- [ ] 3 stats מתעדכנים real-time
- [ ] רשימת תוכניות פעילות נטענת
- [ ] CTA "+ תוכנית חדשה" → form (name/price/features)
- [ ] עריכת תוכנית קיימת
- [ ] Disable plan → no new subscriptions, existing keep working

### H.27 · Admin Settings (System)
- [ ] שינוי "Timeout עו"ד" → backend config מתעדכן מיד
- [ ] שינוי "רדיוס חיפוש" → אפקט על dispatch הבא
- [ ] Toggle Twilio/Agora/FCM/Gemini → integration enable/disable
- [ ] **מצב תחזוקה ON** → כל אפליקציה אזרח/עו"ד מציג banner
- [ ] **איפוס cache** → 2 confirmations → POST → toast הצלחה
- [ ] שינויים נשמרים בלי refresh

---

## בדיקות תהליכים מקצה לקצה (E2E)

### E2E.1 · אזרח → SOS → שיחה → תיעוד
- [ ] רישום חדש → wizard → veto_screen
- [ ] בחירת תרחיש "חקירה" → זכויות מותאמות
- [ ] לחיצה SOS → dispatch → lawyer found → call screen
- [ ] שיחה 30 שניות → recording זמין
- [ ] סיום שיחה → recording בכספת אישית
- [ ] חזרה ל-veto_screen → status "מחובר · ממתין"

### E2E.2 · עו"ד → קבל קריאה → שיחה
- [ ] Login כעו"ד → dashboard
- [ ] toggle זמינות → ON
- [ ] קבלת alert בזמן אמת → case-card
- [ ] Accept → call screen
- [ ] במהלך שיחה: צ'אט גם פתוח לטקסטים
- [ ] סיום שיחה → תיק נשמר ב-history
- [ ] חזרה לדאשבורד → stats מתעדכנים

### E2E.3 · אדמין → ניהול עו"ד חדש
- [ ] Login כאדמין → dashboard
- [ ] sidebar Pending → 1 בקשה
- [ ] צפייה במסמכים → אישור
- [ ] עו"ד חדש מקבל email/SMS אישור
- [ ] עו"ד מתחבר → רואה dashboard ראשון

---

## בדיקות אבטחה (חוצה מסכים)

| # | בדיקה |
|---|--------|
| S1 | JWT expired → auto-redirect ל-/login |
| S2 | אין JWT → auto-redirect ל-/login |
| S3 | OTP rate limit (10/hour) → error ברור |
| S4 | Storage encryption: לא ניתן לקרוא בלי PIN/Biometric |
| S5 | E2E encryption: server לא יכול לפענח שיחות |
| S6 | Vault files: AES-256 in storage |
| S7 | HTTPS only — שגיאה אם HTTP |
| S8 | CORS: backend מאפשר רק origins ידועים |
| S9 | XSS: כל user input sanitized לפני render |
| S10 | CSRF tokens על מצבי form sensitive |
| S11 | Permissions revoked → graceful degradation (no crash) |
| S12 | Audit log על פעולות אדמין (impersonate, delete user) |

---

## בדיקות ביצועים

| # | בדיקה | יעד |
|---|--------|-----|
| P1 | Initial load (cold start) | ≤ 3s |
| P2 | Splash duration | 1.8s |
| P3 | Tab switch (citizen tabs) | ≤ 200ms |
| P4 | Chat message send | ≤ 500ms (optimistic) |
| P5 | SOS dispatch | ≤ 4s עד "lawyer found" |
| P6 | Vault file upload (10MB) | ≤ 8s על 4G |
| P7 | Map render with 50 pins | ≤ 1.5s |
| P8 | Admin table 1000 rows | ≤ 2s |
| P9 | FPS during animations | ≥ 55fps |
| P10 | Memory usage idle | ≤ 150MB |

---

## רשימת תקלות ידועות (לטיפול לפני production)

> תתעדכן במהלך QA. כל פריט שלא עובר → פותחים ticket.

- [ ] _(בהמשך — ייכתב במהלך מעבר QA)_
