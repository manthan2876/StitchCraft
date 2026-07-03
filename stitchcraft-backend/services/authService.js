/* services/authService.js */
import User from '../models/User.js';
import Shop from '../models/Shop.js';
import jwt from 'jsonwebtoken';
import ActionLog from '../models/ActionLog.js';

export const generateToken = (id, shopId) => {
  return jwt.sign(
    { id, shopId },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
};

export const registerShopOwner = async (name, email, password, shopName, phone, address) => {
  const userExists = await User.findOne({ email });
  if (userExists) {
    throw new Error('User already exists with this email');
  }

  const user = new User({
    name,
    email,
    password,
    role: 'owner',
  });
  await user.save();

  const shop = new Shop({
    shopName,
    ownerId: user._id,
    phone: phone || '',
    address: address || '',
  });
  await shop.save();

  user.shopId = shop._id;
  await user.save();

  return {
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    avatar: user.avatar,
    shopId: shop._id,
    shopName: shop.shopName,
    token: generateToken(user._id, shop._id),
  };
};

export const loginShopOwner = async (email, password) => {
  const user = await User.findOne({ email }).populate('shopId');
  if (!user) {
    throw new Error('Invalid email or password');
  }

  const isMatch = await user.matchPassword(password);
  if (!isMatch) {
    throw new Error('Invalid email or password');
  }

  if (user.status === 'deleting') {
    const gracePeriodMs = 15 * 24 * 60 * 60 * 1000;
    const timeSinceRequest = Date.now() - new Date(user.deletionRequestedAt).getTime();
    
    if (timeSinceRequest > gracePeriodMs) {
      throw new Error('This account has been permanently deleted.');
    } else {
      user.status = 'active';
      user.deletionRequestedAt = undefined;
      user.deletionReason = undefined;
      user.reactivated = true;
      await user.save();

      await ActionLog.create({
        userId: user._id,
        action: 'REACTIVATE_ACCOUNT',
        details: 'Account successfully reactivated via login within 15-day grace period.',
      });
    }
  }

  return {
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    avatar: user.avatar,
    shopId: user.shopId ? user.shopId._id : null,
    shopName: user.shopId ? user.shopId.shopName : '',
    token: generateToken(user._id, user.shopId ? user.shopId._id : null),
  };
};
