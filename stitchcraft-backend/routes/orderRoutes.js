import express from 'express';
const router = express.Router();
import {
  createOrder,
  getOrders,
  getOrderById,
  getOrderByIdPublic,
  updateOrder,
  recordOrderPayment,
  deleteOrder,
  addNoteToOrder,
} from '../controllers/orderController.js';
import { protect } from '../middleware/authMiddleware.js';

// Public guest invoice details route
router.get('/public/:id', getOrderByIdPublic);

router.use(protect); // Secure remaining routes in this module

router.route('/')
  .post(createOrder)
  .get(getOrders);

router.route('/:id')
  .get(getOrderById)
  .put(updateOrder)
  .delete(deleteOrder);

router.post('/:id/payments', recordOrderPayment);
router.post('/:id/notes', addNoteToOrder);

export default router;
