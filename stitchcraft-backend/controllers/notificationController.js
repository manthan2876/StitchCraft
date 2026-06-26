import Notification from '../models/Notification.js';

// @desc    Get all notifications for a shop
// @route   GET /api/notifications
// @access  Private
export const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ shopId: req.user.shopId })
      .populate('customerId', 'name')
      .populate('orderId', 'orderId')
      .sort({ createdAt: -1 });

    res.json(notifications);
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/mark-read
// @access  Private
export const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ shopId: req.user.shopId, read: false }, { read: true });
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all read error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Mark single notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
export const markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOne({ _id: req.params.id, shopId: req.user.shopId });
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    notification.read = true;
    await notification.save();

    res.json(notification);
  } catch (error) {
    console.error('Mark read error:', error);
    res.status(500).json({ message: error.message });
  }
};
