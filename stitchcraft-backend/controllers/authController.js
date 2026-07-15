import User from '../models/User.js';
import Shop from '../models/Shop.js';
import { supabase } from '../config/supabase.js';

// @desc    Register a new shop owner and create a shop
// @route   POST /api/auth/register
// @access  Public
export const registerUser = async (req, res) => {
  try {
    const { name, email, password, shopName, phone, address } = req.body;
    let token = req.headers.authorization?.split(' ')[1];
    let supabaseUser;

    if (token) {
      const { data: { user }, error } = await supabase.auth.getUser(token);
      if (error || !user) {
        return res.status(401).json({ message: 'Invalid Supabase token: ' + (error?.message || 'Invalid user') });
      }
      supabaseUser = user;
    } else {
      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, shopName, phone, address }
        }
      });
      if (error) {
        return res.status(400).json({ message: error.message });
      }
      supabaseUser = data.user;
      token = data.session?.access_token;
    }

    if (!supabaseUser) {
      return res.status(400).json({ message: 'Failed to create user in Supabase' });
    }

    // If signed up via client SDK and confirmation is required, token is null and email_confirmed_at is not set
    if (!token && !supabaseUser.email_confirmed_at) {
      return res.status(201).json({
        message: 'Please check your email to verify your account before logging in.',
        requiresVerification: true
      });
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
      shopName: shopName || supabaseUser.user_metadata?.shopName || `${user.name}'s Shop`,
      ownerId: user._id,
      phone: phone || supabaseUser.user_metadata?.phone || '',
      address: address || supabaseUser.user_metadata?.address || '',
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
    const { email, password } = req.body;
    let token = req.headers.authorization?.split(' ')[1];
    let supabaseUser;

    if (token) {
      const { data: { user }, error } = await supabase.auth.getUser(token);
      if (error || !user) {
        return res.status(401).json({ message: 'Invalid Supabase token: ' + (error?.message || 'Invalid user') });
      }
      supabaseUser = user;
    } else {
      if (!email || !password) {
        return res.status(400).json({ message: 'Supabase authorization token in header or Email & Password in body required' });
      }
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) {
        return res.status(400).json({ message: error.message });
      }
      supabaseUser = data.user;
      token = data.session?.access_token;
    }

    let user = await User.findOne({
      $or: [
        { supabaseId: supabaseUser.id },
        { email: supabaseUser.email.toLowerCase() }
      ]
    }).populate('shopId');

    if (!user) {
      const emailLower = supabaseUser.email.toLowerCase();
      const name = supabaseUser.user_metadata?.name || 'Shop Owner';
      const shopName = supabaseUser.user_metadata?.shopName || `${name}'s Shop`;
      const phone = supabaseUser.user_metadata?.phone || '';
      const address = supabaseUser.user_metadata?.address || '';

      user = new User({
        name,
        email: emailLower,
        role: 'owner',
        supabaseId: supabaseUser.id,
        password: 'SUPABASE_MANAGED_PASSWORD_PLACEHOLDER'
      });
      await user.save();

      const shop = new Shop({
        shopName,
        ownerId: user._id,
        phone,
        address,
      });
      await shop.save();

      user.shopId = shop._id;
      await user.save();

      // Set shop populated reference for response
      user.shopId = shop;
    } else if (!user.supabaseId) {
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

// @desc    Verify email using OTP token or link token_hash
// @route   POST /api/auth/verify
// @access  Public
export const verifyEmail = async (req, res) => {
  try {
    const { email, token, type } = req.body;
    if (!email || !token) {
      return res.status(400).json({ message: 'Email and verification token are required' });
    }

    let verificationToken = token;
    if (token.startsWith('http://') || token.startsWith('https://')) {
      try {
        const urlObj = new URL(token);
        const tokenParam = urlObj.searchParams.get('token');
        if (tokenParam) {
          verificationToken = tokenParam;
        }
      } catch (e) {
        // Fallback to original token
      }
    }

    // Verify OTP/Token via Supabase
    let verificationParams = {};
    if (verificationToken.length <= 10) {
      verificationParams = {
        email,
        token: verificationToken,
        type: type || 'signup',
      };
    } else {
      verificationParams = {
        token_hash: verificationToken,
        type: type || 'signup',
      };
    }

    const { data, error } = await supabase.auth.verifyOtp(verificationParams);

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    const supabaseUser = data.user;
    const sessionToken = data.session?.access_token;

    if (!supabaseUser) {
      return res.status(400).json({ message: 'Verification succeeded but no user returned' });
    }

    const emailLower = supabaseUser.email.toLowerCase();
    let user = await User.findOne({
      $or: [
        { supabaseId: supabaseUser.id },
        { email: emailLower }
      ]
    }).populate('shopId');

    if (!user) {
      const name = supabaseUser.user_metadata?.name || 'Shop Owner';
      const shopName = supabaseUser.user_metadata?.shopName || `${name}'s Shop`;
      const phone = supabaseUser.user_metadata?.phone || '';
      const address = supabaseUser.user_metadata?.address || '';

      user = new User({
        name,
        email: emailLower,
        role: 'owner',
        supabaseId: supabaseUser.id,
        password: 'SUPABASE_MANAGED_PASSWORD_PLACEHOLDER'
      });
      await user.save();

      const shop = new Shop({
        shopName,
        ownerId: user._id,
        phone,
        address,
      });
      await shop.save();

      user.shopId = shop._id;
      await user.save();

      // Populate reference for response
      user.shopId = shop;
    }

    res.json({
      message: 'Email verified successfully and profile provisioned!',
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatar: user.avatar,
      shopId: user.shopId ? user.shopId._id : null,
      shopName: user.shopId ? user.shopId.shopName : '',
      token: sessionToken,
    });
  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ message: error.message });
  }
};
