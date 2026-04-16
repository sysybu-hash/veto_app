// ============================================================
//  error.middleware.js — Global Error Handler
//  VETO Legal Emergency App
// ============================================================

const Sentry = require('../../instrument');

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  // Mongoose validation error (e.g. phone format)
  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message).join('; ');
    return res.status(400).json({ error: messages });
  }
  // Mongoose duplicate key (unique index)
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field';
    return res.status(409).json({ error: `A record with this ${field} already exists.` });
  }
  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    return res.status(400).json({ error: `Invalid value for ${err.path}.` });
  }

  const statusCode = err.statusCode || err.status || 500;
  console.error(`❌ [${req.method}] ${req.path} → ${err.message}`);

  if (statusCode >= 500 && Sentry.__vetoInstrumented) {
    Sentry.captureException(err);
  }

  res.status(statusCode).json({
    error:   err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
