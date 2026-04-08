// ============================================================
//  cloudinary.js — Cloudinary Configuration
//  VETO Legal Emergency App
//  Required env vars:
//    CLOUDINARY_CLOUD_NAME
//    CLOUDINARY_API_KEY
//    CLOUDINARY_API_SECRET
// ============================================================

const cloudinary           = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Multer storage that streams directly to Cloudinary.
 * Files are stored in the 'veto/evidence' folder.
 */
const cloudinaryStorage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => {
    const isVideo = file.mimetype.startsWith('video/');
    const isAudio = file.mimetype.startsWith('audio/');
    return {
      folder:         'veto/evidence',
      resource_type:  isVideo ? 'video' : isAudio ? 'audio' : 'image',
      allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mp3', 'wav', 'm4a'],
      public_id:       `${Date.now()}-${req.params.eventId}`,
    };
  },
});

module.exports = { cloudinary, cloudinaryStorage };
