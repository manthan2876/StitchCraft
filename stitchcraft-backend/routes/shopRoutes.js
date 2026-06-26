import express from 'express';
const router = express.Router();
import {
  getShops,
  createShop,
  getShopById,
  updateShop,
  deleteShop,
} from '../controllers/shopController.js';
import { protect } from '../middleware/authMiddleware.js';

router.use(protect); // Secure all routes in this module

router.route('/')
  .get(getShops)
  .post(createShop);

router.route('/:id')
  .get(getShopById)
  .put(updateShop)
  .delete(deleteShop);

export default router;
