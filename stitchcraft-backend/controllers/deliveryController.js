import Delivery from '../models/Delivery.js';
import Order from '../models/Order.js';
import Notification from '../models/Notification.js';

// @desc    Get all delivery listings for a shop grouped by tabs
// @route   GET /api/deliveries
// @access  Private
export const getDeliveries = async (req, res) => {
  try {
    const { tab } = req.query; // 'Today', 'Late', 'Upcoming', 'Delivered'
    
    const filter = { shopId: req.user.shopId };
    
    // Set dates for comparison
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    if (tab === 'Today') {
      filter.status = 'Pending';
      filter.deliveryDate = { $gte: startOfToday, $lte: endOfToday };
    } else if (tab === 'Late') {
      filter.status = 'Pending';
      filter.deliveryDate = { $lt: startOfToday };
    } else if (tab === 'Upcoming') {
      filter.status = 'Pending';
      filter.deliveryDate = { $gt: endOfToday };
    } else if (tab === 'Delivered') {
      filter.status = 'Delivered';
    }

    const deliveries = await Delivery.find(filter)
      .populate({
        path: 'orderId',
        select: 'orderId customerName apparelType status price'
      })
      .sort({ deliveryDate: 1 });

    // Format deliveries for frontend table
    const results = deliveries.map(d => {
      const order = d.orderId || {};
      return {
        _id: d._id,
        id: d._id,
        orderObjId: order._id,
        orderId: order.orderId || 'ORD-UNKNOWN',
        customerName: order.customerName || 'Unknown Customer',
        apparelType: order.apparelType || 'Tailoring',
        deliveryDate: d.deliveryDate,
        status: d.status,
        deliveredBy: d.deliveredBy,
      };
    });

    res.json(results);
  } catch (error) {
    console.error('Get deliveries error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Mark an order as delivered
// @route   PUT /api/deliveries/:id/deliver
// @access  Private
export const markAsDelivered = async (req, res) => {
  try {
    const delivery = await Delivery.findOne({ _id: req.params.id, shopId: req.user.shopId });
    if (!delivery) {
      return res.status(404).json({ message: 'Delivery record not found' });
    }

    delivery.status = 'Delivered';
    delivery.deliveredBy = req.user.name || 'Owner';
    await delivery.save();

    // Sync order status
    const order = await Order.findById(delivery.orderId);
    if (order) {
      order.status = 'Delivered';
      await order.save();

      // Create notification
      await Notification.create({
        shopId: req.user.shopId,
        customerId: order.customer,
        orderId: order._id,
        message: `Order ${order.orderId} marked as Delivered by ${delivery.deliveredBy}.`,
      });
    }

    res.json(delivery);
  } catch (error) {
    console.error('Mark as delivered error:', error);
    res.status(500).json({ message: error.message });
  }
};
