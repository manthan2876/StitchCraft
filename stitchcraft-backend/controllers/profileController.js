/* controllers/profileController.js */
import User from '../models/User.js';
import Shop from '../models/Shop.js';

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

// @desc    Switch active shop and return updated profile
// @route   PUT /api/auth/switch-shop/:id
// @access  Private
export const switchActiveShop = async (req, res) => {
  try {
    const targetShopId = req.params.id;
    const shop = await Shop.findById(targetShopId);
    if (!shop) {
      return res.status(404).json({ message: 'Shop not found' });
    }

    // Verify authorized membership: user must be the shop owner or an assigned member of this shop
    const isOwner = String(shop.ownerId) === String(req.user._id);
    const isMember = req.user.shopId && String(req.user.shopId) === String(shop._id);

    if (!isOwner && !isMember) {
      return res.status(403).json({ message: 'Access denied. You are not authorized for this shop.' });
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
    });
  } catch (error) {
    console.error('Switch shop error:', error);
    res.status(500).json({ message: error.message });
  }
};
