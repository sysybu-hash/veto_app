# VETO — שפת עיצוב 2026 (Pango-class)

מסמך רפרנס ליישום ב-Flutter. **רפרנס ויזואלי:** מוצר צרכני ישראלי — בהירות, כחול מותג, פינות עגולות, מגירות, FABs (ראו צילומי פנגו בפרויקט).

## טוקנים (`lib/core/theme/veto_mockup_tokens.dart`)

| טוקן | ערך / כלל |
|------|------------|
| `pageBackground` | `#F4F6FA` — אפור־כחלחל בהיר |
| `surfaceCard` | `#FFFFFF`, צל רך |
| `radiusCard` | 24px (כרטיסים גדולים); pill לכפתורים |
| `primaryCta` | כחול מותג `#2B65EC` |
| `primaryCtaDeep` / `Dark` | כחול כהה לגרדיאנט / לחיץ |
| `drawerTint` | `#E8F1FF` — מגירת תפריט |
| `drawerHeader` | `#0E2A5A` — כותרות מגירת נגישות |
| `emerg` | אדום חירום (לא מחליף primary) |
| `textPrimary` | `#1A1A1A` |
| `textSecondary` | `#4A5568` |
| `hairline` | `#E2E8EF` |
| `wheelRed/Teal/Orange/Yellow/Sky` | דיסקיות אייקון בגלגל שירותים |

## מבנה

- **דסקטופ RTL:** כמו קודם — סרגל ימין באפליקציה; **דף נחיתה** — הירו מרכזי עם גלגל תרחישים, מגירה מקצה המסך.
- **מובייל:** כרטיס לבן גדול, שורת שירותים, CTA עגול עם הילה עדינה.

## רכיבים

- `lib/core/theme/veto_mockup_tokens.dart`
- `lib/widgets/citizen_mockup_shell.dart`
- `lib/widgets/veto_landing_service_hub.dart` — גלגל תרחישים (דף נחיתה)
- `lib/l10n/*.arb` — מחרוזות רב־לשוניות (מבנה זהה בין שפות)

## הגבלות Web

- `web/index.html`: `dir="ltr"` ל-WebRTC; RTL ב-`Directionality` של Flutter בלבד.

## מסכים מול מוקאפ

ראו [VETO_SCREEN_MATRIX_2026.md](VETO_SCREEN_MATRIX_2026.md).
