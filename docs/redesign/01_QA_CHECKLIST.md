# VETO 2026 — Manual QA Checklist

This is the release gate for visual alignment between the Flutter app and the
VETO 2026 HTML/CSS mockups in `2026/*.html`. Run through it before promoting
any redesign change to `main` or to production.

## How to run

### Chrome (desktop + mobile breakpoints)

```powershell
# from repo root, after 'npm run dev' in backend (port 5001)
cd frontend
flutter run -d chrome --web-port=5555
```

In the Chrome devtools Device Toolbar, test both breakpoints:

- **Mobile — 390 × 844** (iPhone 14 Pro) — below the 900px cut, exercises
  bottom-nav, FAB, sheets, compact headers, mobile AppBar.
- **Desktop — 1440 × 900** — exercises sidebars, desktop top-bars, split-view
  chat, admin console, wide tables.

### Physical mobile (localtunnel)

```powershell
# start backend + tunnel per veto-architecture.mdc
cd backend
npm run dev:urls   # prints the dart-define line to copy
# then from frontend:
flutter run --dart-define=VETO_HOST=<PC_LAN_IP>
# or via tunnel:
flutter run --dart-define=VETO_HOST=sweet-turkey-60.loca.lt
```

All HTTP to `*.loca.lt` must send `bypass-tunnel-reminder: true` — this is
already handled by `AppConfig.httpHeaders` / `httpHeadersBinary`. Do not add
new HTTP callsites that bypass these helpers.

## Automated pre-gate

Before starting the manual sweep, these must be green:

```powershell
cd frontend
flutter analyze            # must say: "No issues found!"
flutter test               # must say: "All tests passed!"
```

If either fails, stop and fix before QA-ing visuals.

## Global checks (apply to every screen)

For every screen run through this short list before tile-by-tile QA:

- [ ] **Tokens** — no raw hex colors, no literal sizes that don't match V26
      constants (`V26.paper`, `V26.navy600`, `V26.ink700`, `V26.hairline`,
      `V26.rPill` / `V26.rMd` / `V26.rLg`, etc.)
- [ ] **RTL** — Hebrew layout mirrors correctly; no cut-off text; icons that
      imply direction (back arrow, chevrons) flip with `AppLanguage.directionOf`
- [ ] **Font scaling 200%** — no clipped UI, no tap targets shrink below 44×44
- [ ] **Focus visible** — tab through interactive elements; focused element
      shows a clear outline (keyboard on desktop web, switch control on mobile)
- [ ] **Touch targets** — every tappable element is ≥ 44×44 px in mobile
- [ ] **Empty / loading / error** — each state renders without overflow or
      unintended fallback text
- [ ] **Contrast** — WCAG AA — text on tinted pill backgrounds, hover states,
      and dark surfaces pass
- [ ] **Hover / active** — on desktop web, interactive elements have clear
      hover and active states (not identical to rest)

## Per-screen matrix (27 screens)

Legend: **M** = mobile 390, **D** = desktop 1440, **P** = physical device.
Check when done. Notes column → use `frontend/test/` goldens only if visual
regression spotted.

### Auth & Entry (3)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 1 | Splash                    | `2026/splash.html`   | [ ] | [ ] | [ ] | Logo proportion, tagline fade-in |
| 2 | Landing                   | `2026/landing.html`  | [ ] | [ ] | [ ] | Hero → Features → Stats → Stack → Pricing → CTA → Footer order |
| 3 | Login Wizard              | `2026/login.html`    | [ ] | [ ] | [ ] | OTP pinput, role select, RTL phone field |

### Citizen Core (2)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 4 | Citizen Home (VetoScreen) | `2026/citizen.html`  | [ ] | [ ] | [ ] | SOS button proportion, 6 scenario chips |
| 5 | Wizard Shell              | `2026/wizard.html`   | [ ] | [ ] | [ ] | Progress bar + step transitions |

### Lawyer Core (2)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 6 | Lawyer Dashboard          | `2026/lawyer.html`   | [ ] | [ ] | [ ] | **Desktop: sidebar visible**, availability toggle, 4 stat cards, emergency call list with pulsing red pill |
| 7 | Lawyer Settings           | `2026/lawyer.html#s` | [ ] | [ ] | [ ] | Schedule grid, specialization chips |

### Communication (4)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 8 | Chat                      | `2026/communication.html` | [ ] | [ ] | [ ] | **Desktop: conversations list on the side**, AI hint bubble, composer |
| 9 | Call Entry                | `2026/communication.html` | [ ] | [ ] | [ ] | Lawyer picker, call type toggle |
| 10 | Voice Call               | `2026/communication.html` | [ ] | [ ] | [ ] | **Dark surface** (V26DarkSurface), mute/end controls centered |
| 11 | Video Call (Agora)       | `2026/communication.html` | [ ] | [ ] | [ ] | **Dark surface**, peer video fills, local PIP |

### Vault & Evidence (4)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 12 | Files Vault              | `2026/vault.html`    | [ ] | [ ] | [ ] | Grid with file icons + badges, storage indicator bar |
| 13 | Shared Vault             | `2026/vault.html`    | [ ] | [ ] | [ ] | **Desktop two-column**, mobile tabs, "נסגר אוטומטית 30 יום" notice |
| 14 | Evidence Camera          | `2026/vault.html`    | [ ] | [ ] | [ ] | **Dark UI**, viewfinder, GPS + timestamp overlay, shutter, mode switcher |
| 15 | Maps                      | `2026/vault.html`    | [ ] | [ ] | [ ] | Marker clusters, recent locations bottom sheet |

### Legal Tools (3)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 16 | Legal Calendar           | `2026/legal-tools.html` | [ ] | [ ] | [ ] | Month grid + event pills, RTL week order |
| 17 | Legal Notebook           | `2026/legal-tools.html` | [ ] | [ ] | [ ] | Enterprise look — sidebar of notes + editor |
| 18 | Legal Document           | `2026/legal-tools.html` | [ ] | [ ] | [ ] | Privacy/Terms; long-form readable typography |

### Settings & Profile (2)

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 19 | Profile                   | `2026/settings.html` | [ ] | [ ] | [ ] | Avatar, subscription status card |
| 20 | Settings                  | `2026/settings.html` | [ ] | [ ] | [ ] | **Desktop: category sidebar + content**, mobile accordion, "אזור מסוכן" with red border |

### Admin Console (7) — all use `AdminShell`

| # | Screen                    | Mockup               | M | D | P | Notes |
| - | ------------------------- | -------------------- | - | - | - | ----- |
| 21 | Admin Dashboard          | `2026/admin.html`    | [ ] | [ ] | [ ] | **Sidebar + top-bar w/ Production/Staging**, 4 KPI cards, activity feed + health panel |
| 22 | All Users                | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=users, add user FAB |
| 23 | All Lawyers              | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=lawyers, add lawyer FAB, available/unavailable badges |
| 24 | Pending Lawyers          | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=pending, approve/reject inline |
| 25 | Emergency Logs           | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=logs, status change dropdown |
| 26 | Subscriptions            | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=subscriptions, TabBar (Users / Login log) below top-bar |
| 27 | Admin Settings           | `2026/admin.html`    | [ ] | [ ] | [ ] | AdminShell active=settings, danger-zone with red border |

## Cross-cutting regression checks

Run these end-to-end scenarios once per release candidate:

- [ ] **Citizen SOS flow**: Splash → Login (as citizen) → VetoScreen → press
      SOS → dispatch view → cancel dispatch. Verify push notification dot
      updates on admin dashboard.
- [ ] **Lawyer accept flow**: Sign in as lawyer → toggle Available → receive
      emergency in list → accept → land on chat screen with citizen.
- [ ] **Admin Prod/Staging**: Log in as admin (+972525640021) → open Admin
      Dashboard → switch Production/Staging in top-bar → nav to Users → env
      selector state persists across sidebar navigation.
- [ ] **Language switch**: Any screen → open language menu (HE / EN / RU) →
      layout + direction updates without crash; RTL-only elements flip.
- [ ] **Logout**: Profile / Admin Settings → Logout → returns to Splash and
      clears `jwt` + `veto_role` from secure storage.

## Release gate

A release is blocked until:

1. `flutter analyze` reports **No issues found!**
2. `flutter test` reports **All tests passed!**
3. Every screen row above has at least the **M** and **D** columns checked.
4. All 5 cross-cutting scenarios are checked.
5. No console errors in Chrome devtools (Network + Console tabs) during the
   scenarios above.

If any gate item fails, file a ticket in the `VET` Linear team and reference
the screen row it maps to.
