# Call QA matrix (manual)

Run after backend (Render) and web bundle (Vercel) updates that touch Agora or `CallSessionController`.

## Preconditions

- HTTPS production URL (or localhost) for web video; HTTP non-localhost will show the in-app “secure context” message instead of starting media.
- Two accounts (e.g. citizen + lawyer) and a real or staging event with a valid `eventId` for token refresh.

## Matrix

| Client | Join | Remote video | Local PIP (web) | Mic mute | Tab refresh mid-call | 30s background |
|--------|------|----------------|-----------------|----------|------------------------|----------------|
| Chrome (desktop) |  |  |  |  |  |  |
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
