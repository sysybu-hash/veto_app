# VETO — release QA checklist

Use after stabilization changes or before tagging a release.

**Also read:** [RELEASE_READINESS.md](RELEASE_READINESS.md) (URLs, risks, ops).  
**After any Flutter/Dart change** that affects the web app: from repo root run `npm run ship:web` and commit updated `frontend/build/web` (Vercel serves prebuilt assets; see [DEPLOY.md](../DEPLOY.md)).

## Stack boundaries (where each layer lives)

| Area | Server (Node) | Client (Flutter/Dart) | Web-only JS (`frontend/web/`) |
|------|---------------|------------------------|--------------------------------|
| Auth, sessions, admin API | `backend` — JWT, `auth.middleware`, `/api/*` | Login, `AuthService`, admin screens | GIS token via `browser_bridge` (Flutter web) |
| Real-time dispatch | `socket.io` in `server.js` + `dispatch.socket` | `socket_service` (`socket_io_client` only) | — |
| Agora | Token + call routes in `backend` | `agora_rtc_engine` + `AgoraService` (public App ID only; token from API) | — |
| Files / vault / upload | Express + models + storage | `upload_service`, vault UI | — |
| AI (Gemini) | `POST /api/ai/chat`, `live-token` for browser session | `AiService` → `/ai/chat`; `AiChatDialog` | **Exception:** `gemini_live.mjs` + worklet: Multimodal Live in the browser; ephemeral token from `POST /api/ai/live-token` (no API key in the page). |
| Push, calendar, payments | FCM, cron, PayPal, calendar routes | Firebase Messaging, UI | `push-sw.js` (push SW if used) |
| PWA / static web | `backend` serves API; Render | Flutter build → `frontend/build/web` | `index.html`, `flutter_service_worker.js` (cache killer), TTS/bridge scripts as needed |

**Alignment audit (2026-04):** Grep of `frontend/lib` found no hardcoded Google/Gemini API keys; `firebase_options.dart` uses `replace-me` until configured. REST chat paths use `AiService` only; Gemini Live is the documented client exception.

### P0 stability (code triage, 2026-04-28)

Use this when debugging **PWA + native** “freezes” or “crashes” (see plan: both platforms).

| Symptom | Suspected code path | What we changed |
|--------|---------------------|-----------------|
| Tab unresponsive after web login (Flows) | `login_screen` already uses 8s timeout on `flowsSetUser`; `veto_screen` had unbounded retry | `_retryWebFlows` now uses **8s timeout**; failures are non-fatal. |
| “Frozen” right after opening `/veto_screen` | Subscription gate dialog + first socket frames | First **subscription** check delayed to **~650ms** after first frame (less contention with post-login paint). |
| Web: audio level | PCM in `gemini_live.mjs` | **Master `GainNode`** + prefs `VetoLiveAudioPrefs` (voice + gain); live token supports **allowlisted** `voiceName` on the server. |

**Manual follow-up (still required):** capture Chrome/Safari remote logs (PWA) and `logcat` / Xcode console (native) for OOM or Skia errors — not reproducible in CI.

### Release versions (bump when you ship)

| Part | Version / command |
|------|---------------------|
| App (Flutter) | `1.1.0+2` in `frontend/pubspec.yaml` |
| API (Node) | `1.1.0` in `backend/package.json` |
| Record exact toolchains | `node -v`, `npm -v`, `flutter --version` (paste into release notes) |

**Gemini Live voice:** `POST /api/ai/live-token` body may include `voiceName` (server allowlist: Kore, Puck, Charon, Fenrir, Zephyr, Aoede). Web `vetoGeminiLive.start` passes `(lang, jwt, baseUrl, voiceName, gain)`.

## Citizen

- [ ] Login / OTP (dev: OTP in backend terminal)
- [ ] AI legal chat (authenticated); rate-limit friendly message if spamming
- [ ] Dispatch from VETO screen → `emergency_created` → `veto_dispatched`
- [ ] Lawyer accepts → `lawyer_found` → navigate to call with correct call type
- [ ] Call connect (audio/video), mute/camera toggles
- [ ] End call from **citizen** → lawyer returns to **available** in dashboard
- [ ] Cancel veto before accept → lawyers dismissed

## Lawyer

- [ ] Dashboard online + availability toggle
- [ ] Receive `new_emergency_alert` (socket + push if configured)
- [ ] Accept race: second lawyer gets `case_already_taken`
- [ ] Reject / ignore alert (dispatch log updated)
- [ ] End call from **lawyer** → self available again

## Admin

- [ ] Admin login, emergency logs, user/lawyer lists (smoke)

## API / infra

- [ ] `GET /health` → `mongo: connected` on deployed API
- [ ] Recording upload then transcribe with **only** `recording_url` (server fetches audio)
- [ ] CI: backend `npm run lint` + `npm test`; frontend `flutter test` + analyze gate
- [ ] **Automated smoke (local/CI):** `cd frontend && flutter test` (includes route mount tests, including `/privacy` and `/terms`).

> Full **manual** exercises below require the **real production (or staging) web + API URL** — `flutter test` alone does not replace this.

## Analyzer

Run locally: `flutter analyze`.

CI now runs strict `flutter analyze`, so analyzer cleanliness is a hard release gate.
