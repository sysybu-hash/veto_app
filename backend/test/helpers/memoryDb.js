// ============================================================
//  memoryDb.js — real MongoDB for integration tests
//
//  Some behaviour cannot be proven with stubs: unique-index races, atomic
//  updateMany claims, and authorization queries that join two collections.
//  Those tests connect to a throwaway in-memory mongod instead of mocking
//  Mongoose, so what passes is what the driver actually does.
// ============================================================

const mongoose = require('mongoose');

let mongod = null;

async function startMemoryDb() {
  const { MongoMemoryServer } = require('mongodb-memory-server');
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri(), { dbName: 'veto_test' });
  return mongoose.connection;
}

async function stopMemoryDb() {
  await mongoose.connection.dropDatabase().catch(() => {});
  await mongoose.disconnect().catch(() => {});
  if (mongod) {
    await mongod.stop().catch(() => {});
    mongod = null;
  }
}

/** Wipe every collection between tests without paying for a new mongod. */
async function clearCollections() {
  const { collections } = mongoose.connection;
  await Promise.all(
    Object.values(collections).map((c) => c.deleteMany({})),
  );
}

module.exports = { startMemoryDb, stopMemoryDb, clearCollections };
