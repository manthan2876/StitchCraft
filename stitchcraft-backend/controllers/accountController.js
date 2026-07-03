/* controllers/accountController.js */
import User from '../models/User.js';
import {
  exportAllDataService,
  purgeAllDataService,
  requestDeletionService,
  checkConflictsService,
  importAllDataService,
} from '../services/accountService.js';

// Helper to authenticate user password before critical operations
const authenticateUser = async (userId, password) => {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  const isMatch = await user.matchPassword(password);
  if (!isMatch) throw new Error('Incorrect password');
  return user;
};

// @desc    Download all data as JSON
// @route   POST /api/auth/account/download-data
// @access  Private
export const downloadAllData = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });

    const user = await authenticateUser(req.user._id, password);
    const data = await exportAllDataService(user);
    res.json(data);
  } catch (error) {
    console.error('Download data error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete all active shop data
// @route   POST /api/auth/account/delete-all-data
// @access  Private
export const deleteAllData = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });

    const user = await authenticateUser(req.user._id, password);
    await purgeAllDataService(user);
    res.json({ message: 'All shop data deleted successfully' });
  } catch (error) {
    console.error('Delete all data error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Request account deletion
// @route   POST /api/auth/account/delete-account
// @access  Private
export const deleteAccountRequest = async (req, res) => {
  try {
    const { password, reason } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });

    const user = await authenticateUser(req.user._id, password);
    await requestDeletionService(user, reason);
    res.json({ message: 'Account scheduled for deletion. Logging out...' });
  } catch (error) {
    console.error('Delete account request error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Check conflicts in uploaded JSON import data
// @route   POST /api/auth/account/check-conflicts
// @access  Private
export const checkImportConflicts = async (req, res) => {
  try {
    const { data } = req.body;
    if (!data) return res.status(400).json({ message: 'Backup data is required' });

    const shopId = req.user.shopId;
    if (!shopId) return res.status(400).json({ message: 'No active shop selected' });

    const conflicts = await checkConflictsService(shopId, data);
    res.json({
      hasConflicts: conflicts.length > 0,
      conflicts
    });
  } catch (error) {
    console.error('Check conflicts error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Import shop data from JSON with conflict resolution choices
// @route   POST /api/auth/account/import-data
// @access  Private
export const importAllData = async (req, res) => {
  try {
    const { password, data, resolutions } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });
    if (!data) return res.status(400).json({ message: 'Import data is required' });

    const user = await authenticateUser(req.user._id, password);
    await importAllDataService(user, data, resolutions);
    res.json({ message: 'All shop data imported successfully.' });
  } catch (error) {
    console.error('Import data error:', error);
    res.status(500).json({ message: error.message });
  }
};
