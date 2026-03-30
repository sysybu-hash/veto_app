// ============================================================
//  error.middleware.js — Global Error Handler
//  VETO Legal Emergency App
// ============================================================

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  console.error(`❌ [${req.method}] ${req.path} → ${err.message}`);

  res.status(statusCode).json({
    error:   err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
