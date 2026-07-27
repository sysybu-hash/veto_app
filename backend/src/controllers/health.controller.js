const mongoose = require('mongoose');
const { pubClient } = require('../config/redis');
const agoraCrHealth = require('../services/agoraCloudRecording.service');

// readyState===1 only means the socket thinks it's connected — it doesn't prove the
// server actually responds. A real ping catches a wedged/half-open connection that
// readyState alone would report as healthy.
async function pingMongo() {
  if (mongoose.connection.readyState !== 1) return false;
  try {
    const pingPromise = mongoose.connection.db.admin().ping();
    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('mongo ping timeout')), 3000),
    );
    await Promise.race([pingPromise, timeout]);
    return true;
  } catch {
    return false;
  }
}

exports.getHealthStatus = async (req, res) => {
  try {
    const mongoReachable = await pingMongo();
    const mongoStatus = mongoReachable ? 'connected' : 'disconnected';

    // pubClient is null when Redis isn't configured at all — that's a valid deployment
    // mode (single-instance Socket.io, no adapter), not a failure. Only a *configured but
    // unreachable* Redis should mark the service unhealthy.
    let redisStatus = 'disabled/not-configured';
    let redisConfigured = false;
    if (pubClient) {
      redisConfigured = true;
      redisStatus = pubClient.isReady ? 'connected' : 'disconnected';
    }

    const configStatus = {
      jwtSecret: !!process.env.JWT_SECRET,
      agoraAppId: !!process.env.AGORA_APP_ID,
      vapidPublicKey: !!process.env.VAPID_PUBLIC_KEY,
      sentryDsn: !!process.env.SENTRY_DSN,
      cloudinary:
        !!process.env.CLOUDINARY_URL ||
        (!!process.env.CLOUDINARY_CLOUD_NAME && !!process.env.CLOUDINARY_API_KEY),
    };

    const rs = mongoose.connection.readyState;
    /** Legacy shape for `web-client` admin proxy + docs (`connected` | `error` | effective pending). */
    const mongoLegacy =
      rs === 1 ? 'connected' : rs === 2 ? 'pending' : 'error';

    const io = req.app.get('io');

    const status = {
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      services: {
        database: mongoStatus,
        redis: redisStatus,
      },
      configuration: configStatus,
      version: process.version,
      app: 'VETO',
      mongo: mongoLegacy,
      db: mongoLegacy,
      socket: !!io,
      cloudRecordingConfigured: agoraCrHealth.isCloudRecordingConfigured(),
    };

    const isHealthy =
      mongoStatus === 'connected' && (!redisConfigured || redisStatus === 'connected');

    res.status(isHealthy ? 200 : 503).json(status);
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};
