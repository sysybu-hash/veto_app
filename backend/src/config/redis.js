const { createClient } = require('redis');
const Sentry = require('@sentry/node');
const logger = require('../lib/logger');

// Fallback to memory if Redis is not configured (useful for local dev)
const REDIS_URL = process.env.REDIS_URL || null;

let redisClient = null;
let pubClient = null;
let subClient = null;

async function initRedis() {
  if (!REDIS_URL) {
    logger.warn('No REDIS_URL provided. Socket.io will run in memory-only mode (not recommended for multi-instance production).');
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

    logger.info('Redis connected successfully for Socket.io Adapter.');
    return { pubClient, subClient };
  } catch (error) {
    logger.error({ err: error }, 'Redis connection failed');
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
