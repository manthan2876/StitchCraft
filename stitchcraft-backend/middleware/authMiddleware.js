import { supabase } from '../config/supabase.js';
import User from '../models/User.js';
import Shop from '../models/Shop.js';
import { PERMISSIONS, ROLE_PERMISSIONS, hasPermission } from '../config/permissions.js';

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

      if (user.isActive === false || user.status === 'revoked' || user.status === 'inactive') {
        return res.status(401).json({ message: 'Not authorized, user membership is inactive or has been revoked' });
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

/**
 * Permission-based Authorization Middleware (Phase 4, 8.1)
 * Enforces that user's role has ALL required permissions.
 * Owner role with '*' is universally granted access.
 */
export const requirePermission = (...permissions) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Not authorized, no authenticated user' });
  }

  if (req.user.isActive === false || req.user.status === 'revoked' || req.user.status === 'inactive' || req.user.status === 'deleting') {
    return res.status(403).json({
      message: 'Forbidden: your membership in this shop is inactive or has been revoked.',
    });
  }

  const role = (req.user.role || 'staff').toLowerCase();
  const userPermissions = ROLE_PERMISSIONS[role] || [];

  if (userPermissions.includes('*')) {
    return next();
  }

  const missingPermissions = permissions.filter((perm) => !userPermissions.includes(perm));
  if (missingPermissions.length > 0) {
    return res.status(403).json({
      message: `Forbidden: role '${role}' lacks required permission [${missingPermissions.join(', ')}].`,
    });
  }

  next();
};

/**
 * Disjunctive Permission-based Authorization Middleware (Phase 4, 8.1)
 * Enforces that user's role has AT LEAST ONE of the required permissions.
 */
export const requireAnyPermission = (...permissions) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Not authorized, no authenticated user' });
  }

  if (req.user.isActive === false || req.user.status === 'revoked' || req.user.status === 'inactive' || req.user.status === 'deleting') {
    return res.status(403).json({
      message: 'Forbidden: your membership in this shop is inactive or has been revoked.',
    });
  }

  const role = (req.user.role || 'staff').toLowerCase();
  const userPermissions = ROLE_PERMISSIONS[role] || [];

  if (userPermissions.includes('*')) {
    return next();
  }

  const hasAny = permissions.some((perm) => userPermissions.includes(perm));
  if (!hasAny) {
    return res.status(403).json({
      message: `Forbidden: role '${role}' lacks required permissions [${permissions.join(' or ')}].`,
    });
  }

  next();
};
