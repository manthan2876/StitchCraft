/* controllers/authController.js */
import User from '../models/User.js';
import {
  registerShopOwner,
  loginShopOwner,
} from '../services/authService.js';

// @desc    Register a new shop owner and create a shop
// @route   POST /api/auth/register
// @access  Public
export const registerUser = async (req, res) => {
  try {
    const { name, email, password, shopName, phone, address } = req.body;
    if (!name || !email || !password || !shopName) {
      return res.status(400).json({ message: 'Please provide name, email, password, and shopName' });
    }

    const result = await registerShopOwner(name, email, password, shopName, phone, address);
    res.status(201).json(result);
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Authenticate user & get token
// @route   POST /api/auth/login
// @access  Public
export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const result = await loginShopOwner(email, password);
    res.json(result);
  } catch (error) {
    console.error('Login error:', error, error.message);
    if (error.message === 'Invalid email or password' || error.message === 'This account has been permanently deleted.') {
      return res.status(401).json({ message: error.message });
    }
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update user password
// @route   PUT /api/auth/update-password
// @access  Private
export const updatePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Please provide current and new passwords' });
    }

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) return res.status(400).json({ message: 'Incorrect current password' });

    user.password = newPassword;
    await user.save();

    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Update password error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Verify current password only
// @route   POST /api/auth/verify-password
// @access  Private
export const verifyPasswordOnly = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) return res.status(400).json({ message: 'Password is required' });

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isMatch = await user.matchPassword(password);
    if (!isMatch) return res.status(400).json({ message: 'Incorrect password' });

    res.json({ success: true });
  } catch (error) {
    console.error('Verify password error:', error);
    res.status(500).json({ message: error.message });
  }
};
