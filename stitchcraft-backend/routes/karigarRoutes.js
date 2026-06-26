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

router.use(protect); // Require auth for all karigars endpoints

router.route('/')
  .post(createKarigar)
  .get(getKarigars);

router.route('/:id')
  .get(getKarigarById)
  .put(updateKarigar)
  .delete(deleteKarigar);

export default router;
