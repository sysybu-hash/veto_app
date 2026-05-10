// ============================================================
//  account.service.js
//  Cross-collection account lookup (User + Lawyer) and a small
//  serializer for the public account payload returned to clients.
// ============================================================

const User = require('../../models/User');
const Lawyer = require('../../models/Lawyer');

/**
 * Find an account in either collection by phone.
 * Returns `{ doc, role }` or `null`. Admins keep their `admin` role,
 * everyone else collapses to `user` / `lawyer`.
 */
async function findByPhone(phone) {
  const user = await User.findOne({ phone });
  if (user) {
    const appRole = user.role === 'admin' ? 'admin' : 'user';
    return { doc: user, role: appRole };
  }

  const lawyer = await Lawyer.findOne({ phone });
  if (lawyer) return { doc: lawyer, role: 'lawyer' };

  return null;
}

/** Pick the right Mongoose model for a role string. */
function modelFor(role) {
  if (role === 'lawyer') return Lawyer;
  return User;
}

/**
 * Look up an account by id and `role`. Pass `includePasskeys=true` to also
 * select the protected `passkeys` field for WebAuthn flows.
 */
async function findAccountById(id, role, includePasskeys = false) {
  const Model = role === 'lawyer' ? Lawyer : User;
  const query = Model.findById(id);
  if (includePasskeys) query.select('+passkeys');
  const doc = await query;
  if (!doc) return null;
  return { doc, role: role === 'admin' ? 'admin' : role };
}

/** Strip a Mongoose doc down to the safe fields we expose to clients. */
function publicAccount(doc, role) {
  return {
    id: doc._id,
    role,
    full_name: doc.full_name,
    phone: doc.phone,
    email: doc.email || null,
  };
}

module.exports = {
  findByPhone,
  modelFor,
  findAccountById,
  publicAccount,
};
