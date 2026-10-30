import express from 'express';
const router = express.Router();
import { getUploadUrl, getViewUrl } from '../controllers/uploadController.js';
import { protect } from '../middleware/authMiddleware.js';
import { uploadLimiter } from '../middleware/securityMiddleware.js';

router.post('/get-upload-url', protect, uploadLimiter, getUploadUrl);
router.get('/view-url', protect, uploadLimiter, getViewUrl);
router.get('/view-url/:bucket/:path', protect, uploadLimiter, getViewUrl);

export default router;