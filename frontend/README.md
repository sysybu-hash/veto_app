# `frontend/` — VETO Flutter Client (LEGACY / FROZEN)

> **Status: 🧊 frozen. Do not add new features here.**
> The active web client lives in [`web-client/`](../web-client/) (Next.js 16). The active backend lives in [`backend/`](../backend/) (Node.js + Socket.io on Render).
>
> This Flutter app is preserved as the historical mobile reference (Cloudinary recording flow, Agora 6.6.x integration, Hebrew UI strings). Don't delete it without first porting any still-needed flow into [`mobile/`](../mobile/) (Expo) or `web-client`.
>
> **Do not** run `flutter pub upgrade` here — the `flutter_secure_storage_windows ^4.1.0` ↔ `agora_rtc_engine 6.6.x` resolver conflict documented in `pubspec.yaml` will reappear.

## What's still here

- `lib/` — original Flutter source for the citizen + lawyer apps.
- `pubspec.yaml` — pinned dependency set; `flutter_secure_storage_windows: 4.0.0` is the workaround pin.
- `build/web/` — last shipped PWA build, served by Vercel via `npm run serve:web` from repo root for backwards compatibility links only.
- `test/` — `e2e_*_test.dart` integration tests, still runnable with `npm run e2e:flutter` from repo root.

## When in doubt

Use the web client. The mobile rewrite plan (Expo) lives in `mobile/` and inherits the same backend over HTTPS — see [`docs/MATRIX_2026_GAP.md`](../docs/MATRIX_2026_GAP.md) for the migration matrix.
