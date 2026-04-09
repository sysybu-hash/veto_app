const express = require('express');
const router = express.Router();
const multer = require('multer');
const { protect } = require('../middleware/auth.middleware');
const {
  getFiles, deleteFile, updateFileAccess, analyzeFile,
  getCases, createCase
} = require('../controllers/vault.controller');

// Secure all routes with protect middleware
router.use(protect);

router.get('/files', getFiles);
router.delete('/files/:fileId', deleteFile);
router.patch('/files/:fileId/access', updateFileAccess);
router.patch('/files/:fileId', updateFile);
router.post('/files/:fileId/analyze', analyzeFile);

// Lawyer-specific view: see files shared by a user
router.get('/shared/:userId', authorize('lawyer', 'admin'), getSharedFiles);

router.get('/cases', getCases);
router.post('/cases', createCase);

// ── Multer setup for Vault Uploads ──
// Same as Event evidence logic or just basic disk/Cloudinary
let upload;
if (process.env.CLOUDINARY_CLOUD_NAME) {
  const { cloudinaryStorage } = require('../config/cloudinary');
  upload = multer({ storage: cloudinaryStorage, limits: { fileSize: 50 * 1024 * 1024 }});
} else {
  const path = require('path');
  const fs = require('fs');
  const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads');
  if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });
  upload = multer({
    storage: multer.diskStorage({
      destination: (req, file, cb) => cb(null, UPLOADS_DIR),
      filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
    }),
    limits: { fileSize: 50 * 1024 * 1024 },
  });
}

// Upload endpoint securely assigns user_id from req.user
router.post('/files/upload', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    
    let cloudUrl = req.file.path ? req.file.path : `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    
    // Some Cloudinary setup appends resource type, some return http url. Check and fix secure url here if needed:
    if (cloudUrl.startsWith('http://res.cloudinary')) cloudUrl = cloudUrl.replace('http:', 'https:');

    const VaultFile = require('../models/VaultFile');
    const file = await VaultFile.create({
      user_id: req.user.userId,
      name: req.body.name || req.file.originalname,
      mimeType: req.body.mimeType || req.file.mimetype,
      url: cloudUrl,
      sizeBytes: req.file.size,
    });

    res.status(201).json(file);
  } catch (err) { next(err); }
});

module.exports = router;
