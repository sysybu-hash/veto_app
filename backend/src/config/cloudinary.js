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
    const isImage = file.mimetype.startsWith('image/');
    
    // Auto resource type for PDFs/Docs etc.
    let resourceType = 'auto';
    if (isImage) resourceType = 'image';
    if (isVideo || isAudio) resourceType = 'video';

    return {
      folder:         'veto/vault',
      resource_type:  resourceType,
      // No strict allowed_formats here for 'raw' types, but Cloudinary handles many.
      public_id:       `${Date.now()}-${file.originalname.split('.')[0]}`,
    };
  },
});

module.exports = { cloudinary, cloudinaryStorage };
