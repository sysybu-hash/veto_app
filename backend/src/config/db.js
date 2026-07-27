// ============================================================
//  db.js — MongoDB Connection (Mongoose)
//  VETO Legal Emergency App
// ============================================================

const dns = require('dns');
const mongoose = require('mongoose');
const logger = require('../lib/logger');

const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri || typeof uri !== 'string' || !uri.trim()) {
    const msg =
      'MONGO_URI is missing or empty. Set it in backend/.env locally or in Render Environment.';
    logger.error(msg);
    throw new Error(msg);
  }

  // Windows: DNS מקומי לפעמים נכשל על SRV של Atlas — ניסיון עם DNS ציבורי
  try {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
  } catch {
    /* ignore */
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 30000,
      family: 4,
    });

    logger.info({ host: conn.connection.host }, 'VETO Atlas Connected');
  } catch (error) {
    const hint = String(error.message).includes('querySrv')
      ? 'querySrv = DNS issue for mongodb+srv. Try: set Windows DNS to 8.8.8.8, or use Atlas "Standard connection" (mongodb://...) instead of srv, and update MONGO_URI.'
      : undefined;
    logger.error({ err: error, hint }, 'MongoDB connection error');
    throw error;
  }
};

module.exports = connectDB;
