// Structured logging (JSON) so log lines can actually be searched/filtered/alerted on
// in Render's log viewer or any log drain, instead of grepping console.log text.
// Pretty-prints in dev when pino-pretty is installed; plain JSON otherwise / in production.
const pino = require('pino');

const isProd = process.env.NODE_ENV === 'production';

function buildLogger() {
  const base = {
    level: process.env.LOG_LEVEL || (isProd ? 'info' : 'debug'),
    // Only redact OTP/passwords arriving on *incoming request bodies* (pino-http's req.body,
    // when body logging is enabled elsewhere) — not top-level fields on objects we log
    // ourselves. The one place we intentionally log an OTP value (auth.controller.js,
    // dev/no-Twilio path only) passes it explicitly and must not be silently blanked.
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers.cookie',
        'req.body.password',
        'req.body.otp',
      ],
      censor: '[redacted]',
    },
  };

  if (isProd) {
    return pino(base);
  }

  try {
    require.resolve('pino-pretty');
    return pino({
      ...base,
      transport: {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: 'HH:MM:ss', ignore: 'pid,hostname' },
      },
    });
  } catch {
    return pino(base);
  }
}

const logger = buildLogger();

module.exports = logger;
