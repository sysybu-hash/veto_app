# VETO — מבנה הפרויקט

## סקירה

```
veto_legal/
├── web-client/      ← Next.js (ווב ראשי — Vercel)
├── frontend/        ← Flutter (מובייל / ארטיפקט web legacy אם קיים)
├── mobile/           ← Expo / ניסויים נייד (אם בשימוש)
├── backend/          ← Node.js + Express + Socket.io (Render)
├── docs/             ← בדיקות, QA
├── design_mockups/   ← HTML סטטי (הפניה עיצובית)
├── .github/          ← CI, בדיקת סודות ב-git
├── render.yaml       ← Blueprint ל-Render
├── DEPLOY.md         ← מדריך פריסה
└── package.json      ← סקריפטים משורש (tunnel, backend, בדיקות)
```

למפת Next.js מלאה: `web-client/src/app/`.  
למפת שרת: `backend/server.js` ו-`backend/src/`.

## קישורים

- [DEPLOY.md](DEPLOY.md) — Render + Vercel + משתני סביבה  
- [backend/ENV_GUIDE.md](backend/ENV_GUIDE.md)
