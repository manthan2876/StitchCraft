import express from 'express';
const router = express.Router();
import { getUploadUrl, getViewUrl, listBucketFiles } from '../controllers/uploadController.js';
import { protect } from '../middleware/authMiddleware.js';

router.post('/get-upload-url', protect, getUploadUrl);
router.get('/view-url/:bucket/:path', protect, getViewUrl);
router.get('/list/:bucket', protect, listBucketFiles);

export default router;