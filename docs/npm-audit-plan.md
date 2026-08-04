# npm audit plan (P2)

Do **not** run `npm audit fix --force` on production branches without E2E.

| Area | Known chain | Next step |
|------|-------------|-----------|
| `backend` firebase-admin (optional) | Only if `FIREBASE_SERVICE_ACCOUNT` used | Bump when enabling FCM; retest Expo path |
| `web-client` Next / transitive | Pin via Dependabot PRs | Run Call QA matrix after Next minor bumps |
| `mobile` Expo | SDK-aligned only | `npx expo install` after SDK upgrade |

Record audit date in release notes when a bump ships.
