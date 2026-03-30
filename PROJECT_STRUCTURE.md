# VETO – Project Structure

## Overview
```
veto/
├── frontend/          ← Flutter Mobile App
├── backend/           ← Node.js + Express + Socket.io
└── PROJECT_STRUCTURE.md
```

---

## Frontend (Flutter)
```
frontend/
├── pubspec.yaml
├── lib/
│   ├── main.dart                    ← App entry point, theme, routes
│   │
│   ├── screens/
│   │   ├── VetoScreen.dart          ← ✅ DONE – Main VETO button screen
│   │   ├── LawyerDashboard.dart     ← Lawyer accepts/rejects calls
│   │   ├── EvidenceScreen.dart      ← Camera/mic evidence recording
│   │   ├── LoginScreen.dart         ← Auth (phone OTP)
│   │   └── SplashScreen.dart        ← Animated splash
│   │
│   ├── widgets/
│   │   ├── VetoButton.dart          ← Reusable animated VETO button
│   │   ├── StatusBar.dart           ← Live status indicator
│   │   ├── LanguageSwitcher.dart    ← EN / עב / ع toggle
│   │   └── ActionIcon.dart          ← Camera / Mic bottom icons
│   │
│   ├── services/
│   │   ├── socket_service.dart      ← Socket.io client (dispatch)
│   │   ├── upload_service.dart      ← Cloud evidence upload
│   │   ├── location_service.dart    ← GPS metadata
│   │   └── auth_service.dart        ← JWT + OTP auth
│   │
│   ├── models/
│   │   ├── user_model.dart          ← User data model
│   │   ├── lawyer_model.dart        ← Lawyer data model
│   │   └── event_model.dart         ← Emergency event model
│   │
│   └── utils/
│       ├── l10n.dart                ← i18n strings (EN/HE/AR)
│       ├── theme.dart               ← Colors, typography, theme
│       └── deep_link.dart           ← WhatsApp/Telegram deep links
│
└── assets/
    └── fonts/                       ← Premium fonts (e.g. Cormorant)
```

---

## Backend (Node.js + Express + Socket.io)
```
backend/
├── package.json
├── .env                             ← MongoDB URI, JWT_SECRET, etc.
├── server.js                        ← Entry point (Express + Socket.io)
│
└── src/
    ├── config/
    │   └── db.js                    ← MongoDB connection (Mongoose)
    │
    ├── models/
    │   ├── User.js                  ← ✅ Mongoose schema – User
    │   ├── Lawyer.js                ← ✅ Mongoose schema – Lawyer
    │   └── EmergencyEvent.js        ← ✅ Mongoose schema – Emergency Event
    │
    ├── routes/
    │   ├── auth.routes.js           ← POST /auth/login, /auth/verify
    │   ├── user.routes.js           ← GET/PUT /users/:id
    │   ├── lawyer.routes.js         ← GET /lawyers/available
    │   └── event.routes.js          ← POST /events, GET /events/:id
    │
    ├── controllers/
    │   ├── auth.controller.js
    │   ├── user.controller.js
    │   ├── lawyer.controller.js
    │   └── event.controller.js
    │
    ├── middleware/
    │   ├── auth.middleware.js       ← JWT verification
    │   └── error.middleware.js      ← Global error handler
    │
    └── socket/
        └── dispatch.socket.js       ← Smart Dispatch logic (Socket.io)
```
