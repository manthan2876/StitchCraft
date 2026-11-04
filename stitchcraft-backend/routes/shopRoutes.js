import express from 'express';
const router = express.Router();
import {
  getShops,
  createShop,
  getShopById,
  updateShop,
  deleteShop,
  getPartnerTailors,
} from '../controllers/shopController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';

router.use(protect); // Secure all routes in this module

router.get('/partners', getPartnerTailors);

router.route('/')
  .get(getShops)
  .post(createShop);

router.route('/:id')
  .get(getShopById)
  .put(updateShop)
  .delete(authorize('owner'), deleteShop);

export default router;
