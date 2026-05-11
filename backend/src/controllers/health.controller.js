const mongoose = require('mongoose');
const { pubClient } = require('../config/redis');
const agoraCrHealth = require('../services/agoraCloudRecording.service');

exports.getHealthStatus = async (req, res) => {
  try {
    const mongoStatus =
      mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';

    let redisStatus = 'disabled/not-configured';
    if (pubClient) {
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

    const isHealthy = mongoStatus === 'connected';

    res.status(isHealthy ? 200 : 503).json(status);
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};
