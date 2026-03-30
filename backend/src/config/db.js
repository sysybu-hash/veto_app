// ============================================================
//  db.js — MongoDB Connection (Mongoose)
//  VETO Legal Emergency App
// ============================================================

const dns = require('dns');
const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri || typeof uri !== 'string' || !uri.trim()) {
    console.error('❌ MONGO_URI is missing or empty.');
    console.error('   Create backend/.env with MONGO_URI=... (UTF-8) and run from backend/: npm run dev');
    process.exit(1);
  }

  // Windows: DNS מקומי לפעמים נכשל על SRV של Atlas — ניסיון עם DNS ציבורי
  try {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
  } catch (_) {
    /* ignore */
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 30000,
      family: 4,
    });

    console.log('✅ VETO Atlas Connected');
    console.log(`   Host: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    if (String(error.message).includes('querySrv')) {
      console.error('');
      console.error('   טיפ: שגיאת querySrv = בעיית DNS ל־mongodb+srv.');
      console.error('   נסה: הגדרת DNS בווינדוס ל־8.8.8.8, או ב-Atlas קח מחרוזת');
      console.error('   "Standard connection" (mongodb://...) במקום srv, ועדכן MONGO_URI.');
    }
    process.exit(1);
  }
};

module.exports = connectDB;
