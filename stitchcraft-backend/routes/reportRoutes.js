import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { getMonthEndReport } from '../controllers/reportController.js';

const router = express.Router();

// Owner and Manager can access business reports
router.get('/month-end', protect, authorize('owner', 'manager'), getMonthEndReport);

export default router;
