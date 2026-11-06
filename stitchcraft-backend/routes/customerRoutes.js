import express from 'express';
const router = express.Router();
import {
  createCustomer,
  getCustomers,
  getCustomerById,
  updateCustomer,
  deleteCustomer,
  getPendingBalances,
} from '../controllers/customerController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { validateCustomerRequest } from '../middleware/validationMiddleware.js';
import { enforceMutationIdempotency } from '../middleware/mutationMiddleware.js';

router.use(protect); // Secure all routes in this module
router.use(enforceMutationIdempotency('customers'));

// Pending balances (Udhar) route must come before /:id param match
router.get('/pending-balances', getPendingBalances);

// Parity endpoint for mobile client: /customers/:id/profile (P1-01)
router.get('/:id/profile', getCustomerById);

router.route('/')
  .post(validateCustomerRequest, createCustomer)
  .get(getCustomers);

router.route('/:id')
  .get(getCustomerById)
  .put(validateCustomerRequest, updateCustomer)
  .delete(authorize('owner'), deleteCustomer);

export default router;
