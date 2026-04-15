/**
 * When a member records evidence in a "documentation" session, mirror the file
 * into their personal vault (VaultFile) so it appears under כספת קבצים.
 */
const mongoose = require('mongoose');
const VaultFile = require('../models/VaultFile');

function guessMime(type, explicit) {
  if (explicit && String(explicit).trim()) return String(explicit).trim();
  if (type === 'photo') return 'image/jpeg';
  if (type === 'video') return 'video/mp4';
  if (type === 'audio') return 'audio/m4a';
  return 'application/octet-stream';
}

function displayName(originalName, type) {
  const o = originalName && String(originalName).trim();
  if (o) return o.slice(0, 240);
  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const ext = type === 'photo' ? 'jpg' : type === 'video' ? 'mp4' : type === 'audio' ? 'm4a' : 'bin';
  return `documentation_${ts}.${ext}`;
}

/**
 * @returns {Promise<import('mongoose').Document|null>}
 */
async function mirrorDocumentationToVault({
  userId,
  eventId,
  eventStatus,
  cloudUrl,
  mimeType,
  sizeBytes,
  originalName,
  type,
}) {
  if (eventStatus !== 'documentation' || !cloudUrl) return null;
  try {
    const srcEv =
      eventId && mongoose.isValidObjectId(eventId)
        ? new mongoose.Types.ObjectId(eventId)
        : undefined;
    const file = await VaultFile.create({
      user_id: userId,
      name: displayName(originalName, type),
      mimeType: guessMime(type, mimeType),
      url: cloudUrl,
      sizeBytes: Number(sizeBytes) || 0,
      lawyerAccess: false,
      ...(srcEv ? { sourceEventId: srcEv } : {}),
    });
    return file;
  } catch (err) {
    console.error('[documentationVaultMirror]', err.message);
    return null;
  }
}

module.exports = { mirrorDocumentationToVault };
