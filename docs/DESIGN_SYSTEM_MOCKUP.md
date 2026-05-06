# VETO — שפת עיצוב מונחה מוקאפ (2026)

מסמך רפרנס ליישום ב-Flutter. מקורות ויזואליים:

- דסקטופ: `assets/` + קבצי PNG ב-workspace (מוקאפ סרגל ימין, חיפוש, Hub, מדדים).
- מובייל: מוקאפ עם הירו, מגן משפטי 2×2, צ'יפים, כלים עגולים, פעילות, Bottom Nav עם כפתור מרכזי.

## טוקנים

| טוקן | ערך / כלל |
|------|------------|
| `pageBackground` | לבן / `#F7F5F0` — אפור-קרם בהיר |
| `surfaceCard` | `#FFFFFF`, צל `0 4px 24px rgba(0,0,0,0.06)` |
| `radiusCard` | 16–20px |
| `radiusButton` | 12–16px (pill לחיפוש) |
| `primaryCta` | בורדו/אדום `#B91C3C`–`#7A1E2E`, טקסט לבן מודגש |
| `navActive` | אדום + קו תחתון / זוהר עדין |
| `textPrimary` | `#1A1A1A`, כותרות `FontWeight.w700`–`w800` |
| `textSecondary` | `#4A5568` |
| `metricBlue` / `metricPurple` | כרטיסי סטטיסטיקה (איקון + מספר) |
| `hairline` | `#E8E4DC` |

## מבנה

- **דסקטופ RTL**: סרגל ניווט אנכי **ימין**; תוכן משמאל; שורת עליון: חיפוש, פעמון, פרופיל.
- **מובייל**: Bottom navigation — בית | הגנות | **שלח VETO** (מרכז מורם) | מסמכים | עוד (מגירה).

## רכיבים משותפים (קוד)

- `lib/core/theme/veto_mockup_tokens.dart` — קבועי צבע/רדיוס.
- `lib/widgets/veto_shell_sidebar.dart` — מעטפת דסקטופ.
- `lib/widgets/veto_mobile_nav.dart` — ניווט תחתון עם כפתור מרכזי.
- `lib/widgets/veto_dialogs.dart` — דיאלוגים אחידים.

## הגבלות Web

- `web/index.html`: `dir="ltr"` נשמר ל-WebRTC; RTL רק ב-`Directionality` של Flutter.
