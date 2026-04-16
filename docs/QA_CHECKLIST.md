# VETO — release QA checklist

Use after stabilization changes or before tagging a release.

## Citizen

- [ ] Login / OTP (dev: OTP in backend terminal)
- [ ] AI legal chat (authenticated); rate-limit friendly message if spamming
- [ ] Dispatch from VETO screen → `emergency_created` → `veto_dispatched`
- [ ] Lawyer accepts → `lawyer_found` → navigate to call with correct call type
- [ ] Call connect (audio/video), mute/camera toggles
- [ ] End call from **citizen** → lawyer returns to **available** in dashboard
- [ ] Cancel veto before accept → lawyers dismissed

## Lawyer

- [ ] Dashboard online + availability toggle
- [ ] Receive `new_emergency_alert` (socket + push if configured)
- [ ] Accept race: second lawyer gets `case_already_taken`
- [ ] Reject / ignore alert (dispatch log updated)
- [ ] End call from **lawyer** → self available again

## Admin

- [ ] Admin login, emergency logs, user/lawyer lists (smoke)

## API / infra

- [ ] `GET /health` → `mongo: connected` on deployed API
- [ ] Recording upload then transcribe with **only** `recording_url` (server fetches audio)
- [ ] CI: backend `npm run lint` + `npm test`; frontend `flutter test` + analyze gate

## Analyzer

Run locally: `flutter analyze`.

CI now runs strict `flutter analyze`, so analyzer cleanliness is a hard release gate.
