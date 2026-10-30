import express from 'express';
const router = express.Router();
import {
  createOrder,
  getOrders,
  getOrderById,
  getOrderByIdPublic,
  generateShareToken,
  updateOrder,
  recordOrderPayment,
  deleteOrder,
  addNoteToOrder,
} from '../controllers/orderController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateObjectIdParam } from '../middleware/securityMiddleware.js';
import {
  validateOrderCreateRequest,
  validateOrderUpdateRequest,
  validatePaymentRequest,
} from '../middleware/validationMiddleware.js';

// Public guest invoice details route (by shareToken or ID)
router.get('/public/:id', validateObjectIdParam(), getOrderByIdPublic);

router.use(protect); // Secure remaining routes in this module

router.route('/')
  .post(validateOrderCreateRequest, createOrder)
  .get(getOrders);

router.route('/:id')
  .get(getOrderById)
  .put(validateOrderUpdateRequest, updateOrder)
  .delete(deleteOrder);

router.post('/:id/payments', validatePaymentRequest, recordOrderPayment);
router.post('/:id/notes', addNoteToOrder);
router.post('/:id/share-token', generateShareToken);

export default router;
