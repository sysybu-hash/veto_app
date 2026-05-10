# VETO web-client — Playwright E2E

End-to-end tests for the rewritten call surface (`/call/[channel]/_v2`)
plus the SOS → call → vault flow exercised by the citizen hub.

## Quick start

```bash
# from repo root
cd web-client
npm install -D @playwright/test
npx playwright install --with-deps chromium firefox webkit
NEXT_PUBLIC_CALL_V2=1 npm run build && npm start &
npx playwright test
```

The suite expects a running backend at the URL in
`NEXT_PUBLIC_API_BASE` (defaults to `http://localhost:5001` in dev).

## Files

- `playwright.config.ts` — projects: `chromium-desktop`, `webkit-mobile`.
- `specs/sos-call-vault.spec.ts` — happy path:
  citizen logs in, presses SOS, lawyer accepts, both join `_v2`,
  citizen ends call, vault auto-saves a new evidence row.
- `fixtures/auth.ts` — programmatic OTP login that hits the dev OTP
  endpoint (`RETURN_OTP_IN_JSON=1`) so we don't need real SMS.

## Why minimal?

Real call testing needs Agora keys, two browsers, and a microphone /
camera mock — out of scope for CI's first iteration. The scaffolding
here is the smallest setup the team needs to flip on; once tokens and
media mocks are wired (`fakeUserMedia` Chrome flag) the spec runs on
every PR.
