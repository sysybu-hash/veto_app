/**
 * Upsert admin users in MongoDB (User collection, role: admin).
 * Run from backend/:  npm run init-admins
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (_) {}

const mongoose = require('mongoose');
const User = require('../src/models/User');
const Lawyer = require('../src/models/Lawyer');

const ADMINS = [
  { full_name: 'אדמין +972525640021', phone: '+972525640021' },
  { full_name: 'אדמין +972506400030', phone: '+972506400030' },
];

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGO_URI missing in .env');
    process.exit(1);
  }

  await mongoose.connect(uri, { serverSelectionTimeoutMS: 30000, family: 4 });
  console.log('Connected. Upserting admins...\n');

  for (const a of ADMINS) {
    const asLawyer = await Lawyer.findOne({ phone: a.phone });
    if (asLawyer) {
      console.log(`Skip ${a.phone}: already a Lawyer document.`);
      continue;
    }

    const doc = await User.findOneAndUpdate(
      { phone: a.phone },
      {
        $set: {
          full_name: a.full_name,
          role: 'admin',
          preferred_language: 'he',
          is_verified: true,
        },
        $setOnInsert: { phone: a.phone },
      },
      { upsert: true, new: true, runValidators: true },
    );

    console.log(`OK  ${a.phone} → ${doc.full_name} (role=${doc.role})`);
  }

  await mongoose.disconnect();
  console.log('\nDone.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
