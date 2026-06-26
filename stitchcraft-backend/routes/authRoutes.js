import express from 'express';
const router = express.Router();
import {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
  switchActiveShop,
  updatePassword,
  downloadAllData,
  deleteAllData,
  deleteAccountRequest,
  verifyPasswordOnly,
  importAllData,
  checkImportConflicts,
} from '../controllers/authController.js';
import { protect } from '../middleware/authMiddleware.js';

router.post('/register', registerUser);
router.post('/login', loginUser);
router.route('/profile')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile);
router.put('/switch-shop/:id', protect, switchActiveShop);
router.put('/update-password', protect, updatePassword);
router.post('/verify-password', protect, verifyPasswordOnly);
router.post('/account/download-data', protect, downloadAllData);
router.post('/account/delete-all-data', protect, deleteAllData);
router.post('/account/delete-account', protect, deleteAccountRequest);
router.post('/account/check-conflicts', protect, checkImportConflicts);
router.post('/account/import-data', protect, importAllData);

export default router;
