# VETO Legal — Release readiness

Use this alongside [QA_CHECKLIST.md](QA_CHECKLIST.md) before calling a build “production ready”.  
**Fill in bracketed placeholders** for your org; legal text in the app is a **draft** — get counsel sign-off.

## Production URL and clients

| Item | Value / note |
|------|----------------|
| **API origin (Render)** | Public URL from Render (e.g. `https://veto-app-new.onrender.com`) — must match `NEXT_PUBLIC_API_ORIGIN`, CI `VETO_API_BASE`. See [ENV_GUIDE](../backend/ENV_GUIDE.md#9-render). |
| **Web (Vercel)** | Deploy **`web-client/`** (Next.js). Flutter `frontend/` is frozen legacy. |
| **Single API service** | Only **one** live Render web service for this product. |

## Monitoring and ops

| Item | Note |
|------|------|
| **Sentry** | `SENTRY_DSN` on Render + `NEXT_PUBLIC_SENTRY_DSN` on Vercel. |
| **Health** | `GET /health` — `mongo: connected` after Atlas is up. |
| **Uptime (recommended)** | External monitor (UptimeRobot / Better Stack) pinging `GET /health` every 1–5 min — complementary to repo `keepalive.yml`. |
| **TURN** | Configure `WEBRTC_ICE_SERVERS_JSON` or `TURN_URL` + credentials ([ENV_GUIDE](../backend/ENV_GUIDE.md)) for reliable WebRTC behind strict NAT. |
| **MongoDB Atlas** | Network access allows Render; backups per Atlas plan. |
| **Neon** | `DATABASE_URL` on Vercel; run `prisma migrate deploy` after schema changes. |
| **On-call / owner** | **\[Name / channel\]** |

## Known product limits

- **Render Free**: cold start after ~15 min idle; first request can take 30–60s. (**Upgrade deferred** — operator decision.)
- Twilio SMS / PayPal Live / Admin fixed-OTP harden — **deferred**; see [DEPLOY.md](../DEPLOY.md) operator checklist.

## P0 risks (template)

| Risk | Mitigation |
|------|------------|
| Wrong API URL in app or CI | Verify one Render URL; grep `onrender.com` / `NEXT_PUBLIC_API_ORIGIN`. |
| Atlas not reachable | `MONGO_URI` format; IP allowlist. |
| Vault orphans | Cloudinary delete via `/api/vault/delete-remote`; fail closed in prod. |
| Legal copy | Draft banners on `/terms` `/privacy` until counsel — [LEGAL_REVIEW_PACKAGE.md](LEGAL_REVIEW_PACKAGE.md). |

## Out of scope for this document

- SMS/OTP Twilio configuration — deferred / operator.
- PayPal Live + Render paid plan — deferred / operator.
- ISO/HIPAA — separate compliance program if required.
