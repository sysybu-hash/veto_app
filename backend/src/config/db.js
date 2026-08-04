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

    // Drop legacy sparse unique phone index (indexes null) and sync partial unique.
    try {
      const User = require('../models/User');
      const indexes = await User.collection.indexes();
      for (const idx of indexes) {
        const keys = Object.keys(idx.key || {});
        if (
          keys.length === 1 &&
          keys[0] === 'phone' &&
          idx.unique &&
          idx.name !== 'phone_partial_unique'
        ) {
          await User.collection.dropIndex(idx.name);
          logger.warn({ index: idx.name }, '[DB] Dropped legacy unique phone index');
        }
      }
      const repair = await User.updateMany(
        { $or: [{ phone: null }, { phone: '' }] },
        { $unset: { phone: '' } },
      );
      if (repair.modifiedCount > 0) {
        logger.warn(
          { modifiedCount: repair.modifiedCount },
          '[DB] Unset null/empty phone fields on connect',
        );
      }
      await User.syncIndexes();
    } catch (indexErr) {
      logger.warn({ err: indexErr }, '[DB] Phone index repair skipped');
    }
  } catch (error) {
    const hint = String(error.message).includes('querySrv')
      ? 'querySrv = DNS issue for mongodb+srv. Try: set Windows DNS to 8.8.8.8, or use Atlas "Standard connection" (mongodb://...) instead of srv, and update MONGO_URI.'
      : undefined;
    logger.error({ err: error, hint }, 'MongoDB connection error');
    throw error;
  }
};

module.exports = connectDB;
