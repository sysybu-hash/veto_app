# Call QA matrix (manual)

Run after backend (Render) and web bundle (Vercel) updates that touch Agora or `CallSessionController`.

## Preconditions

- HTTPS production URL (or localhost) for web video; HTTP non-localhost will show the in-app “secure context” message instead of starting media.
- Two accounts (e.g. citizen + lawyer) and a real or staging event with a valid `eventId` for token refresh.

## Matrix

| Client | Join | Remote video | Local PIP (web) | Mic mute | Tab refresh mid-call | 30s background |
|--------|------|----------------|-----------------|----------|------------------------|----------------|
| Chrome (desktop) | OK (2026-07-27) | OK (2026-07-27) |  |  |  |  |
| Edge (desktop) |  |  |  |  |  |  |
| Firefox (desktop) |  |  |  |  |  |  |
| Safari (macOS) |  |  | n/a |  |  |  |
| Safari (iOS) |  |  | n/a |  |  |  |
| Chrome (Android) |  |  | n/a |  |  |  |

## Web-only

- Outbound **video** call: first screen must show **“Start video call”**; after tap, connecting should proceed (user-gesture policy).
- Insecure HTTP (non-localhost): expect **HTTPS / localhost** message, not a hung spinner.

## Regression targets

- No `UID_CONFLICT` loop after backend UID hash deploy.
- After token errors, capped automatic recovery; then Retry / Exit on hard failure.

Mark each cell **OK** or note the build / date and the failure symptom.

## Hangup / summary sync (regression)

| Check | Status |
|-------|--------|
| Citizen ends call → citizen summary (billing/vault) | Shipped `#53` |
| Peer receives `call-ended` → shows role summary (not stuck in-call) | Shipped `#53` |
| Lawyer summary has no pay/vault CTAs | Shipped `#53` |
| Close summary → hub without “Connecting your call…” overlay | Shipped `#53` |
| Chat-only also shows summary | Shipped `#53` |

## Manual test session — 2026-07-27 (Chrome desktop, citizen + lawyer, real 2-account call)

- **Join + remote video: OK.** Both sides connected and saw each other's video.
- **Bug found & fixed**: on call end, the **lawyer** was redirected to `/hub` instead of `/dashboard` — fixed via `postCallHome` by role.
- **2026-08-04 follow-up**: hangup sync + dual summaries shipped in `#53`. Re-verify on production after deploy.
- **Still untested**: Edge, Firefox, Safari (macOS/iOS), Chrome (Android); Local PIP, Mic mute, Tab refresh mid-call, 30s background.
