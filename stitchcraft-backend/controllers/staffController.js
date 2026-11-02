/* controllers/staffController.js */
import User from '../models/User.js';
import { escapeRegex } from '../middleware/securityMiddleware.js';

// @desc    Get all staff members for the authenticated shop
// @route   GET /api/staff
// @access  Private (Owner, Manager)
export const getStaff = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop associated with user session' });
    }

    const staffMembers = await User.find({ shopId }).select('-password').sort({ createdAt: -1 });

    res.json(staffMembers.map(member => ({
      _id: member._id,
      name: member.name,
      email: member.email,
      phone: member.phone || '',
      role: member.role || 'staff',
      isActive: member.isActive !== false,
      createdAt: member.createdAt,
      lastLogin: member.lastLogin,
      isOwner: member.role === 'owner' || String(member._id) === String(req.user._id && req.user.role === 'owner' ? req.user._id : ''),
    })));
  } catch (error) {
    console.error('Get staff error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add or invite a staff member to the shop
// @route   POST /api/staff
// @access  Private (Owner, Manager)
export const addStaff = async (req, res) => {
  try {
    const shopId = req.user.shopId;
    if (!shopId) {
      return res.status(400).json({ message: 'No active shop associated with user session' });
    }

    const { name, email, role, phone } = req.body;

    if (!name || !email) {
      return res.status(400).json({ message: 'Staff name and email are required' });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    const cleanRole = role && ['manager', 'karigar', 'staff'].includes(role) ? role : 'staff';

    // Only owner can appoint a manager
    if (cleanRole === 'manager' && req.user.role !== 'owner') {
      return res.status(403).json({ message: 'Only shop owners can assign the manager role' });
    }

    // Check if user already exists
    let existingUser = await User.findOne({ email: cleanEmail });
    if (existingUser) {
      if (existingUser.shopId && String(existingUser.shopId) === String(shopId)) {
        return res.status(400).json({ message: 'A team member with this email is already in your shop' });
      }

      // Associate existing user with this shop
      existingUser.shopId = shopId;
      existingUser.role = cleanRole;
      if (phone && !existingUser.phone) existingUser.phone = phone;
      existingUser.isActive = true;
      await existingUser.save();

      return res.status(200).json({
        message: 'Staff member added to shop successfully',
        staff: {
          _id: existingUser._id,
          name: existingUser.name,
          email: existingUser.email,
          phone: existingUser.phone || '',
          role: existingUser.role,
          isActive: existingUser.isActive,
        }
      });
    }

    // Create new staff profile
    const newStaff = await User.create({
      name: String(name).trim(),
      email: cleanEmail,
      phone: phone ? String(phone).trim() : '',
      role: cleanRole,
      shopId,
      isActive: true,
      emailConfirmed: false,
    });

    res.status(201).json({
      message: 'Staff member profile created successfully',
      staff: {
        _id: newStaff._id,
        name: newStaff.name,
        email: newStaff.email,
        phone: newStaff.phone || '',
        role: newStaff.role,
        isActive: newStaff.isActive,
      }
    });
  } catch (error) {
    console.error('Add staff error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update staff role
// @route   PUT /api/staff/:id/role
// @access  Private (Owner only)
export const updateStaffRole = async (req, res) => {
  try {
    const { role } = req.body;
    const { id } = req.params;

    if (!role || !['manager', 'karigar', 'staff'].includes(role)) {
      return res.status(400).json({ message: 'Valid role is required (manager, karigar, staff)' });
    }

    if (String(id) === String(req.user._id)) {
      return res.status(400).json({ message: 'Cannot change your own role as owner' });
    }

    const staffMember = await User.findOne({ _id: id, shopId: req.user.shopId });
    if (!staffMember) {
      return res.status(404).json({ message: 'Staff member not found in your shop' });
    }

    staffMember.role = role;
    await staffMember.save();

    res.json({
      message: `Staff role updated to ${role}`,
      staff: {
        _id: staffMember._id,
        name: staffMember.name,
        email: staffMember.email,
        role: staffMember.role,
        isActive: staffMember.isActive,
      }
    });
  } catch (error) {
    console.error('Update staff role error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Toggle staff active status (deactivate or reactivate)
// @route   PUT /api/staff/:id/status
// @access  Private (Owner, Manager)
export const updateStaffStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    if (String(id) === String(req.user._id)) {
      return res.status(400).json({ message: 'Cannot deactivate your own account' });
    }

    const staffMember = await User.findOne({ _id: id, shopId: req.user.shopId });
    if (!staffMember) {
      return res.status(404).json({ message: 'Staff member not found in your shop' });
    }

    // Manager cannot deactivate an owner or another manager
    if (req.user.role === 'manager' && (staffMember.role === 'owner' || staffMember.role === 'manager')) {
      return res.status(403).json({ message: 'Managers cannot modify status of owners or managers' });
    }

    staffMember.isActive = Boolean(isActive);
    await staffMember.save();

    res.json({
      message: `Staff member ${staffMember.isActive ? 'activated' : 'deactivated'} successfully`,
      staff: {
        _id: staffMember._id,
        name: staffMember.name,
        email: staffMember.email,
        role: staffMember.role,
        isActive: staffMember.isActive,
      }
    });
  } catch (error) {
    console.error('Update staff status error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Remove staff member from shop
// @route   DELETE /api/staff/:id
// @access  Private (Owner only)
export const removeStaff = async (req, res) => {
  try {
    const { id } = req.params;

    if (String(id) === String(req.user._id)) {
      return res.status(400).json({ message: 'Cannot remove yourself as shop owner' });
    }

    const staffMember = await User.findOne({ _id: id, shopId: req.user.shopId });
    if (!staffMember) {
      return res.status(404).json({ message: 'Staff member not found in your shop' });
    }

    // Unlink staff member from the shop
    staffMember.shopId = null;
    staffMember.role = 'staff';
    await staffMember.save();

    res.json({ message: 'Staff member removed from shop' });
  } catch (error) {
    console.error('Remove staff error:', error);
    res.status(500).json({ message: error.message });
  }
};

