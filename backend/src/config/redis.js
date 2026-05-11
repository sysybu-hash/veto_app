const { createClient } = require('redis');
const Sentry = require('@sentry/node');

// Fallback to memory if Redis is not configured (useful for local dev)
const REDIS_URL = process.env.REDIS_URL || null;

let redisClient = null;
let pubClient = null;
let subClient = null;

async function initRedis() {
  if (!REDIS_URL) {
    console.warn('⚠️ No REDIS_URL provided. Socket.io will run in memory-only mode (Not recommended for multi-instance production).');
    return null;
  }

  try {
    redisClient = createClient({ url: REDIS_URL });
    pubClient = redisClient.duplicate();
    subClient = redisClient.duplicate();

    redisClient.on('error', (err) => Sentry.captureException(err));
    pubClient.on('error', (err) => Sentry.captureException(err));
    subClient.on('error', (err) => Sentry.captureException(err));

    await Promise.all([
      redisClient.connect(),
      pubClient.connect(),
      subClient.connect()
    ]);

    console.log('✅ Redis connected successfully for Socket.io Adapter.');
    return { pubClient, subClient };
  } catch (error) {
    console.error('❌ Redis connection failed:', error);
    Sentry.captureException(error);
    return null;
  }
}

module.exports = {
  initRedis,
  /** Live reference — required for health checks after `initRedis()` runs. */
  get pubClient() {
    return pubClient;
  },
  get subClient() {
    return subClient;
  },
};
