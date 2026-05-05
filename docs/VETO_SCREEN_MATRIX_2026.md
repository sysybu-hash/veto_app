# VETO — מטריצת מסכים מול מוקאפ ורפרנס עיצוב (מאי 2026)

מסמך איחוד דרישות ליישום התוכנית. **רפרנס ויזואלי ראשי:** שפת עיצוב פנגו־סוג (כחול ראשי, רקע בהיר, פינות עגולות, מגירות, FABs) — ראו צילומי משתמש ב־`assets/` ו־[`design_mockups/`](design_mockups/).

## נתיבים (מקור: `vetoAppRoutes` ב־[`frontend/lib/main.dart`](../frontend/lib/main.dart))

| נתיב | תפקיד | מוקאפ | קוד / i18n |
|------|--------|--------|------------|
| `/` | Splash | ממתין | **בוצע** — ללא מחרוזות UI קשיחות בקוד המסך |
| `/landing` | דף בית שיווקי | `08_veto_landing_pango_class.html` | **בוצע** — ARB, גלגל, מגירה, FABs |
| `/login` | OTP | ממתין | **בוצע** — ARB + קישורי פוטר; הודעת Flows ב־ARB |
| `/wizard_home`, `/emergency_wizard` | אונבורדינג | ממתין | **בוצע** — `wizOnb*` / `wizShell*` ב־ARB (`onboarding_wizard_screen`, `wizard_shell_screen`) |
| `/veto_screen` | Hub אזרח | ממתין PNG QA (he/en/ru) | **בוצע** — ממשק מ־ARB (`vetoUi*` וכו'); דיאלוג מנוי `_SubscriptionGateDialog` ב־`vetoPaySub*` / `vetoPayPal*`; תרחישים: `_sdMap` + אופציונלי `assets/l10n/scenarios_bundle.json` (`overrides` ל־`he`/`ru`/`en`); בדיקה `test/scenarios_bundle_json_test.dart` |
| `/lawyer_dashboard` | לוח עו"ד | **בוצע** — צילום קוד [`veto-code-lawyer-dashboard-1440x900.png`](../design_mockups/from_code_2026/veto-code-lawyer-dashboard-1440x900.png) | **בוצע** — `lawyerDash*` ב־ARB (he/en/ru) |
| `/profile` | פרופיל | ממתין PNG ייעודי | **בוצע** — תוויות תפקיד מ־`landingRoleLawyer` / `Admin` / `User` ב־ARB |
| `/admin_settings`, `/admin_dashboard`, `/admin_*` | אדמין | ממתין | **בוצע** — `adm*` + `AdminStrings.languageLabel` דרך ARB (`cset*`) |
| `/settings` | הגדרות אזרח | ממתין | **בוצע** — ARB + IA |
| `/lawyer_settings` | הגדרות עו"ד | ממתין | **בוצע** — ARB |
| `/files_vault`, `/legal_calendar`, `/legal_notebook`, `/chat`, `/call`, `/maps`, `/shared_vault` | פיצ'רים משותפים | ממתין (PNG QA) | **גל E — ARB + טוקנים** (vault badges/time · יומן · מחברת · צ׳אט סטטוס דסקטופ · מפות · כספת משותפת) |
| `/citizen_*`, `/security_center` | אזרח | ממתין | **בוצע** — סריקה: ללא `lang`/עברית קשיחה במסכי citizen |
| `/privacy`, `/terms` | מסמכים | ממתין | **גל E — כותרות ב־ARB**; גוף טקסט לפי שפה כמו קודם |

**רכיבים גלובליים:** `global_legal_ai_overlay` — **בוצע** (`legalAi*` ב־ARB); `veto_dialogs` — **בוצע** (ברירות מחדל `commonOk` / `vetoUiCancel`).

## עקביות רב־לשונית (he / en / ru)

- מבנה זהה; כיווניות בלבד (`Directionality` + `*Directional`).
- בדיקה: אותה רזולוציה, שלוש שפות, ללא סטיית פריסה.

## מוקאפים קיימים ב־repo

- HTML: [`design_mockups/01_landing_premium_dark.html`](../design_mockups/01_landing_premium_dark.html) (כהה — לא רפרנס ראשי ל־2026).
- חדש: `design_mockups/08_veto_landing_pango_class.html` (פנגו־סוג ל־VETO).

## Linear

- צוות `Veto_legal`, קידומת `VET` — לשלב משימות UX לפי מסך מהטבלה לעיל.
