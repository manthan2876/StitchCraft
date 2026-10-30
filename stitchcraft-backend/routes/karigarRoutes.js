import express from 'express';
const router = express.Router();
import {
  createKarigar,
  getKarigars,
  getKarigarById,
  updateKarigar,
  deleteKarigar,
} from '../controllers/karigarController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateKarigarRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Require auth for all karigars endpoints

router.route('/')
  .post(validateKarigarRequest, createKarigar)
  .get(getKarigars);

router.route('/:id')
  .get(getKarigarById)
  .put(validateKarigarRequest, updateKarigar)
  .delete(deleteKarigar);

export default router;
