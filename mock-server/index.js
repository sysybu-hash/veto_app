const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory storage for OTP codes (for demo purposes)
const otpStorage = {};
const validTokens = {};

// Helper function to generate random OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Helper function to generate token
function generateToken() {
  return 'token_' + Math.random().toString(36).substr(2, 9);
}

console.log('🚀 Mock VETO Server started on port', PORT);
console.log('📱 Base URL: http://localhost:' + PORT);
console.log('========================================');

// ==================== AUTH ENDPOINTS ====================

/**
 * POST /auth/request-otp
 * Request OTP for a phone number
 */
app.post('/auth/request-otp', (req, res) => {
  const { phoneNumber } = req.body;

  console.log(`📞 OTP Request for: ${phoneNumber}`);

  if (!phoneNumber) {
    return res.status(400).json({
      success: false,
      message: 'Phone number is required',
      error: 'MISSING_PHONE_NUMBER'
    });
  }

  // Generate OTP
  const otp = generateOTP();
  otpStorage[phoneNumber] = {
    otp: otp,
    createdAt: Date.now(),
    attempts: 0,
    verified: false
  };

  console.log(`✅ OTP generated for ${phoneNumber}: ${otp} (expires in 10 minutes)`);

  return res.status(200).json({
    success: true,
    message: 'OTP sent successfully',
    phoneNumber: phoneNumber,
    expiresIn: 600, // 10 minutes
    // For testing purposes only - remove in production
    __debug__: {
      otp: otp,
      message: '👉 Use this OTP in the app for testing'
    }
  });
});

/**
 * POST /auth/verify-otp
 * Verify OTP code and return token
 */
app.post('/auth/verify-otp', (req, res) => {
  const { phoneNumber, otpCode } = req.body;

  console.log(`🔐 OTP Verification for: ${phoneNumber}`);

  if (!phoneNumber || !otpCode) {
    return res.status(400).json({
      success: false,
      message: 'Phone number and OTP code are required',
      error: 'MISSING_PARAMS'
    });
  }

  const storedData = otpStorage[phoneNumber];

  // Check if OTP exists
  if (!storedData) {
    console.log(`❌ No OTP found for ${phoneNumber}`);
    return res.status(400).json({
      success: false,
      message: 'OTP not found. Please request a new OTP',
      error: 'OTP_NOT_FOUND'
    });
  }

  // Check if OTP is expired (10 minutes)
  if (Date.now() - storedData.createdAt > 600000) {
    console.log(`⏰ OTP expired for ${phoneNumber}`);
    delete otpStorage[phoneNumber];
    return res.status(400).json({
      success: false,
      message: 'OTP has expired. Please request a new OTP',
      error: 'OTP_EXPIRED'
    });
  }

  // Check OTP code
  if (storedData.otp !== otpCode) {
    storedData.attempts += 1;
    console.log(`❌ Invalid OTP for ${phoneNumber} (attempt ${storedData.attempts})`);

    if (storedData.attempts >= 5) {
      delete otpStorage[phoneNumber];
      return res.status(429).json({
        success: false,
        message: 'Too many failed attempts. Please request a new OTP',
        error: 'TOO_MANY_ATTEMPTS'
      });
    }

    return res.status(400).json({
      success: false,
      message: `Invalid OTP. ${5 - storedData.attempts} attempts remaining`,
      error: 'INVALID_OTP',
      attemptsRemaining: 5 - storedData.attempts
    });
  }

  // OTP is correct - generate token
  const token = generateToken();
  validTokens[token] = {
    phoneNumber: phoneNumber,
    createdAt: Date.now(),
    expiresAt: Date.now() + 86400000 // 24 hours
  };

  console.log(`✅ OTP verified for ${phoneNumber}. Token generated: ${token}`);
  delete otpStorage[phoneNumber];

  return res.status(200).json({
    success: true,
    message: 'OTP verified successfully',
    phoneNumber: phoneNumber,
    token: token,
    expiresIn: 86400, // 24 hours in seconds
    user: {
      phoneNumber: phoneNumber,
      isNewUser: true,
      createdAt: new Date().toISOString()
    }
  });
});

/**
 * POST /auth/verify-token
 * Verify if a token is valid
 */
app.post('/auth/verify-token', (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({
      success: false,
      message: 'Token is required',
      error: 'MISSING_TOKEN'
    });
  }

  const tokenData = validTokens[token];

  if (!tokenData) {
    console.log(`❌ Invalid token`);
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token',
      error: 'INVALID_TOKEN'
    });
  }

  if (Date.now() > tokenData.expiresAt) {
    console.log(`⏰ Token expired`);
    delete validTokens[token];
    return res.status(401).json({
      success: false,
      message: 'Token has expired',
      error: 'TOKEN_EXPIRED'
    });
  }

  console.log(`✅ Token verified for ${tokenData.phoneNumber}`);
  return res.status(200).json({
    success: true,
    message: 'Token is valid',
    phoneNumber: tokenData.phoneNumber,
    expiresAt: new Date(tokenData.expiresAt).toISOString()
  });
});

/**
 * POST /auth/logout
 * Logout and invalidate token
 */
app.post('/auth/logout', (req, res) => {
  const { token } = req.body;

  if (token && validTokens[token]) {
    const phoneNumber = validTokens[token].phoneNumber;
    delete validTokens[token];
    console.log(`👋 User ${phoneNumber} logged out`);
  }

  return res.status(200).json({
    success: true,
    message: 'Logged out successfully'
  });
});

// ==================== HEALTH CHECK ====================

/**
 * GET /health
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Mock server is healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    endpoints: {
      'POST /auth/request-otp': 'Request OTP for phone number',
      'POST /auth/verify-otp': 'Verify OTP and get token',
      'POST /auth/verify-token': 'Verify token validity',
      'POST /auth/logout': 'Logout and invalidate token',
      'GET /health': 'Health check'
    }
  });
});

// ==================== ERROR HANDLING ====================

/**
 * 404 Not Found
 */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.path,
    method: req.method,
    error: 'NOT_FOUND'
  });
});

/**
 * Global error handler
 */
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: err.message
  });
});

// ==================== SERVER START ====================

app.listen(PORT, () => {
  console.log(`\n✨ Mock VETO Server is running!`);
  console.log(`📍 URL: http://localhost:${PORT}`);
  console.log(`\n✅ Ready for testing!`);
  console.log(`\nUsage:`);
  console.log(`  Test Phone: +972525640021`);
  console.log(`  Health Check: http://localhost:${PORT}/health\n`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down server...');
  process.exit(0);
});
