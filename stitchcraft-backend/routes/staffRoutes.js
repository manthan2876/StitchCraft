/* routes/staffRoutes.js */
import { Router } from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
  getStaff,
  addStaff,
  updateStaffRole,
  updateStaffStatus,
  removeStaff,
} from '../controllers/staffController.js';

const router = Router();

// Protect all routes with auth token
router.use(protect);

// Routes accessible by owner & manager
router.get('/', authorize('owner', 'manager'), getStaff);
router.post('/', authorize('owner', 'manager'), addStaff);
router.put('/:id/status', authorize('owner', 'manager'), updateStaffStatus);

// Routes strictly restricted to owner
router.put('/:id/role', authorize('owner'), updateStaffRole);
router.delete('/:id', authorize('owner'), removeStaff);

export default router;

