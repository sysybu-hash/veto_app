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

## Manual test session — 2026-07-27 (Chrome desktop, citizen + lawyer, real 2-account call)

- **Join + remote video: OK.** Both sides connected and saw each other's video.
- **Bug found & fixed**: on call end, the **lawyer** was redirected to `/hub` (the citizen's screen) instead of `/dashboard`. Root cause: `CallShell.tsx`'s `endCall`/`closeSummary`/no-session-fallback all hardcoded `router.replace("/hub")` regardless of `myRole`. Fixed by routing to `myRole === "lawyer" ? "/dashboard" : "/hub"` in all three places (commit pending push).
- **Additional bugs reported, not yet triaged**: user recorded a video of the session (lawyer side) showing further issues beyond the redirect — not yet itemized in this matrix. Follow up needed to extract concrete repro steps per issue.
- **Call UI redesign requested**: user flagged the call screens as needing a visual redesign — tracked as a separate design task, not a QA regression.
- **Still untested**: Edge, Firefox, Safari (macOS/iOS), Chrome (Android); Local PIP, Mic mute, Tab refresh mid-call, 30s background — none of these were covered by this session.
