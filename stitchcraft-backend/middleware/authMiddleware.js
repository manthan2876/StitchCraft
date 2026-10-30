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
