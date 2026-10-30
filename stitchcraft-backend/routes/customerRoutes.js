import express from 'express';
const router = express.Router();
import {
  createCustomer,
  getCustomers,
  getCustomerById,
  updateCustomer,
  deleteCustomer,
} from '../controllers/customerController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateCustomerRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Secure all routes in this module

router.route('/')
  .post(validateCustomerRequest, createCustomer)
  .get(getCustomers);

router.route('/:id')
  .get(getCustomerById)
  .put(validateCustomerRequest, updateCustomer)
  .delete(deleteCustomer);

export default router;
