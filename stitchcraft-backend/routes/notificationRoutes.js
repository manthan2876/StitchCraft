import express from 'express';
const router = express.Router();
import { getNotifications, markAllAsRead, markAsRead } from '../controllers/notificationController.js';
import { protect } from '../middleware/authMiddleware.js';

router.use(protect);

router.get('/', getNotifications);
router.put('/mark-read', markAllAsRead);
router.put('/:id/read', markAsRead);

export default router;
