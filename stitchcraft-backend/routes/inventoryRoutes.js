import express from 'express';
const router = express.Router();
import {
  createInventoryItem,
  getInventory,
  getInventoryItemById,
  updateInventoryItem,
  deleteInventoryItem,
  adjustInventoryItem,
  getInventoryItemMovements,
  reconcileInventoryItem,
} from '../controllers/inventoryController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateInventoryRequest } from '../middleware/validationMiddleware.js';
import { enforceMutationIdempotency } from '../middleware/mutationMiddleware.js';

router.use(protect); // Require auth for all inventory endpoints
router.use(enforceMutationIdempotency('inventory'));

router.route('/')
  .post(validateInventoryRequest, createInventoryItem)
  .get(getInventory);

router.route('/:id')
  .get(getInventoryItemById)
  .put(validateInventoryRequest, updateInventoryItem)
  .delete(deleteInventoryItem);

router.post('/:id/adjust', adjustInventoryItem);
router.get('/:id/movements', getInventoryItemMovements);
router.get('/:id/reconciliation', reconcileInventoryItem);

export default router;
