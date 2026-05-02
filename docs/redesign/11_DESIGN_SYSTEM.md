# VETO · Design System · 2026

> Design Tokens — מקור אחד לכל הצבעים, הטיפוגרפיה, המרווחים, הצללים והרכיבים. כל המוקאפים תואמים את המסמך הזה. כל קוד Flutter עתידי צריך לאכוף אותו.

## עקרונות

1. **מקצועי-יוקרתי בהיר** — תחושת משרד עורכי דין מודרני, נייר רגוע, סריפי לכותרות.
2. **Pango-inspired** — כחול עמוק, נקי, טיפוגרפיה ברורה, RTL מלא.
3. **לא**: glass כהה, glow ניאון, גרדיאנטים סגולים, חמש שכבות צל.
4. **כן**: לבן רגוע, צללים נמוכים אחידים, accent זהב נדיר, אדום יוקרתי ל-SOS בלבד.

---

## 1. Color Tokens

### Brand · Navy
| Token | Hex | שימוש |
|-------|-----|--------|
| `navy-900` | `#0E1F37` | רקע כהה מקסימלי (CTA strip, call screen) |
| `navy-800` | `#13284A` | wizard rail bg |
| `navy-700` | `#1B3A66` | crest gradient start |
| **`navy-600`** | **`#264975`** | **PRIMARY brand** — CTA, links accents, kicker |
| `navy-500` | `#2E69E7` | crest gradient end, focus ring, links |
| `navy-400` | `#5B8BF0` | hover, secondary |
| `navy-300` | `#83B7F8` | hover border, decorative |
| `navy-200` | `#B6D2FB` | tags, chips backgrounds |
| `navy-100` | `#D4F1F7` | sidebar active background |

### Accent · Gold (sparing)
| Token | Hex | שימוש |
|-------|-----|--------|
| `gold` | `#B8895C` | premium tag, CTA זהב יחיד |
| `gold-soft` | `#E9D9C2` | hero underline, badges חיוביים נדירים |
| `gold-deep` | `#8C6235` | gold text on light bg |

**כלל**: Gold מופיע ב-≤3 מקומות לדף. הוא תמלוגים — לא צבע פעולה.

### Surfaces
| Token | Hex | שימוש |
|-------|-----|--------|
| `paper` | `#F6F8FB` | רקע גוף |
| `paper-2` | `#EEF2F8` | כרטיסים מושקעים, tab inactive |
| `paper-3` | `#E5EBF4` | divider עוד יותר עמוק |
| `surface` | `#FFFFFF` | כרטיסים ראשיים |
| `surface-2` | `#FBFCFE` | hover/secondary surfaces |

### Lines
| Token | Hex | שימוש |
|-------|-----|--------|
| `hairline` | `#E2E8F0` | borders רגילים |
| `hairline-2` | `#CBD5E1` | seperators contrasting |
| `hairline-strong` | `#94A3B8` | rare emphasis |

### Ink (Text)
| Token | Hex | שימוש |
|-------|-----|--------|
| `ink-900` | `#0B1830` | primary text (headings, body) |
| `ink-800` | `#162646` | document body (in serif) |
| `ink-700` | `#27374D` | secondary text |
| `ink-500` | `#4A5A75` | muted body |
| `ink-300` | `#7A8AA5` | placeholder, hints |
| `ink-200` | `#A6B3C8` | disabled |

### Status
| Token | Hex | שימוש |
|-------|-----|--------|
| `emerg` | `#D6243A` | SOS, danger CTAs, recording |
| `emerg-2` | `#B81B30` | hover/pressed |
| `emerg-soft` | `#FBE7EA` | success-on-danger surfaces |
| `emerg-bg` | `#FFF5F1` | background של callout danger |
| `emerg-border` | `#F8D6CB` | borders של danger callouts |
| `ok` | `#2BA374` | success indicators, "online" dot |
| `ok-soft` | `#DDF2E9` | success callout bg |
| `warn` | `#C58B12` | warnings, "busy" |
| `warn-soft` | `#FBEFD3` | warn callout bg |
| `info` | `#2E69E7` | = navy-500 |
| `info-soft` | `#DCE7FB` | info callout bg |

---

## 2. Typography

### Font Stacks
```
--serif: 'Frank Ruhl Libre', 'Times New Roman', Georgia, serif;
--sans:  'Heebo', 'Assistant', system-ui, -apple-system, 'Segoe UI', sans-serif;
--mono:  ui-monospace, 'SFMono-Regular', 'Menlo', monospace;
```

### Scale (Material 3 inspired, חידוש לעברית)
| Style | Family | Size | Weight | Line | Letter | שימוש |
|-------|--------|------|--------|------|--------|--------|
| `display-lg` | serif | 57px | 700 | 1.05 | -0.5 | landing hero |
| `display-md` | serif | 45px | 700 | 1.1 | -0.3 | onboarding hero |
| `display-sm` | serif | 36px | 600 | 1.15 | -0.2 | section headers |
| `headline-lg` | serif | 32px | 800 | 1.2 | 0.2 | page headings |
| `headline-md` | serif | 28px | 700 | 1.25 | 0.0 | card titles big |
| `headline-sm` | serif | 24px | 700 | 1.3 | 0.0 | section labels |
| `title-lg` | serif | 20px | 700 | 1.3 | 0.2 | card titles |
| `title-md` | sans | 16px | 600 | 1.4 | 0.0 | row item titles |
| `title-sm` | sans | 14px | 600 | 1.4 | 0.0 | meta labels |
| `body-lg` | sans | 16px | 500 | 1.65 | 0.0 | hero body |
| `body-md` | sans | 14px | 500 | 1.5 | 0.0 | regular body |
| `body-sm` | sans | 13px | 500 | 1.55 | 0.0 | secondary body |
| `body-xs` | sans | 11px | 500 | 1.4 | 0.0 | small details |
| `label-lg` | sans | 14px | 700 | 1.2 | 0.6 | buttons large |
| `label-md` | sans | 13px | 700 | 1.2 | 0.4 | buttons regular |
| `label-sm` | sans | 11px | 800 | 1.2 | 0.18em | kickers, eyebrows (UPPERCASE) |
| `mono-md` | mono | 14px | 700 | 1.4 | 0.0 | timers, IDs |

**RTL**: `letter-spacing` חיובי בעברית פוגע בקריאות בגדלים קטנים. בעברית, ב-≤14px להגדיר `letter-spacing: 0`.

---

## 3. Spacing Scale

```
--s-1: 4px
--s-2: 8px
--s-3: 12px
--s-4: 16px
--s-5: 20px
--s-6: 24px
--s-8: 32px
--s-10: 40px
--s-12: 48px
--s-16: 64px
```

**כללי שימוש**:
- מרווח פנימי בכרטיס: `--s-5` ל-`--s-6`
- מרווח בין כרטיסים: `--s-4` ל-`--s-6`
- מרווח בין סקציות: `--s-8` ל-`--s-10`
- מרווח hero: `--s-12` ל-`--s-16`

---

## 4. Radius Scale

```
--r-xs: 6px      → micro (badges)
--r-sm: 8px      → buttons, small cards
--r-md: 12px     → standard cards
--r-lg: 16px     → big cards, sections
--r-xl: 22px     → hero subsection
--r-2xl: 28px    → hero card
--r-pill: 999px  → pills, status badges
```

**כללי**: רכיב גדול = רדיוס גדול יותר, אבל לא יותר מ-28px.

---

## 5. Shadows

```css
--shadow-1: 0 1px 2px rgba(11,24,48,.04), 0 8px 24px rgba(11,24,48,.06);
   /* רכיבים רגילים */

--shadow-2: 0 2px 4px rgba(11,24,48,.05), 0 18px 48px rgba(11,24,48,.10);
   /* hero, modal */

--shadow-3: 0 4px 8px rgba(11,24,48,.06), 0 28px 72px rgba(11,24,48,.14);
   /* dropdowns, popups */

--shadow-emerg: 0 12px 40px rgba(214,36,58,.28);
   /* SOS orb בלבד */

--shadow-brand: 0 6px 16px rgba(38,73,117,.30);
   /* primary CTA */
```

**כללי**: ≤2 שכבות צל לרכיב. לא להמציא צל חדש לכל מקום — להשתמש מהמערכת.

---

## 6. Motion

| Token | Curve | משך | שימוש |
|-------|-------|------|--------|
| `ease` | `cubic-bezier(.4,0,.2,1)` | — | curve סטנדרטי |
| `dur-fast` | — | 120ms | hover state |
| `dur-base` | — | 200ms | tab switch, focus |
| `dur-medium` | — | 300ms | dialog enter/exit |
| `dur-slow` | — | 500ms | page transition |
| `pulse` | infinite | 3.2s | SOS rings |

**כללי**:
- `prefers-reduced-motion` → כל אנימציה ל-`.01ms` (ראה `_veto-2026.css` שורות 109-112).
- אין bouncing/elastic. רק ease-out.
- אין rotate fancy של אייקונים.

---

## 7. Components

### Buttons

| סגנון | מתי |
|--------|------|
| `cta` (primary) | פעולה ראשית בעמוד |
| `cta.lg` | hero CTA, שלבים סופיים |
| `cta.ghost` | פעולה משנית בולטת |
| `cta.subtle` | פעולה משנית רגילה |
| `cta.danger` | SOS, מחיקה, קבלת קריאה (אדום) |
| `cta.gold` | פרימיום, "לעבור לאשף" יחיד |
| `ghost-btn` | פעולות לידיות |
| `ghost-btn.danger` | פעולות הרסניות נדירות |
| `iconbtn` | פעולות ללא טקסט |

**גובה סטנדרטי**: 38px (regular), 48px (lg), 32px (sm), 36px (ghost-btn).

### Status Pill
- White bg, hairline border, padding 7×14, font 12/700.
- כולל dot צבעוני (ok=ירוק, busy=כתום, offline=אפור, live=אדום).

### Badge
- 7 וריאנטים: default, brand, ok, warn, danger, gold.
- padding 3×10, radius pill, font 11/700.

### Card
- White, hairline border, radius 16, shadow-1.
- אופציה: lift (shadow-2).
- מבנה: `head` + `body` + `foot` (כולם אופציונליים).

### Field / Input
- 44px גובה, padding 0×14, border hairline, radius 10.
- focus → border navy-500 + shadow ring 4px rgba(46,105,231,.10).
- אייקון ב-end side via `input-with-ico` wrapper.

### Tabs
- inline-flex, padding 4 פנימי, gap 2 בין tabs.
- bg paper-2, border hairline, radius 10.
- active = white + shadow-1.

### Bottom Tabs (Mobile)
- 4 lpd, height 72, white bg, top border.
- active = navy-600 + pip 22×4 בתחתית.

### Sidebar
- 240px קבוע בדסקטופ.
- group-title (10px, 0.18em letter, uppercase, ink-300).
- a items: 9×12 padding, font 13/600, hover paper-2.
- active = navy-100 bg + 3px navy-600 vertical bar.

### Tables
- thead: paper-2 bg, hairline bottom, font 11/800 uppercase 0.08em letter.
- tbody td: 14×16 padding, hairline bottom.
- hover row → surface-2 bg.

### Callouts (4 וריאנטים)
- Info, Warn, Danger, Success.
- Border + bg matching color, ico 24×24 בצבע.
- font 13/1.55.

### Avatar
| size | width | radius | font | שימוש |
|------|-------|--------|------|--------|
| sm | 30 | 8 | 12 | tables |
| default | 46 | 14 | 16 | cards, lists |
| lg | 64 | 18 | 22 | hero/profile compact |
| xl | 96 | 24 | 34 | profile hero |

---

## 8. עקרונות ויזואליים

### גרדיאנטים מותרים
1. **Crest** (logo): `linear-gradient(135deg, navy-700, navy-500)`
2. **CTA strip background**: `linear-gradient(135deg, navy-700, navy-600)` + radial gold accent
3. **SOS orb**: `radial-gradient(120% 120% at 30% 25%, #FF8492 0%, #E5354C 38%, #B81B30 78%)`
4. **Card head**: `linear-gradient(180deg, surface-2, white)` (subtle wash)
5. **Ambient page bg**: 2 radial gradients ב-paper (navy + gold tints)

**אסור**: rainbow, neon, סגול↔ורוד, gradient על טקסט.

### אייקונים
- Stroke-based, weight 2 (regular) / 2.5 (emphasized).
- Size: 14 (small inline), 16 (default), 18-20 (cards), 22-24 (hero/buttons).
- Color: inherit מההורה.
- Source: feather-icons / lucide / ידני SVG.

### Imagery
- אין תמונות סטוק זולות.
- אם נדרש: צילום עו"ד אמיתיים, בכל לבוש, רקע שחור/לבן, b/w או lightly-tinted.

---

## 9. RTL Specifics

- `dir="rtl"` ב-html.
- `text-align: start/end` (לא left/right).
- Spacings logical: `padding-inline-start`, `margin-inline-end`.
- אייקונים שמסמלים כיוון (← →) — להפוך אוטומטית ב-RTL.
- Numbers + פטחים LTR בתוך RTL: `direction: ltr` לתאים.

---

## 10. Mapping ל-Flutter Tokens

(הצעה — ייושם בקובץ `core/theme/veto_theme_2026.dart`)

```dart
class VetoTokens2026 {
  // Brand
  static const navy900 = Color(0xFF0E1F37);
  static const navy800 = Color(0xFF13284A);
  static const navy700 = Color(0xFF1B3A66);
  static const navy600 = Color(0xFF264975);  // PRIMARY
  static const navy500 = Color(0xFF2E69E7);
  static const navy400 = Color(0xFF5B8BF0);
  static const navy300 = Color(0xFF83B7F8);
  static const navy200 = Color(0xFFB6D2FB);
  static const navy100 = Color(0xFFD4F1F7);

  // Surfaces
  static const paper = Color(0xFFF6F8FB);
  static const paper2 = Color(0xFFEEF2F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFBFCFE);

  // Lines
  static const hairline = Color(0xFFE2E8F0);
  static const hairline2 = Color(0xFFCBD5E1);

  // Ink
  static const ink900 = Color(0xFF0B1830);
  static const ink700 = Color(0xFF27374D);
  static const ink500 = Color(0xFF4A5A75);
  static const ink300 = Color(0xFF7A8AA5);

  // Status
  static const emerg = Color(0xFFD6243A);
  static const ok = Color(0xFF2BA374);
  static const warn = Color(0xFFC58B12);

  // Gold accent
  static const gold = Color(0xFFB8895C);
  static const goldSoft = Color(0xFFE9D9C2);

  // Radius
  static const rSm = 8.0;
  static const rMd = 12.0;
  static const rLg = 16.0;
  static const r2Xl = 28.0;
  static const rPill = 999.0;

  // Shadows
  static List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0A0B1830), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0B1830), blurRadius: 24, offset: Offset(0, 8)),
  ];
  // ... etc
}
```

ה-Theme הראשי יוגדר ב-`VetoTheme2026.luxuryLight()` ויחליף את `VetoTheme.luxuryLight()` הישן.
