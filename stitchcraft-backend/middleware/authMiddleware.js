import { supabase } from '../config/supabase.js';
import User from '../models/User.js';

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

      // Enforce single-role Owner-only security policy (P0-02)
      const userRole = (user.role || 'owner').toLowerCase();
      if (userRole !== 'owner') {
        return res.status(403).json({
          message: `Forbidden: role '${user.role}' is not authorized. StitchCraft is restricted to shop owners only.`,
        });
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

export const authorize = (...roles) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ message: 'Not authorized, no authenticated user' });
  }

  const userRole = (req.user.role || 'owner').toLowerCase();
  // StitchCraft single-role enforcement (P0-02): Only owner is authorized
  if (userRole !== 'owner') {
    return res.status(403).json({
      message: `Forbidden: role '${userRole}' is not authorized. Owner access required.`,
    });
  }

  next();
};
