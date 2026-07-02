/* controllers/authController.js */
import User from '../models/User.js';
import Shop from '../models/Shop.js';
import jwt from 'jsonwebtoken';
import ActionLog from '../models/ActionLog.js';

// Generate JWT token including shopId in payload
const generateToken = (id, shopId) => {
  return jwt.sign(
    { id, shopId },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
};

// @desc    Register a new shop owner and create a shop
// @route   POST /api/auth/register
// @access  Public
export const registerUser = async (req, res) => {
  try {
    const { name, email, password, shopName, phone, address } = req.body;

    if (!name || !email || !password || !shopName) {
      return res.status(400).json({ message: 'Please provide name, email, password, and shopName' });
    }

    // Check if user exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists with this email' });
    }

    // 1. Create User with role 'owner'
    const user = new User({
      name,
      email,
      password,
      role: 'owner',
    });
    await user.save();

    // 2. Create Shop
    const shop = new Shop({
      shopName,
      ownerId: user._id,
      phone: phone || '',
      address: address || '',
    });
    await shop.save();

    // 3. Link Shop to User
    user.shopId = shop._id;
    await user.save();

    // Respond with user data and token
    res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: shop._id,
      shopName: shop.shopName,
      token: generateToken(user._id, shop._id),
    });
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

    // Find user by email and populate shop details
    const user = await User.findOne({ email }).populate('shopId');

    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Validate password
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Check account status and deletion requested date
    if (user.status === 'deleting') {
      const gracePeriodMs = 15 * 24 * 60 * 60 * 1000;
      const timeSinceRequest = Date.now() - new Date(user.deletionRequestedAt).getTime();
      
      if (timeSinceRequest > gracePeriodMs) {
        return res.status(401).json({ message: 'This account has been permanently deleted.' });
      } else {
        // Reactivate user since they logged in within the 15 days window with correct password!
        user.status = 'active';
        user.deletionRequestedAt = undefined;
        user.deletionReason = undefined;
        user.reactivated = true;
        await user.save();

        // Log the reactivation action
        await ActionLog.create({
          userId: user._id,
          action: 'REACTIVATE_ACCOUNT',
          details: 'Account successfully reactivated via login within 15-day grace period.',
        });
      }
    }

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: user.shopId ? user.shopId._id : null,
      shopName: user.shopId ? user.shopId.shopName : '',
      token: generateToken(user._id, user.shopId ? user.shopId._id : null),
    });
  } catch (error) {
    console.error('Login error:', error);
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
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check current password
    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect current password' });
    }

    // Update password (pre-save hook will hash it)
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
    if (!password) {
      return res.status(400).json({ message: 'Password is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Incorrect password' });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Verify password error:', error);
    res.status(500).json({ message: error.message });
  }
};
