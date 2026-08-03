# VETO — מבנה הפרויקט

## סקירה

```
veto_legal/
├── web-client/      ← Next.js (ווב ראשי — Vercel) — הפיתוח הפעיל
├── frontend/        ← Flutter — 🧊 קפוא/legacy, לא לפתח כאן (ר' frontend/README.md)
├── mobile/           ← Expo — סקלט/WIP, לא לפרודקשן (ר' mobile/README.md)
├── backend/          ← Node.js + Express + Socket.io (Render) — הפיתוח הפעיל
├── docs/             ← בדיקות, QA
├── design_mockups/   ← HTML סטטי (הפניה עיצובית)
├── .github/          ← CI, בדיקת סודות ב-git
├── render.yaml       ← Blueprint ל-Render
├── DEPLOY.md         ← מדריך פריסה
└── package.json      ← סקריפטים משורש (tunnel, backend, בדיקות)
```

למפת Next.js מלאה: `web-client/src/app/`.  
למפת שרת: `backend/server.js` ו-`backend/src/`.

**Source of truth:** כל פיתוח מוצר חדש ב-`web-client/` + `backend/` בלבד.  
`frontend/` (Flutter) קפוא — ר' `frontend/README.md`.  
`mobile/` (Expo) סקלט — לא לפרודקשן עד parity.

## קישורים

- [DEPLOY.md](DEPLOY.md) — Render + Vercel + operator checklist  
- [backend/ENV_GUIDE.md](backend/ENV_GUIDE.md)  
- [docs/DATA_RETENTION.md](docs/DATA_RETENTION.md) — soft-delete Evidence  
- [docs/LEGAL_REVIEW_PACKAGE.md](docs/LEGAL_REVIEW_PACKAGE.md)
