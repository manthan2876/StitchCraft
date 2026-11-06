import express from 'express';
import {
  pushMutations,
  pullChanges,
  getSyncStatus,
  getSyncRegistryMetadata,
} from '../controllers/syncController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.use(protect);

router.post('/push', pushMutations);
router.get('/pull', pullChanges);
router.get('/status', getSyncStatus);
router.get('/registry', getSyncRegistryMetadata);

export default router;

