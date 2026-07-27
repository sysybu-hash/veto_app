const { geminiChat } = require('../services/gemini.service');
const logger = require('../lib/logger');

function canExecute(role, action) {
  if (role === 'admin') return true;
  const a = String(action || '').toLowerCase();
  if (role === 'lawyer') return !a.includes('system');
  return !(a.includes('admin') || a.includes('system'));
}

exports.contextChat = async (req, res) => {
  try {
    const { message, history, lang = 'he', route = '/', action = '' } = req.body || {};
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'message is required' });
    }

    const role = req.user?.role || 'user';
    if (!canExecute(role, action)) {
      return res.status(403).json({
        error: 'Forbidden action for current role',
      });
    }

    const contextEnvelope = `ROLE=${role}\nROUTE=${route}\nACTION=${action}\nUSER_MESSAGE=${message}`;
    const reply = await geminiChat(history || [], contextEnvelope, lang);

    return res.json({
      ok: true,
      role,
      route,
      reply,
    });
  } catch (err) {
    logger.error({ err }, 'contextChat error');
    return res.status(500).json({ error: 'Assistant unavailable' });
  }
};

