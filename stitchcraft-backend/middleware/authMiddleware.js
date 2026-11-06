import { supabase } from '../config/supabase.js';
import User from '../models/User.js';
import Shop from '../models/Shop.js';

/**
 * Authentication middleware
 * Verifies JWT token from Authorization header and attaches the user and active shop membership context.
 * Supports multi-role authentication (owner, manager, karigar, staff).
 */
export const protect = async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];

      // Get user profile from Supabase Auth using the access token
      const { data: { user: supabaseUser }, error } = await supabase.auth.getUser(token);

      if (error || !supabaseUser) {
        return res.status(401).json({ message: 'Not authorized, Supabase token failed: ' + (error?.message || 'Invalid user') });
      }

      // Find the application profile by Supabase user ID or email
      let user = await User.findOne({
        $or: [
          { supabaseId: supabaseUser.id },
          { email: supabaseUser.email.toLowerCase() }
        ]
      }).select('-password');

      if (!user) {
        return res.status(401).json({ message: 'User profile not found in application database' });
      }

      // Link legacy profiles that do not yet have a Supabase user ID.
      if (!user.supabaseId) {
        user.supabaseId = supabaseUser.id;
        await user.save();
      }

      if (user.status === 'deleting') {
        return res.status(401).json({ message: 'Not authorized, account scheduled for deletion' });
      }

      // Verify active shop membership context and prevent cross-shop tenant boundary leaks
      const requestedShopId = req.headers['x-shop-id'];
      if (requestedShopId) {
        const shop = await Shop.findById(requestedShopId);
        if (!shop) {
          return res.status(404).json({ message: 'Active shop not found' });
        }

        const isOwner = String(shop.ownerId) === String(user._id);
        const isMember = user.shopId && String(user.shopId) === String(requestedShopId);

        if (!isOwner && !isMember) {
          return res.status(403).json({
            message: 'Access denied. Not authorized for this shop.',
          });
        }

        req.shopId = requestedShopId;
      } else if (user.shopId) {
        req.shopId = user.shopId;
      }

      req.user = user;
      next();
    } catch (error) {
      console.error('Auth middleware error:', error);
      res.status(401).json({ message: 'Not authorized, token validation failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token provided' });
  }
};

/**
 * Authorization middleware
 * Enforces role-based permissions according to route specification.
 * Supports multi-role access (e.g. authorize('owner', 'manager')).
 */
export const authorize = (...roles) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Not authorized, no authenticated user' });
  }

  const userRole = (req.user.role || 'staff').toLowerCase();
  const allowedRoles = roles.map((r) => String(r).toLowerCase());

  if (allowedRoles.length > 0 && !allowedRoles.includes(userRole)) {
    return res.status(403).json({
      message: `Forbidden: role '${userRole}' is not authorized. Required: [${roles.join(', ')}].`,
    });
  }

  next();
};
