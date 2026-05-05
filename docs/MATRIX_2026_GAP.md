# מטריצת גאפ: `2026/00_index.html` ↔ Flutter

מקור אמת למוקאפים: `2026/00_index.html` (27 כרטיסים). עמודת **סטטוס** מתעדכנת לפי ספרינטים; סימון נוכחי משקף את מצב הקוד אחרי סגירת פערי Citizen + AI/Live בתוכנית Gemini Live + Parity.

| # | קבוצה | מוקאפ HTML | קובץ Dart (יעד) | סטטוס | הערות QA |
|---|--------|------------|-----------------|--------|-----------|
| 01 | Auth | `splash.html` | `frontend/lib/screens/splash_screen.dart` | חלקי | השוואת משך/אנימציה לעומת 1.8s |
| 02 | Auth | `landing.html` | `frontend/lib/screens/landing_screen.dart` | חלקי | Hero, מחירים, CTA |
| 03 | Auth | `login.html` | `frontend/lib/screens/login_screen.dart` | חלקי | אשף 3 שלבים, עמודה כהה/בהירה |
| 04 | Citizen | `citizen.html` | `frontend/lib/screens/veto_screen.dart` | עבר (ספרינט נוכחי) | 6 תרחישים, פאנל פירוט, זכויות עשירות, בועת AI, Live |
| 05 | Citizen | `wizard.html` | `frontend/lib/screens/wizard/wizard_shell_screen.dart` | חלקי | רכבת התקדמות, 4 שלבים |
| 06 | Lawyer | `lawyer.html` | `frontend/lib/screens/lawyer_dashboard.dart` | חלקי | Sidebar, סטטיסטיקות, דחיפות |
| 07 | Lawyer | `lawyer.html#settings` | `frontend/lib/screens/lawyer_settings_screen.dart` | חלקי | 4 כרטיסי הגדרות |
| 08 | Communication | `communication.html` | `frontend/lib/screens/veto_screen.dart` (צ'אט אזרח) / `chat_screen.dart` | חלקי | `.ai-card` הוטמע ב־`GeminiAiMessageCard`; sidebar שיחות — להשוות |
| 09 | Communication | `communication.html#call-entry` | `frontend/lib/features/call/call_screen.dart` (זרימת כניסה) | חלקי | מסך התחברות + incoming |
| 10 | Communication | `communication.html#call` | `frontend/lib/features/call/call_screen.dart` | חלקי | כפתורי שליטה, recording pill |
| 11 | Communication | `communication.html#video` | `frontend/lib/features/call/call_screen.dart` | חלקי | Agora self-view, overlays |
| 12 | Vault | `vault.html` | `frontend/lib/screens/files_vault_screen.dart` | חלקי | גריד, badges |
| 13 | Vault | `vault.html#shared` | `frontend/lib/screens/shared_vault_screen.dart` | חלקי | שני טורים, חתימה |
| 14 | Vault | `vault.html#evidence` | `frontend/lib/screens/evidence_screen.dart` | חלקי | viewfinder כהה, GPS |
| 15 | Vault | `vault.html#map` | `frontend/lib/screens/maps_screen.dart` | חלקי | פינים, כרטיס תחתון |
| 16 | Legal Tools | `legal-tools.html` | `frontend/lib/screens/legal_calendar_screen.dart` | חלקי | צבעי אירוע |
| 17 | Legal Tools | `legal-tools.html#notebook` | `frontend/lib/screens/legal_notebook_screen.dart` | חלקי | Markdown, sidebar |
| 18 | Legal Tools | `legal-tools.html#document` | `frontend/lib/screens/legal_document_screen.dart` | חלקי | רוחב, טאבים |
| 19 | Settings | `settings.html` | `frontend/lib/screens/profile_screen.dart` | חלקי | אווטר, stats |
| 20 | Settings | `settings.html#settings` | `frontend/lib/screens/settings_screen.dart` | חלקי | קטגוריות, אזור מסוכן |
| 21 | Admin | `admin.html` | `frontend/lib/screens/admin_dashboard.dart` | חלקי | stats, chart |
| 22 | Admin | `admin.html#users` | `frontend/lib/screens/admin/all_users_screen.dart` | חלקי | טבלה, סינון |
| 23 | Admin | `admin.html#lawyers` | `frontend/lib/screens/admin/all_lawyers_screen.dart` | חלקי | — |
| 24 | Admin | `admin.html#pending` | `frontend/lib/screens/admin/pending_lawyers_screen.dart` | חלקי | כרטיסי בקשה |
| 25 | Admin | `admin.html#logs` | `frontend/lib/screens/admin/emergency_logs_screen.dart` | חלקי | זרם לוגים |
| 26 | Admin | `admin.html#subscriptions` | `frontend/lib/screens/subscription_admin_screen.dart` | חלקי | ARPU, תוכניות |
| 27 | Admin | `admin.html#admin-settings` | `frontend/lib/screens/admin_settings_screen.dart` | חלקי | תקשורת / Gemini env |

## סדר עדיפויות (מתוכנית המקור)

1. Citizen + AI / Gemini Live — **בוצע בספרינט זה** (תרחישים, זכויות, בועת AI, הגדרות Live, באנר Live).
2. Communication / Call — הבא בתור.
3. Vault.
4. Auth / Landing / Login.
5. Lawyer.
6. Admin.

## בדיקות

- `flutter analyze` (שורש `frontend/`).
- Web: סשן מיקרופון Live, שינוי שפה/קול בעמוד ההגדרות, ריענון — וידוא ערכים ב-`SharedPreferences`.
