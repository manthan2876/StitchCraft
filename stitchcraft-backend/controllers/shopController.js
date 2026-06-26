import Shop from '../models/Shop.js';
import User from '../models/User.js';

// @desc    Get all shops owned by the logged-in user
// @route   GET /api/shops
// @access  Private
export const getShops = async (req, res) => {
  try {
    const shops = await Shop.find({ ownerId: req.user._id });
    res.json(shops);
  } catch (error) {
    console.error('Get shops error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a new shop
// @route   POST /api/shops
// @access  Private
export const createShop = async (req, res) => {
  try {
    const { shopName, phone, address, plan } = req.body;

    if (!shopName) {
      return res.status(400).json({ message: 'Shop name is required' });
    }

    const shop = await Shop.create({
      shopName,
      phone: phone || '',
      address: address || '',
      plan: plan || 'Free',
      ownerId: req.user._id,
      email: req.user.email || '',
      isActive: true
    });

    // If the user currently has no active shopId, set this new one as active
    const user = await User.findById(req.user._id);
    if (user && !user.shopId) {
      user.shopId = shop._id;
      await user.save();
    }

    res.status(201).json(shop);
  } catch (error) {
    console.error('Create shop error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get details of a single shop
// @route   GET /api/shops/:id
// @access  Private
export const getShopById = async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });

    if (!shop) {
      return res.status(404).json({ message: 'Shop not found or access denied' });
    }

    res.json(shop);
  } catch (error) {
    console.error('Get shop error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a shop
// @route   PUT /api/shops/:id
// @access  Private
export const updateShop = async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });

    if (!shop) {
      return res.status(404).json({ message: 'Shop not found or access denied' });
    }

    const { shopName, phone, address, plan, isActive } = req.body;

    if (shopName) shop.shopName = shopName;
    if (phone !== undefined) shop.phone = phone;
    if (address !== undefined) shop.address = address;
    if (plan) shop.plan = plan;
    if (isActive !== undefined) shop.isActive = isActive;

    const updatedShop = await shop.save();
    res.json(updatedShop);
  } catch (error) {
    console.error('Update shop error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a shop
// @route   DELETE /api/shops/:id
// @access  Private
export const deleteShop = async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });

    if (!shop) {
      return res.status(404).json({ message: 'Shop not found or access denied' });
    }

    // Check if user owns multiple shops or if this is their only shop
    const userShopsCount = await Shop.countDocuments({ ownerId: req.user._id });
    if (userShopsCount <= 1) {
      return res.status(400).json({ message: 'Cannot delete your only shop. StitchCraft requires at least one shop profile.' });
    }

    await Shop.deleteOne({ _id: shop._id });

    // Cascade: If deleted shop was user's active session shopId, switch to another owned shop
    const user = await User.findById(req.user._id);
    if (user && user.shopId && user.shopId.toString() === shop._id.toString()) {
      const remainingShop = await Shop.findOne({ ownerId: req.user._id });
      user.shopId = remainingShop ? remainingShop._id : null;
      await user.save();
    }

    res.json({ message: 'Shop deleted successfully' });
  } catch (error) {
    console.error('Delete shop error:', error);
    res.status(500).json({ message: error.message });
  }
};
