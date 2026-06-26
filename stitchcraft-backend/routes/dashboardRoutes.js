import express from 'express';
const router = express.Router();
import { getDashboardStats } from '../controllers/dashboardController.js';
import { protect } from '../middleware/authMiddleware.js';

router.use(protect);

router.get('/stats', getDashboardStats);

export default router;
