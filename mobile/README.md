# `mobile/` — VETO Expo Client (work-in-progress)

Replacement for [`frontend/`](../frontend/) (Flutter, frozen). Stack:

- Expo SDK 54 + React Native 0.81
- NativeWind for styling (matches the web client's Tailwind tokens)
- Same backend as [`web-client/`](../web-client/) — see [`backend/ENV_GUIDE.md`](../backend/ENV_GUIDE.md)

## Status

**WIP — not for production users yet**, but SOS path is wired:

| Feature | Status |
|---------|--------|
| OTP login + roles | Working |
| Citizen SOS over Socket.io | Working |
| Lawyer queue + accept + Agora | Working |
| Location heartbeat (lawyer) | Working (`PUT /lawyers/location`) |
| Push registration | `expo-notifications` → `POST /users/fcm-token` → backend `expoPush.service` (**no Firebase required** for Expo tokens). Set `FIREBASE_SERVICE_ACCOUNT` only for legacy FCM tokens. |

Canonical clients today:

| Surface | Path | Status |
|---------|------|--------|
| Web product | [`web-client/`](../web-client/) | **Source of truth** — ship here |
| API | [`backend/`](../backend/) | Active |
| Flutter legacy | [`frontend/`](../frontend/) | Frozen — do not extend |
| This Expo app | `mobile/` | SOS + push registration in progress |

## Why two mobile trees exist

`frontend/` (Flutter) is the historical client and stays frozen as the source of truth for the legacy mobile UX (Hebrew strings, Cloudinary recording flow, Agora 6.6.x). `mobile/` (Expo) is the green-field replacement that will share types and API contracts with `web-client/`.

When `mobile/` reaches parity, `frontend/` will be archived to a tagged release and removed. Until then, neither tree should be deleted.
