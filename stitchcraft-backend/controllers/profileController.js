/* controllers/profileController.js */
import User from '../models/User.js';
import Shop from '../models/Shop.js';
import jwt from 'jsonwebtoken';

// Generate JWT token including shopId in payload
const generateToken = (id, shopId) => {
  return jwt.sign(
    { id, shopId },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
};

// @desc    Get user profile
// @route   GET /api/auth/profile
// @access  Private
export const getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('shopId');

    if (user) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        avatar: user.avatar,
        shopId: user.shopId ? user.shopId._id : null,
        shopName: user.shopId ? user.shopId.shopName : '',
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update user profile details & avatar (profile photo)
// @route   PUT /api/auth/profile
// @access  Private
export const updateUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { name, avatar } = req.body;

    if (name) user.name = name;
    if (avatar !== undefined) user.avatar = avatar;

    const updatedUser = await user.save();
    
    // Populate shop details if linked
    const populated = await User.findById(updatedUser._id).populate('shopId');

    res.json({
      _id: populated._id,
      name: populated.name,
      email: populated.email,
      role: populated.role,
      avatar: populated.avatar,
      shopId: populated.shopId ? populated.shopId._id : null,
      shopName: populated.shopId ? populated.shopId.shopName : '',
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Switch active shop and return new token
// @route   PUT /api/auth/switch-shop/:id
// @access  Private
export const switchActiveShop = async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found or access denied' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.shopId = shop._id;
    await user.save();

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: shop._id,
      shopName: shop.shopName,
      token: generateToken(user._id, shop._id), // return new token
    });
  } catch (error) {
    console.error('Switch shop error:', error);
    res.status(500).json({ message: error.message });
  }
};
