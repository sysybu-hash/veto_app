// ============================================================
//  cloudinaryDelete.service.js — Parse Cloudinary URLs + destroy
// ============================================================

const { cloudinary } = require('../../config/cloudinary');

/**
 * Parse a Cloudinary delivery URL into destroy() args.
 * Supports image / video / raw upload URLs (with optional version segment).
 *
 * @param {string} fileUrl
 * @returns {{ cloudName: string, resourceType: string, publicId: string } | null}
 */
function parseCloudinaryUrl(fileUrl) {
  if (!fileUrl || typeof fileUrl !== 'string') return null;
  let parsed;
  try {
    parsed = new URL(fileUrl);
  } catch {
    return null;
  }
  if (!parsed.hostname.endsWith('res.cloudinary.com') && parsed.hostname !== 'res.cloudinary.com') {
    // Also allow cloudinary.com subdomains like <cloud>-res.cloudinary.com historically rare;
    // primary host is res.cloudinary.com/<cloud>/...
    if (!/cloudinary\.com$/i.test(parsed.hostname)) return null;
  }

  // /<cloud>/<resource_type>/upload/[transformations/][v123/]<public_id>[.ext]
  const path = parsed.pathname.replace(/^\/+/, '');
  const parts = path.split('/');
  if (parts.length < 4) return null;

  const cloudName = parts[0];
  const resourceType = parts[1];
  if (!['image', 'video', 'raw', 'auto'].includes(resourceType)) return null;
  if (parts[2] !== 'upload') return null;

  let rest = parts.slice(3);
  // Drop leading version segment
  if (rest[0] && /^v\d+$/.test(rest[0])) {
    rest = rest.slice(1);
  }
  // Drop common transformation segments (contain , or start with known prefixes)
  while (
    rest.length > 1 &&
    (/[,_]/.test(rest[0]) || /^(c_|w_|h_|q_|f_|fl_|e_|l_|t_|dpr_|ar_)/.test(rest[0]))
  ) {
    rest = rest.slice(1);
  }
  if (rest.length === 0) return null;

  let publicId = rest.join('/');
  // image/video: destroy expects public_id without file extension
  if (resourceType === 'image' || resourceType === 'video') {
    publicId = publicId.replace(/\.[^./]+$/, '');
  }

  return { cloudName, resourceType: resourceType === 'auto' ? 'image' : resourceType, publicId };
}

function isOurCloudinaryUrl(fileUrl) {
  const parsed = parseCloudinaryUrl(fileUrl);
  if (!parsed) return false;
  const configured = process.env.CLOUDINARY_CLOUD_NAME;
  if (configured && parsed.cloudName !== configured) return false;
  return true;
}

/**
 * Destroy a Cloudinary asset by delivery URL or explicit public_id.
 * @param {{ fileUrl?: string, publicId?: string, resourceType?: string }} opts
 * @returns {Promise<{ ok: boolean, skipped?: boolean, result?: unknown, error?: string }>}
 */
async function destroyCloudinaryAsset(opts = {}) {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;
  if (!cloudName || !apiKey || !apiSecret) {
    return { ok: false, error: 'Cloudinary is not configured' };
  }

  let publicId = opts.publicId;
  let resourceType = opts.resourceType || 'image';

  if (!publicId && opts.fileUrl) {
    if (opts.fileUrl.startsWith('data:')) {
      return { ok: true, skipped: true };
    }
    const parsed = parseCloudinaryUrl(opts.fileUrl);
    if (!parsed) {
      return { ok: false, error: 'Not a recognizable Cloudinary URL' };
    }
    if (parsed.cloudName !== cloudName) {
      return { ok: false, error: 'Cloudinary cloud name mismatch' };
    }
    publicId = parsed.publicId;
    resourceType = parsed.resourceType;
  }

  if (!publicId) {
    return { ok: false, error: 'Missing public_id' };
  }

  const tryTypes = [resourceType, 'image', 'video', 'raw'].filter(
    (t, i, arr) => arr.indexOf(t) === i,
  );

  let lastErr = null;
  for (const type of tryTypes) {
    try {
      const result = await cloudinary.uploader.destroy(publicId, {
        resource_type: type,
        invalidate: true,
      });
      // Cloudinary returns { result: 'ok' | 'not found' | ... }
      if (result && (result.result === 'ok' || result.result === 'not found')) {
        return { ok: true, result };
      }
      lastErr = result?.result || 'unexpected destroy result';
    } catch (err) {
      lastErr = err instanceof Error ? err.message : String(err);
    }
  }
  return { ok: false, error: lastErr || 'Cloudinary destroy failed' };
}

module.exports = {
  parseCloudinaryUrl,
  isOurCloudinaryUrl,
  destroyCloudinaryAsset,
};
