import express from 'express';
const router = express.Router();
import {
  registerUser,
  loginUser,
  verifyEmail,
  updatePassword,
  verifyPasswordOnly,
} from '../controllers/authController.js';
import {
  getUserProfile,
  updateUserProfile,
  switchActiveShop,
} from '../controllers/profileController.js';
import {
  downloadAllData,
  deleteAllData,
  deleteAccountRequest,
  importAllData,
  checkImportConflicts,
} from '../controllers/accountController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { authLimiter, destructiveLimiter } from '../middleware/securityMiddleware.js';
import { validateRegisterRequest } from '../middleware/validationMiddleware.js';

router.post('/register', authLimiter, validateRegisterRequest, registerUser);
router.post('/login', authLimiter, loginUser);
router.post('/verify', authLimiter, verifyEmail);
router.route('/profile')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile);
router.put('/switch-shop/:id', protect, switchActiveShop);
router.put('/update-password', protect, destructiveLimiter, updatePassword);
router.post('/verify-password', protect, destructiveLimiter, verifyPasswordOnly);
router.post('/account/download-data', protect, authorize('owner'), destructiveLimiter, downloadAllData);
router.post('/account/delete-all-data', protect, authorize('owner'), destructiveLimiter, deleteAllData);
router.post('/account/delete-account', protect, authorize('owner'), destructiveLimiter, deleteAccountRequest);
router.post('/account/check-conflicts', protect, authorize('owner'), destructiveLimiter, checkImportConflicts);
router.post('/account/import-data', protect, authorize('owner'), destructiveLimiter, importAllData);

export default router;
