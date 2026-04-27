// ============================================================

const crypto = require('crypto');
const User = require('../models/User');
const Lawyer = require('../models/Lawyer');

function accountFromReq(req) {
  const r = req.user?.role;
  if (r === 'lawyer') {
    return { accountId: req.user.userId, accountRole: 'lawyer' };
  }
  if (r === 'admin') {
    return { accountId: req.user.userId, accountRole: 'admin' };
  }
  return { accountId: req.user.userId, accountRole: 'user' };
}

/**
 * @returns {Promise<string|null>} secret token
 */
async function ensureIcalFeedToken(accountId, accountRole) {
  if (accountRole === 'lawyer') {
    let doc = await Lawyer.findById(accountId).select('icalFeedToken');
    if (!doc) return null;
    if (!doc.icalFeedToken) {
      const t = crypto.randomBytes(24).toString('hex');
      await Lawyer.findByIdAndUpdate(accountId, { icalFeedToken: t });
      return t;
    }
    return doc.icalFeedToken;
  }
  let doc = await User.findById(accountId).select('icalFeedToken');
  if (!doc) return null;
  if (!doc.icalFeedToken) {
    const t = crypto.randomBytes(24).toString('hex');
    await User.findByIdAndUpdate(accountId, { icalFeedToken: t });
    return t;
  }
  return doc.icalFeedToken;
}

/**
 * @returns {email?: string, fullName?: string}
 */
async function getAccountEmail(accountId, accountRole) {
  if (accountRole === 'lawyer') {
    const l = await Lawyer.findById(accountId).select('email full_name');
    return { email: l?.email, fullName: l?.full_name };
  }
  const u = await User.findById(accountId).select('email full_name');
  return { email: u?.email, fullName: u?.full_name };
}

module.exports = { accountFromReq, ensureIcalFeedToken, getAccountEmail };
