# VETO · Inventory · 2026

> מצאי המסכים הנוכחיים והתאמתם למוקאפים החדשים. עוזר לתכנן את שלב המימוש Flutter.

## טבלת סטטוס

| # | מסך | קובץ Flutter | שורות | מוקאפ HTML | מערכת theme | מורכבות מימוש |
|---|------|-------------|--------|-----------|-------------|----------------|
| 01 | Splash | `splash_screen.dart` | 142 | `splash.html` | glassDark (heavy) | **קלה** |
| 02 | Landing | `landing_screen.dart` | 1,320 | `landing.html` | glass-aurora | **גבוהה** |
| 03 | Login | `login_screen.dart` | 1,308 | `login.html` | glass+light | **גבוהה** |
| 04 | Citizen Home | `veto_screen.dart` | 3,148 | `citizen.html` | glassDark + light3D | **גבוהה מאוד** |
| 05 | Wizard Shell | `wizard/wizard_shell_screen.dart` | 681 | `wizard.html` | mixed | **בינונית** |
| 06 | Lawyer Dashboard | `lawyer_dashboard.dart` | 1,059 | `lawyer.html` | mixed | **גבוהה** |
| 07 | Lawyer Settings | `lawyer_settings_screen.dart` | ? | `lawyer.html` (תחתית) | mixed | **בינונית** |
| 08 | Chat | `chat_screen.dart` | ? | `communication.html` | mixed | **בינונית** |
| 09 | Call Entry | `call_entry_screen.dart` | ? | `communication.html` | dark | **קלה** |
| 10 | Call Screen | `call_screen.dart` | ? | `communication.html` | dark | **בינונית** |
| 11 | Call Session | `call_session_screen.dart` | ? | `communication.html` | dark | **בינונית** |
| 12 | Agora Call | `agora_call_screen.dart`* | ? | `communication.html` | dark | **גבוהה** |
| 13 | In-call Speech | `in_call_speech*.dart` (3 platform splits) | ? | _(part of call)_ | n/a | **בינונית** |
| 14 | Evidence | `evidence_screen.dart` | ? | `vault.html` | dark | **בינונית** |
| 15 | Files Vault | `files_vault_screen.dart` | ? | `vault.html` | luxuryLight | **בינונית** |
| 16 | Shared Vault | `shared_vault_screen.dart` | ? | `vault.html` | luxuryLight | **בינונית** |
| 17 | Maps | `maps_screen.dart` | ? | `vault.html` | luxuryLight | **קלה** (webview) |
| 18 | Legal Calendar | `legal_calendar_screen.dart` | ? | `legal-tools.html` | luxuryLight | **בינונית** |
| 19 | Legal Notebook | `legal_notebook_screen.dart` | ? | `legal-tools.html` | luxuryLight | **בינונית-גבוהה** |
| 20 | Legal Document | `legal_document_screen.dart` | ? | `legal-tools.html` | luxuryLight | **קלה** |
| 21 | Profile | `profile_screen.dart` | ? | `settings.html` | luxuryLight | **קלה** |
| 22 | Settings | `settings_screen.dart` | ? | `settings.html` | luxuryLight | **בינונית** |
| 23 | Admin Dashboard | `admin_dashboard.dart` | ? | `admin.html` | luxuryLight | **גבוהה** |
| 24 | Admin Settings | `admin_settings_screen.dart` | ? | `admin.html` | luxuryLight | **בינונית** |
| 25 | All Users | `admin/all_users_screen.dart` | ? | `admin.html` | luxuryLight | **בינונית** |
| 26 | All Lawyers | `admin/all_lawyers_screen.dart` | ? | `admin.html` | luxuryLight | **בינונית** |
| 27 | Pending Lawyers | `admin/pending_lawyers_screen.dart` | ? | `admin.html` | luxuryLight | **קלה** |
| 28 | Emergency Logs | `admin/emergency_logs_screen.dart` | ? | `admin.html` | luxuryLight | **קלה** |
| 29 | Subscription Admin | `subscription_admin_screen.dart` | ? | `admin.html` | luxuryLight | **בינונית** |

\* `agora_call_screen.dart` מוזכר ב-PROJECT_STRUCTURE.md אך לא הופיע ב-`ls screens/` — ייתכן שצריך לוודא שהוא קיים.

## מודולים תומכים שצריכים עדכון

| מודול | מטרה | פעולה |
|--------|--------|--------|
| `core/theme/veto_theme.dart` | luxuryLight + glassDark | **שכתוב מלא** ל-`veto_theme_2026.dart` עם design tokens חדשים |
| `core/theme/veto_glass_system.dart` | glass-dark tokens | **למחוק** או להפוך ל-legacy fallback |
| `core/theme/future_surface.dart` | surfaces helper | **לבדוק רלוונטיות** |
| `widgets/dispatch_sheets.dart` | bottom sheets | **עדכון לעיצוב חדש** |
| `widgets/ai_chat_dialog.dart` | AI chat widget | **עדכון לבועות AI מובחנות** |
| `widgets/app_language_menu.dart` | בורר שפה | **כמעט ללא שינוי** (פנים אסטטי) |
| `widgets/accessibility_toolbar.dart` | toolbar נגישות | **עדכון לסגנון bottom sheet בהיר** |
| `widgets/veto_live_voice_sheet.dart` | Gemini live voice | **עדכון לעיצוב חדש** |

## נכסים לטיפול

| נכס | מצב נוכחי | פעולה נדרשת |
|------|-----------|--------------|
| `assets/fonts/Heebo-VF.ttf` | קיים | ✅ נשמר |
| `assets/fonts/FrankRuhlLibre-*.ttf` | חסר | **להוסיף** (כותרות סריפי-עברי) |
| `assets/icons/*` | אם קיים | לבדוק שאין glow/neon |
| `web/index.html` | meta + manifest | לעדכן theme-color ל-Navy 600 |
| `web/manifest.json` | PWA | לעדכן צבעים |
| `assets/splash/*` | splash native | להחליף splash images |
| `android/app/src/main/res/...` | Android resources | adaptive icon חדש |
| `ios/Runner/Assets.xcassets/...` | iOS resources | App icon חדש |

## הערכת מימוש

| Phase | תיאור | היקף |
|-------|--------|------|
| **Phase 1** | Theme tokens חדשים + Heebo+Frank Ruhl Libre | 1-2 ימי עבודה |
| **Phase 2** | Splash + Landing + Login | 3-4 ימי עבודה |
| **Phase 3** | Citizen Home (veto_screen 3.1k שורות) | 5-7 ימי עבודה |
| **Phase 4** | Lawyer Dashboard + Settings + Profile | 4-5 ימי עבודה |
| **Phase 5** | Communication (chat + 3 call screens) | 4-5 ימי עבודה |
| **Phase 6** | Vault + Evidence + Maps | 4-5 ימי עבודה |
| **Phase 7** | Legal Tools (calendar + notebook + document) | 3-4 ימי עבודה |
| **Phase 8** | Admin Console (7 מסכים) | 5-7 ימי עבודה |
| **Phase 9** | QA + Bug fixes + Polish | 5-7 ימי עבודה |
| **סה"כ** | | **~6-8 שבועות עבודה** |
