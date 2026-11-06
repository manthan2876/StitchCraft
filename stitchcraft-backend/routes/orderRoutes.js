import express from 'express';
const router = express.Router();
import {
  createOrder,
  getOrders,
  getOrderById,
  getOrderByIdPublic,
  generateShareToken,
  revokeShareToken,
  updateOrder,
  recordOrderPayment,
  recordOrderRefund,
  deleteOrder,
  addNoteToOrder,
  delegateOrder,
  revokeDelegation,
} from '../controllers/orderController.js';
import { protect } from '../middleware/authMiddleware.js';
import { enforceMutationIdempotency } from '../middleware/mutationMiddleware.js';
import {
  validateObjectIdParam,
  validateShareTokenParam,
  publicInvoiceLimiter,
} from '../middleware/securityMiddleware.js';
import {
  validateOrderCreateRequest,
  validateOrderUpdateRequest,
  validatePaymentRequest,
} from '../middleware/validationMiddleware.js';

// Public guest invoice details route (strictly by opaque shareToken only - P0-01)
router.get('/public/:token', publicInvoiceLimiter, validateShareTokenParam('token'), getOrderByIdPublic);

router.use(protect); // Secure remaining routes in this module
router.use(enforceMutationIdempotency('orders'));

router.route('/')
  .post(validateOrderCreateRequest, createOrder)
  .get(getOrders);

router.route('/:id')
  .get(getOrderById)
  .put(validateOrderUpdateRequest, updateOrder)
  .delete(deleteOrder);

router.post('/:id/payments', validatePaymentRequest, recordOrderPayment);
router.post('/:id/refunds', recordOrderRefund);
router.post('/:id/payments/refund', recordOrderRefund);
router.post('/:id/notes', addNoteToOrder);
router.post('/:id/share-token', generateShareToken);
router.post('/:id/revoke-share-token', revokeShareToken);
router.post('/:id/share-token/revoke', revokeShareToken);
router.post('/:id/delegate', delegateOrder);
router.post('/:id/revoke-delegation', revokeDelegation);

export default router;
