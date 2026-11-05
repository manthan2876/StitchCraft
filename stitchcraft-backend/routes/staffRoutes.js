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

// Protect all routes with auth token and enforce owner-only access (P0-02)
router.use(protect);
router.use(authorize('owner'));

// Staff management operations (Owner-only)
router.get('/', getStaff);
router.post('/', addStaff);
router.put('/:id/status', updateStaffStatus);
router.put('/:id/role', updateStaffRole);
router.delete('/:id', removeStaff);

export default router;

