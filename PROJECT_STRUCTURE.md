# VETO – Project Structure

> Last synced with: `frontend/lib/main.dart` (`vetoAppRoutes`), `frontend/lib/**` navigation grep, and `backend/server.js` mounts.

## Overview

```
veto_legal/
├── frontend/     ← Flutter (mobile + web)
├── backend/        ← Node.js + Express + Socket.io
├── docs/           ← e.g. QA checklists
├── package.json     ← root scripts (dev, tunnel, ship:web, e2e)
└── PROJECT_STRUCTURE.md
```

---

## Frontend — `lib/`

### Entry & global wiring

| File | Role |
|------|------|
| [lib/main.dart](frontend/lib/main.dart) | `VetoApp`, `vetoAppRoutes`, providers (`AppLanguage`, `AccessibilitySettings`, `VaultSaveQueue`, `SocketService`), backend warm-up |
| [lib/app_navigator.dart](frontend/lib/app_navigator.dart) | `vetoRootNavigatorKey` for tests / global navigation |
| [lib/config/app_config.dart](frontend/lib/config/app_config.dart) | Base URL, headers (incl. localtunnel bypass) |

### Services (`lib/services/`)

| File | Role |
|------|------|
| `auth_service.dart` | OTP / JWT, logout, role routing |
| `socket_service.dart` | Socket.io: dispatch, session ready, chat-adjacent events |
| `agora_service.dart` | Agora RTC engine (join/leave, video) |
| `call_api_service.dart` | REST helpers for call flow |
| `ai_service.dart` | Legal AI / Gemini integration (client) |
| `admin_service.dart` | Admin API helpers |
| `upload_service.dart` | Evidence / media upload |
| `payment_service.dart` | Payments / subscription client |
| `vault_save_queue.dart` | Local queue for vault saves |
| `vault_payload_compress.dart` | Payload compression for vault |
| `webrtc_service.dart` | WebRTC (non-Agora paths where used) |
| `webrtc_ice_config_service.dart` / `webrtc_settings_store.dart` / `webrtc_user_settings.dart` | ICE / settings |
| `call_recording_service.dart` + `_web` / `_stub` | Call recording (platform split) |
| `push_service.dart` + `_web` / `_stub` | Web push / stubs |

### Core

- `lib/core/i18n/app_language.dart` — locale controller (he / en / ru)
- `lib/core/accessibility/accessibility_settings.dart` — text scale, contrast, motion
- `lib/core/theme/veto_2026.dart` — VETO 2026 design tokens (`V26`), `V26Backdrop`, `V26Card`, shared painters; `veto_theme.dart` — `ThemeData`; `future_surface.dart` — named surfaces (`FutureBackdrop`, `GlassPanel`) aligned with V26

### Platform & Web

- `lib/platform/browser_bridge*.dart` — web/native bridges (e.g. evidence pickers)
- `lib/platform/maps_embed_*.dart` — embedded maps (web/stub)

### Notable screen modules

- `lib/screens/veto/veto_screen_models.dart` — types/helpers for [veto_screen.dart](frontend/lib/screens/veto_screen.dart)
- `lib/widgets/` — `ai_chat_dialog`, `dispatch_sheets`, `app_language_menu`, `accessibility_toolbar`

---

## Navigation

### A. Named routes (single table — `vetoAppRoutes` in [main.dart](frontend/lib/main.dart))

| Route | Screen widget |
|-------|----------------|
| `/` | `SplashScreen` |
| `/landing` | `LandingScreen` |
| `/login` | `LoginScreen` |
| `/wizard_home` | `WizardShellScreen` |
| `/veto_screen` | `VetoScreen` |
| `/lawyer_dashboard` | `LawyerDashboard` |
| `/profile` | `ProfileScreen` |
| `/admin_settings` | `AdminSettingsScreen` |
| `/files_vault` | `FilesVaultScreen` |
| `/legal_calendar` | `LegalCalendarScreen` |
| `/legal_notebook` | `LegalNotebookScreen` |
| `/admin_dashboard` | `AdminDashboard` |
| `/admin_subscriptions` | `SubscriptionAdminScreen` |
| `/settings` | `SettingsScreen` |
| `/admin_users` | `AllUsersScreen` |
| `/admin_lawyers` | `AllLawyersScreen` |
| `/admin_pending` | `PendingLawyersScreen` |
| `/admin_logs` | `EmergencyLogsScreen` |
| `/lawyer_settings` | `LawyerSettingsScreen` |
| `/chat` | `ChatScreen` |
| `/call` | `CallEntryScreen` (see B below) |
| `/maps` | `MapsScreen` |
| `/shared_vault` | `SharedVaultScreen` |
| `/privacy` | `LegalDocumentScreen` (privacy) |
| `/terms` | `LegalDocumentScreen` (terms) |

### B. `/call` (CallEntryScreen) — no extra named route

[call_entry_screen.dart](frontend/lib/screens/call_entry_screen.dart) branches on arguments:

- `callType == 'chat'` → [CallScreen](frontend/lib/screens/call_screen.dart) (WebRTC / “chat room” path)
- Otherwise (typ. audio/video) → [AgoraCallScreen](frontend/lib/screens/agora_call_screen.dart) with `channelId`, token, `wantVideo`, etc.
- Invalid/missing args → `pushReplacementNamed('/veto_screen')`

Pushed to `/call` with a `Map` of arguments from:

- [VetoScreen](frontend/lib/screens/veto_screen.dart) (`_handleSessionReady`: socket `sessionReady`)
- [LawyerDashboard](frontend/lib/screens/lawyer_dashboard.dart) (socket: lawyer session + `onSessionReady`)
- [WizardShellScreen](frontend/lib/screens/wizard/wizard_shell_screen.dart) (socket `onSessionReady`)

### C. MaterialPageRoute (not in `vetoAppRoutes`)

| Pushed from | Target |
|-------------|--------|
| [VetoScreen](frontend/lib/screens/veto_screen.dart) `_openCamera` (after API session) | `EvidenceScreen` (params: `eventId`, `token`, `language`) |
| [AdminSettingsScreen](frontend/lib/screens/admin_settings_screen.dart) | `PendingLawyersScreen`, `AllUsersScreen`, `AllLawyersScreen`, `EmergencyLogsScreen` (same classes as named routes; stack is explicit `MaterialPageRoute` here) |

> **Note:** Admin user-management screens are reachable both via **named routes** (e.g. from [AdminDashboard](frontend/lib/screens/admin_dashboard.dart) sidebar) and via **inline push** from admin settings; behavior is the same screens, different navigation history shape.

### D. High-level auth / role routing (pushReplacement / pushNamed)

- [SplashScreen](frontend/lib/screens/splash_screen.dart): `pushReplacementNamed` → `/landing`
- [LoginScreen](frontend/lib/screens/login_screen.dart) after success: `pushReplacementNamed` → `/lawyer_dashboard` (lawyer) | `/admin_settings` (admin) | `/veto_screen` (citizen)
- [AuthService](frontend/lib/services/auth_service.dart): logout can `pushReplacementNamed` → `/login`
- [LandingScreen](frontend/lib/screens/landing_screen.dart): CTA to `/login` or role-specific home
- [LawyerDashboard](frontend/lib/screens/lawyer_dashboard.dart): non-lawyer/non-admin → `pushReplacementNamed` → `/veto_screen`
- [VetoScreen](frontend/lib/screens/veto_screen.dart): lawyer in wrong surface → can `pushReplacementNamed` → `/lawyer_dashboard`
- [CallEntryScreen](frontend/lib/screens/call_entry_screen.dart) / [CallScreen](frontend/lib/screens/call_screen.dart): on exit paths → `pushReplacementNamed` → `/veto_screen`
- [SettingsScreen](frontend/lib/screens/settings_screen.dart) / [LawyerSettingsScreen](frontend/lib/screens/lawyer_settings_screen.dart): “logout to splash” style flows use `pushNamedAndRemoveUntil` → `/`

### E. Admin dashboard sidebar (all `pushNamed`)

From [admin_dashboard.dart](frontend/lib/screens/admin_dashboard.dart) `navItems` targets: `/admin_dashboard`, `/admin_users`, `/admin_lawyers`, `/admin_pending`, `/admin_logs`, `/admin_subscriptions`, `/admin_settings`.

---

## Backend (Node.js + Express + Socket.io)

```
backend/
├── server.js                 ← HTTP app, CORS, `/api/*` mounts, `/health`, static `/uploads`
├── package.json
├── .env                      ← MongoDB, JWT, providers (not committed secrets in repo)
└── src/
    ├── config/               db.js, cloudinary, gemini, etc.
    ├── models/               User, Lawyer, EmergencyEvent, Message, vault models, …
    ├── routes/               auth, users, lawyers, events, admin, ai, payments, chat, vault, call
    ├── controllers/
    ├── middleware/           auth, error
    ├── services/            gemini, push, PayPal, vault mirror, …
    └── socket/               dispatch.socket.js, webrtc.socket.js
```

**Mounted API surface** (from `server.js`; all under `/api/…` except discovery):

- `/api/auth` — OTP / JWT
- `/api/users`, `/api/lawyers`, `/api/events`
- `/api/push/vapid-key` — VAPID public key for web push
- `/api/admin`
- `/api/ai`
- `/api/payments`
- `/api/chat`
- `/api/vault`
- `/api/calls`

`GET /health` — liveness. `GET /` and `GET /api` — API discovery / metadata.

---

## Root npm scripts (see [package.json](package.json))

| Script | Purpose |
|--------|---------|
| `npm run dev` / `start` | Backend dev / production start (`backend/`, default port 5001) |
| `npm run tunnel` / `tunnel:any` / `tunnel:help` | localtunnel helpers for mobile |
| `npm run dev:urls` | Print LAN + Flutter `--dart-define` hint |
| `npm run build:web` / `ship:web` | Flutter web build + Vercel prebuild check |
| `npm run e2e:flutter` | Flutter e2e tests under `frontend/test/` |

`backend/package.json` adds: `init-admins`, `lint`, `test`, `free-5001`, `dev:clean`.
