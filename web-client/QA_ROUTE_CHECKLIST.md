# VETO web-client — QA route checklist (polish pass)

Use: RTL · mobile · desktop · theme light (`veto-light`) · theme dark (`veto-dark`) · keyboard focus · contrast.

## Marketing / guest

| Route | Notes |
|-------|--------|
| `/` | Landing, CTA, nav |
| `/pricing` | Cards, links |
| `/register` | Forms |
| `/register/lawyer` | Forms |
| `/terms`, `/privacy`, `/cookies` | Long prose, links |
| `/payments/return` | Status states |

## Citizen

| Route | Notes |
|-------|--------|
| `/hub` | SOS, dialogs, bottom nav padding |
| `/chat` | Messages, input, FAB overlap |
| `/vault` | Lists, upload modal |
| `/calendar` | Events, create modal |
| `/settings` | Shell + sub-routes |
| `/settings/profile` | Forms |
| `/settings/security` | Passkey / OTP |
| `/settings/notifications` | Toggles |
| `/settings/billing` | Pay flow |
| `/plans`, `/family` | Subscription UI |
| `/productivity` | Tasks, modals |
| `/onboarding` | Steps |
| `/transparency`, `/privacy-rights` | Static / forms |

## Lawyer

| Route | Notes |
|-------|--------|
| `/dashboard` | SOS queue, cards |

## Admin

| Route | Notes |
|-------|--------|
| `/admin`, `/admin/dashboard` | `.veto-admin-keep-dark` |
| `/admin/lawyers`, `/admin/vault`, `/admin/settings` | Tables / forms |
| `/admin/users/[id]` | Detail |

## Special

| Route | Notes |
|-------|--------|
| `/login` | Auth glass |
| `/call/[channel]` | `.veto-call-keep-dark`, controls |
| `/vault/generator` | Long form, bottom nav |
| `/~offline` | Offline message |

## Global chrome

- `UniversalNav`, `CitizenBottomNav`, `GlobalAiOverlay`, `CookieConsent`, `ToastHost`, `ThemeToggle`

## PWA / Service worker (technical source of truth)

- **Active service worker:** `/sw.js` — produced at build by `@ducanh2912/next-pwa` ([`next.config.mjs`](web-client/next.config.mjs): `dest: "public"`, `customWorkerSrc: "worker"`). Web Push handlers live in [`worker/index.ts`](web-client/worker/index.ts) and are merged into that bundle.
- **Registration:** [`pushClient.ts`](web-client/src/lib/pushClient.ts) registers `/sw.js` (not a second filename).
- **Offline document:** App Router [`/~offline`](web-client/src/app/~offline/page.tsx) via next-pwa `fallbacks.document`.
- **Legacy:** `public/custom-sw.js` was removed — it was not referenced anywhere; a second SW file would confuse updates and cache busting. When bumping the logo or shell assets, bump cache keys in the **generated** PWA pipeline / workbox config if needed, and keep [`VetoBrandLogo`](web-client/src/components/brand/VetoBrandLogo.tsx) query string in sync with any precache list you add.

## Closure matrix (Definition of Done)

| Dimension | What to verify |
|-----------|----------------|
| **RTL** | `dir="rtl"` pages: scroll, modals, toasts, FAB not clipped; logical padding/margins. |
| **Light (`veto-light`)** | No dark-only text (`text-slate-100` on light canvas); cards readable; marketing/legal pages. |
| **Dark (`veto-dark`)** | `dark:` surfaces; admin/call keep-dark wrappers unchanged. |
| **Keyboard** | `Tab` through nav, forms, modals; `Escape` closes dialogs where implemented; `focus-visible` rings on buttons/links (`globals.css` + `focusRing` in `vetoGlass`). |
| **Touch** | Primary actions ≥ ~44px height (e.g. call `ControlBar`, OTP resend, offline retry). |
| **Contrast** | Secondary text `text-slate-600` / `dark:text-slate-400`; errors `red-700` / `dark:red-300`; success green tuned for light+dark. |

## Modals and overlays (code audit snapshot)

- **Documented dialogs:** `VaultUploadModal`, `CreateTaskModal`, `CreateEventModal`, `SpecializationDialog`, `UniversalNav` mobile menu, productivity contract modals (backdrop + Escape + `aria-modal` on panel), `GlobalAiOverlay` panel uses `role="dialog"` with `aria-modal="false"` because the shell stays interactable (`pointer-events-none` root) — intentional.
- **AI FAB:** `GlobalAiOverlay` trigger is `h-16 w-16` (meets ~44px touch target).
- **Service worker:** see **PWA / Service worker** above; production path is `/sw.js` only.
