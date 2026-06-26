import express from 'express';
const router = express.Router();
import {
  createInventoryItem,
  getInventory,
  getInventoryItemById,
  updateInventoryItem,
  deleteInventoryItem,
} from '../controllers/inventoryController.js';
import { protect } from '../middleware/authMiddleware.js';

router.use(protect); // Require auth for all inventory endpoints

router.route('/')
  .post(createInventoryItem)
  .get(getInventory);

router.route('/:id')
  .get(getInventoryItemById)
  .put(updateInventoryItem)
  .delete(deleteInventoryItem);

export default router;
