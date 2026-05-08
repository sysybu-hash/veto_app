// ============================================================
//  auth.middleware.js — JWT Authentication
//  VETO Legal Emergency App
//  Uses JWT_SECRET + JWT_EXPIRES_IN from process.env
// ============================================================

const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

function jwtSecret() {
  const s = process.env.JWT_SECRET;
  if (!s) {
    throw new Error('JWT_SECRET is not set in environment.');
  }
  return s;
}

// ── HTTP Middleware ────────────────────────────────────────
const protect = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, jwtSecret());
    // Normalize Mongo id from JWT (ObjectId may stringify oddly across clients)
    let uid = decoded.userId ?? decoded.id ?? decoded._id;
    if (uid != null && typeof uid === 'object' && uid.toString) {
      uid = uid.toString();
    }
    if (uid != null) {
      decoded.userId = String(uid);
    }
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

/**
 * After protect — rejects missing/non-ObjectId user ids before Mongo queries
 * (avoids CastError: Invalid value for user_id on citizen CRM / productivity APIs).
 */
const requireValidMongoUserId = (req, res, next) => {
  let id = req.user?.userId ?? req.user?.id;
  if (id != null && typeof id === 'object' && id.toString) {
    id = id.toString();
  }
  if (id != null) id = String(id).trim();
  if (!id) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }
  if (!mongoose.isValidObjectId(id)) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }
  req.user.userId = id;
  next();
};

// ── Role-based Authorization ──────────────────────────────
const authorize = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return res.status(403).json({ error: 'Forbidden.' });
  }
  next();
};

// ── Socket.io Middleware ───────────────────────────────────
const socketAuth = (socket, next) => {
  const token = socket.handshake.auth?.token;

  if (!token) {
    return next(new Error('Socket auth failed: no token.'));
  }

  try {
    const decoded = jwt.verify(token, jwtSecret());
    let uid = decoded.userId ?? decoded.id ?? decoded._id;
    if (uid != null && typeof uid === 'object' && uid.toString) {
      uid = uid.toString();
    }
    if ((uid == null || String(uid).trim() === '') && decoded.sub != null) {
      const s = String(decoded.sub).trim();
      if (mongoose.isValidObjectId(s)) uid = s;
    }
    if (uid != null) {
      decoded.userId = String(uid).trim();
    }
    socket.handshake.auth.decoded = decoded;
    next();
  } catch {
    return next(new Error('Socket auth failed: invalid token.'));
  }
};

// ── Token Generator (auth.controller.js) ──────────────────
const signToken = (payload) =>
  jwt.sign(payload, jwtSecret(), {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });

module.exports = {
  protect,
  authorize,
  socketAuth,
  signToken,
  requireValidMongoUserId,
};
