import express from 'express';
const router = express.Router();
import { getUploadUrl, getViewUrl, deleteMediaFile } from '../controllers/uploadController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { uploadLimiter } from '../middleware/securityMiddleware.js';

router.post('/get-upload-url', protect, uploadLimiter, getUploadUrl);
router.get('/view-url', protect, uploadLimiter, getViewUrl);
router.get('/view-url/:bucket/:path', protect, uploadLimiter, getViewUrl);
router.delete('/file', protect, authorize('owner', 'manager'), deleteMediaFile);

export default router;