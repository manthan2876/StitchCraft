import express from 'express';
const router = express.Router();
import {
  createMachine,
  getMachines,
  getMachineById,
  updateMachine,
  deleteMachine,
} from '../controllers/machineController.js';
import { protect } from '../middleware/authMiddleware.js';
import { validateMachineRequest } from '../middleware/validationMiddleware.js';

router.use(protect); // Require auth for all machines endpoints

router.route('/')
  .post(validateMachineRequest, createMachine)
  .get(getMachines);

router.route('/:id')
  .get(getMachineById)
  .put(validateMachineRequest, updateMachine)
  .delete(deleteMachine);

export default router;
