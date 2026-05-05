// ============================================================
//  AES-256-GCM for Google Calendar refresh_token at rest
//  Key: GCAL_TOKEN_ENC_KEY or SHA-256(JWT_SECRET)
// ============================================================

const crypto = require('crypto');

const ALGO = 'aes-256-gcm';
const IV_LEN = 16;
const AUTH_TAG_LEN = 16;

function encKey() {
  const raw = process.env.GCAL_TOKEN_ENC_KEY || process.env.JWT_SECRET;
  if (!raw) {
    throw new Error('GCAL_TOKEN_ENC_KEY or JWT_SECRET must be set to encrypt calendar tokens.');
  }
  return crypto.createHash('sha256').update(String(raw)).digest();
}

/**
 * @param {string} plain
 * @returns {string|null}
 */
function encryptToken(plain) {
  if (plain == null || plain === '') return null;
  const iv = crypto.randomBytes(IV_LEN);
  const cipher = crypto.createCipheriv(ALGO, encKey(), iv);
  const enc = Buffer.concat([cipher.update(String(plain), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString('base64');
}

/**
 * @param {string|null} blob
 * @returns {string|null}
 */
function decryptToken(blob) {
  if (blob == null || blob === '') return null;
  try {
    const buf = Buffer.from(String(blob), 'base64');
    if (buf.length < IV_LEN + AUTH_TAG_LEN + 1) return null;
    const iv = buf.subarray(0, IV_LEN);
    const tag = buf.subarray(IV_LEN, IV_LEN + AUTH_TAG_LEN);
    const data = buf.subarray(IV_LEN + AUTH_TAG_LEN);
    const decipher = crypto.createDecipheriv(ALGO, encKey(), iv);
    decipher.setAuthTag(tag);
    const out = Buffer.concat([decipher.update(data), decipher.final()]);
    return out.toString('utf8');
  } catch {
    return null;
  }
}

module.exports = { encryptToken, decryptToken };
