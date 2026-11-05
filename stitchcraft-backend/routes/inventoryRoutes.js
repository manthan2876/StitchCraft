import express from 'express';
const router = express.Router();
import {
  createInventoryItem,
  getInventory,
  getInventoryItemById,
  updateInventoryItem,
  deleteInventoryItem,
  adjustInventoryItem,
} from '../controllers/inventoryController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateInventoryRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Require auth for all inventory endpoints

router.route('/')
  .post(validateInventoryRequest, createInventoryItem)
  .get(getInventory);

router.route('/:id')
  .get(getInventoryItemById)
  .put(validateInventoryRequest, updateInventoryItem)
  .delete(deleteInventoryItem);

router.post('/:id/adjust', adjustInventoryItem);

export default router;
