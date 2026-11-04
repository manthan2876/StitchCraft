import { Router } from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
  createRepair,
  getRepairs,
  updateRepair,
  deleteRepair,
} from '../controllers/repairController.js';

const router = Router();

router.use(protect);

router.route('/')
  .post(createRepair)
  .get(getRepairs);

router.route('/:id')
  .put(updateRepair)
  .delete(deleteRepair);

export default router;

