import User from '../models/User.js';
import Shop from '../models/Shop.js';
import { supabase } from '../config/supabase.js';

// @desc    Register a new shop owner and create a shop
// @route   POST /api/auth/register
// @access  Public
export const registerUser = async (req, res) => {
  try {
    const { name, email, shopName, phone, address } = req.body;
    let token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(400).json({ message: 'Supabase authorization token required' });
    }

    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(token);
    if (error || !supabaseUser) {
      return res.status(401).json({ message: 'Invalid Supabase token: ' + (error?.message || 'Invalid user') });
    }

    const emailLower = (email || supabaseUser.email).toLowerCase();
    let userExists = await User.findOne({ $or: [{ email: emailLower }, { supabaseId: supabaseUser.id }] });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists in MongoDB database' });
    }

    const user = new User({
      name: name || supabaseUser.user_metadata?.name || 'Shop Owner',
      email: emailLower,
      role: 'owner',
      supabaseId: supabaseUser.id,
      password: 'SUPABASE_MANAGED_PASSWORD_PLACEHOLDER'
    });
    await user.save();

    const shop = new Shop({
      shopName: shopName || `${user.name}'s Shop`,
      ownerId: user._id,
      phone: phone || '',
      address: address || '',
    });
    await shop.save();

    user.shopId = shop._id;
    await user.save();

    res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: shop._id,
      shopName: shop.shopName,
      token: token,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Authenticate user & get token (checks Supabase token and gets MongoDB details)
// @route   POST /api/auth/login
// @access  Public
export const loginUser = async (req, res) => {
  try {
    let token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(400).json({ message: 'Supabase authorization token required in header' });
    }

    const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(token);
    if (error || !supabaseUser) {
      return res.status(401).json({ message: 'Invalid Supabase token: ' + (error?.message || 'Invalid user') });
    }

    let user = await User.findOne({
      $or: [
        { supabaseId: supabaseUser.id },
        { email: supabaseUser.email.toLowerCase() }
      ]
    }).populate('shopId');

    if (!user) {
      return res.status(404).json({ message: 'User profile not found in MongoDB database' });
    }

    if (!user.supabaseId) {
      user.supabaseId = supabaseUser.id;
      await user.save();
    }

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: user.shopId ? user.shopId._id : null,
      shopName: user.shopId ? user.shopId.shopName : '',
      token: token,
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
