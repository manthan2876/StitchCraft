import express from 'express';
const router = express.Router();
import { getDeliveries, markAsDelivered } from '../controllers/deliveryController.js';
import { protect } from '../middleware/authMiddleware.js';

router.use(protect);

router.get('/', getDeliveries);
router.put('/:id/deliver', markAsDelivered);

export default router;
