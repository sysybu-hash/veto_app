# VETO — release QA checklist

Use after stabilization changes or before tagging a release.

**Also read:** [RELEASE_READINESS.md](RELEASE_READINESS.md) (URLs, risks, ops) · [CALL_QA_MATRIX.md](CALL_QA_MATRIX.md) · [LEGAL_REVIEW_PACKAGE.md](LEGAL_REVIEW_PACKAGE.md).

## Stack boundaries (current SoT)

| Area | Server (Node) | Web (`web-client/` Next.js) | Mobile (`mobile/` Expo) |
|------|---------------|-----------------------------|-------------------------|
| Auth / sessions | `backend` JWT + `/api/*` | `/login`, cookies, passkeys | OTP login (WIP) |
| Real-time SOS | `socket.io` + `dispatch.socket` | Hub + lawyer dashboard | SOS + accept (WIP) |
| Agora calls | Tokens + call routes | `CallShell` v2 | Agora path (WIP) |
| Vault / files | Express + storage | `/vault`, generator | Not yet |
| Calendar | CRUD + GCal + iCal + cron | `/calendar` (redesign) | Not yet |
| Push | VAPID web-push; Expo push; optional FCM | Service worker + VAPID | `expo-notifications` |
| Payments | PayPal orders/subscriptions/webhooks | `/plans`, `/pricing`, settings | Not yet |
| AI | Gemini routes | Chat / docs | Not yet |

**Legacy Flutter** (`frontend/`) is **frozen** — do not treat as release SoT.

### Release versions

| Part | Where |
|------|--------|
| Web | `web-client/package.json` |
| API | `backend/package.json` |
| Mobile | `mobile/app.json` / `package.json` |

## Citizen (web)

- [ ] Login (OTP / Google)
- [ ] Hub SOS → searching overlay → lawyer found → call type → `/call/...`
- [ ] Hangup → citizen summary → back to hub **without** connecting overlay
- [ ] Vault upload / evidence list
- [ ] Calendar create/edit/delete (no mock events)
- [ ] Plans / consultation payment (PayPal)
- [ ] Settings billing CTAs

## Lawyer (web)

- [ ] Dashboard availability + GPS heartbeat
- [ ] Socket `new_emergency_alert` + web push deep-link (`eventId` with or without lat/lng)
- [ ] Accept → session → call
- [ ] Hangup → lawyer summary → `/dashboard`
- [ ] Admin approval gate for new lawyers

## Admin

- [ ] Admin login, lawyers approve/reject, emergency logs smoke

## API / infra

- [ ] `GET /health` → mongo connected
- [ ] CI: backend lint + test; web build verify
- [ ] Cron: `GET /api/cron/retry-pending-sos` (with `CRON_SECRET`)
- [ ] PayPal Live + webhook ID configured

## Mobile (internal only until parity)

- [ ] Expo login + SOS smoke
- [ ] Push registration (Expo token; no Firebase required)
- [ ] Documented as non-production in `mobile/README.md`
