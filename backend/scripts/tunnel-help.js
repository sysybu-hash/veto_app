#!/usr/bin/env node
// eslint-disable-next-line no-console -- CLI help
console.log(`
VETO — localtunnel (הכתובת הציבורית משתנה לעיתים)
=================================================

למה זה משתנה?
  שירותי טונל חינמיים (localtunnel וכו') מחלקים שמות מ-a לפי זמינות.
  גם כשמבקשים subdomain קבוע, מישהו אחר יכול להשתמש בו או השרת מחזיר שם אקראי.

רוצה משהו יציב יותר בלי לשלם?
  • אותה Wi‑Fi: הרץ  npm run dev:urls  והעתק  --dart-define=VETO_HOST=<ה-IP>
    (בבית / משרד זה הכי פשוט.)
  • מחוץ לרשת: ngrok בתשלום עם subdomain שמור, או Cloudflare Tunnel עם דומיין שלך.

==================
1) Terminal A (keep open):
     npm run dev
   Wait for: VETO Server running on port 5001

2) Terminal B (keep open):
     npm run tunnel
   Uses tunnel-run.js: real URL is printed. If localtunnel assigns something
   other than sweet-turkey-60.loca.lt, the script prints the exact
   `flutter run --dart-define=VETO_HOST=...` line to copy.

   OR: npm run tunnel:any
   → Random *.loca.lt via CLI
   → Use the printed hostname with --dart-define=VETO_HOST=...

   Legacy CLI: npm run tunnel:cli (same ambiguity as plain `lt`)

3) Flutter already sends header: bypass-tunnel-reminder: true on REST + socket (loca.lt).

4) If you open *.loca.lt in Chrome/Safari, localtunnel may show a “Continue” page.
   That is normal. Use the app for API, or add a browser extension to inject the header.
   See GET / JSON field "localtunnel" in development for hints.
`);
