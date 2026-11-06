import express from 'express';
const router = express.Router();
import {
  createKarigar,
  getKarigars,
  getKarigarById,
  updateKarigar,
  deleteKarigar,
  getKarigarWages,
  accrueWage,
  recordPayout,
} from '../controllers/karigarController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { validateKarigarRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Require auth for all karigars endpoints

router.route('/')
  .post(validateKarigarRequest, createKarigar)
  .get(getKarigars);

router.route('/:id')
  .get(getKarigarById)
  .put(validateKarigarRequest, updateKarigar)
  .delete(authorize('owner'), deleteKarigar);

// Piece-rate wages and payouts (Phase 7, 11.7)
router.get('/:id/wages', getKarigarWages);
router.post('/:id/wages/accrue', authorize('owner', 'manager'), accrueWage);
router.post('/:id/wages/payout', authorize('owner', 'manager'), recordPayout);

export default router;
