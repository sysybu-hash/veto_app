# `mobile/` — VETO Expo Client (work-in-progress)

Replacement for [`frontend/`](../frontend/) (Flutter, frozen). Stack:

- Expo SDK 54 + React Native 0.81
- NativeWind for styling (matches the web client's Tailwind tokens)
- Same backend as [`web-client/`](../web-client/) — see [`backend/ENV_GUIDE.md`](../backend/ENV_GUIDE.md)

## Status

Scaffold only. Do not point production users here. The web client is the canonical client until parity is reached.

## Why two mobile trees exist

`frontend/` (Flutter) is the historical client and stays frozen as the source of truth for the legacy mobile UX (Hebrew strings, Cloudinary recording flow, Agora 6.6.x). `mobile/` (Expo) is the green-field replacement that will share types and API contracts with `web-client/`.

When `mobile/` reaches parity, `frontend/` will be archived to a tagged release and removed. Until then, neither tree should be deleted.
