# VETO Legal — Release readiness

Use this alongside [QA_CHECKLIST.md](QA_CHECKLIST.md) before calling a build “production ready”.  
**Fill in bracketed placeholders** for your org; legal text in the app is a **draft** — get counsel sign-off.

## Production URL and clients

| Item | Value / note |
|------|----------------|
| **API origin (Render)** | Use the **Public URL** from the Render service page (e.g. `https://veto-app-new.onrender.com`) — must match [AppConfig](../frontend/lib/config/app_config.dart), `VETO_API_BASE` in CI, and `PUBLIC_API_BASE` if set. See [ENV_GUIDE — Render, URL](../backend/ENV_GUIDE.md#9-render). |
| **Web (Vercel)** | e.g. `https://…vercel.app` — same product, static `frontend/build/web`. |
| **Single API service** | Only **one** live Render web service for this product; duplicate services cause wrong endpoints. |

## Monitoring and ops

| Item | Note |
|------|------|
| **Sentry** | `SENTRY_DSN` in Render if you use [backend instrument](../backend/instrument.js). |
| **Health** | `GET /health` — `mongo: connected` after Atlas is up. |
| **Uptime (optional)** | External ping to `/health` (e.g. UptimeRobot) — not in repo. |
| **MongoDB Atlas** | Network access allows Render; backups per Atlas plan. |
| **On-call / owner** | **\[Name / channel\]** |

## Known product limits

- **Render Free**: cold start after ~15 min idle; first request can take 30–60s.
- **Committed web build**: after **any** Dart change, run `npm run ship:web` from repo root and commit `frontend/build/web` (see [root package.json](../package.json)).

## P0 risks (template)

| Risk | Mitigation |
|------|------------|
| Wrong API URL in app or CI | Verify one Render URL; grep `onrender.com` / `VETO_API_BASE`. |
| Atlas not reachable | `MONGO_URI` format; IP allowlist. |
| Web build stale | `ship:web` + commit after Flutter changes. |
| Legal copy | Replace drafts in [legal_document_screen.dart](../frontend/lib/screens/legal_document_screen.dart); operator + counsel own the text. |

## Out of scope for this document

- SMS/OTP configuration — operator responsibility.
- ISO/HIPAA — separate compliance program if required.
