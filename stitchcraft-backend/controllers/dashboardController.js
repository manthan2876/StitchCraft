import Order from '../models/Order.js';
import Customer from '../models/Customer.js';
import Delivery from '../models/Delivery.js';
import Payment from '../models/Payment.js';
import Notification from '../models/Notification.js';
import Karigar from '../models/Karigar.js';
import Machine from '../models/Machine.js';

// @desc    Get dashboard metrics, reminders, and recent orders
// @route   GET /api/dashboard/stats
// @access  Private
export const getDashboardStats = async (req, res) => {
  try {
    const shopId = req.user.shopId;

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    // 1. Today Delivery Count (Pending deliveries due today)
    const todayDeliveryCount = await Delivery.countDocuments({
      shopId,
      status: 'Pending',
      deliveryDate: { $gte: startOfToday, $lte: endOfToday }
    });

    // 2. Late Delivery Count (Pending deliveries due before today)
    const lateDeliveryCount = await Delivery.countDocuments({
      shopId,
      status: 'Pending',
      deliveryDate: { $lt: startOfToday }
    });

    // 3. Incoming Orders Count (Orders with status 'Incoming')
    const incomingOrdersCount = await Order.countDocuments({
      shopId,
      status: 'Incoming'
    });

    // 4. Total Customers Count
    const totalCustomersCount = await Customer.countDocuments({ shopId });

    // 5. Total Revenue (Total paidAmount in Payment collection)
    const payments = await Payment.find({ shopId });
    const totalRevenue = payments.reduce((sum, p) => sum + (p.paidAmount || 0), 0);

    // 6. Recent Orders (Latest 5 orders) - Batch-fetched payment details
    const recentOrders = await Order.find({ shopId })
      .sort({ createdAt: -1 })
      .limit(5);

    const recentOrderIds = recentOrders.map((o) => o._id);
    let recentPayments = [];
    if (recentOrderIds.length > 0) {
      recentPayments = await Payment.find({ orderId: { $in: recentOrderIds }, shopId });
    }
    const recentPaymentMap = new Map();
    for (const p of recentPayments) {
      recentPaymentMap.set(String(p.orderId), p);
    }
    const recentOrdersWithPayments = recentOrders.map((o) => {
      const item = typeof o.toJSON === 'function' ? o.toJSON() : { ...o };
      item.payment = recentPaymentMap.get(String(o._id)) || null;
      return item;
    });

    // 7. Today Reminders / Alerts (Latest 5 alerts)
    const reminders = await Notification.find({ shopId })
      .sort({ createdAt: -1 })
      .limit(5);

    // 8. Daily Stitching Distribution (Single-query weekly window aggregation)
    const current = new Date();
    const currentDay = current.getDay();
    const diffToMonday = currentDay === 0 ? -6 : 1 - currentDay;
    
    const monday = new Date(current);
    monday.setDate(current.getDate() + diffToMonday);
    monday.setHours(0, 0, 0, 0);

    const sundayEnd = new Date(monday);
    sundayEnd.setDate(monday.getDate() + 7);
    sundayEnd.setMilliseconds(sundayEnd.getMilliseconds() - 1);

    const weekCompletedOrders = await Order.find({
      shopId,
      status: { $in: ['Ready', 'Delivered'] },
      updatedAt: { $gte: monday, $lte: sundayEnd },
    });

    const dailyStitching = [0, 0, 0, 0, 0, 0, 0];
    for (const order of weekCompletedOrders) {
      const orderDate = new Date(order.updatedAt || order.createdAt);
      const dayOffset = Math.floor((orderDate - monday) / (24 * 60 * 60 * 1000));
      if (dayOffset >= 0 && dayOffset < 7) {
        dailyStitching[dayOffset] += Number(order.price || 0);
      }
    }

    // 9. Karigar performance metrics (Batch-fetched karigar orders)
    const [karigars, allKarigarOrders] = await Promise.all([
      Karigar.find({ shopId }),
      Order.find({ shopId }),
    ]);

    const karigarOrderMap = new Map();
    for (const o of allKarigarOrders) {
      if (o.assignedKarigar) {
        const kid = String(o.assignedKarigar?._id || o.assignedKarigar);
        if (!karigarOrderMap.has(kid)) karigarOrderMap.set(kid, []);
        karigarOrderMap.get(kid).push(o);
      }
    }

    const karigarPerformance = karigars.map((k) => {
      const kOrders = karigarOrderMap.get(String(k._id)) || [];
      let activeCount = 0;
      let completedCount = 0;
      let completedValue = 0;
      let onTimeCompleted = 0;

      for (let o of kOrders) {
        if (['Ready', 'Delivered'].includes(o.status)) {
          completedCount++;
          completedValue += o.price || 0;
          if (o.updatedAt <= o.deliveryDate) {
            onTimeCompleted++;
          }
        } else {
          activeCount++;
        }
      }

      const onTimeRate = completedCount > 0
        ? Math.round((onTimeCompleted / completedCount) * 100)
        : 100;

      return {
        _id: k._id,
        name: k.name,
        specialization: k.specialization,
        status: k.status,
        activeCount,
        completedCount,
        completedValue,
        onTimeRate,
      };
    });

    // Sort by value created/completed orders
    karigarPerformance.sort((a, b) => b.completedValue - a.completedValue || b.completedCount - a.completedCount);

    // 10. Machine performance metrics (deprecated)
    const machinePerformance = [];

    res.json({
      todayDelivery: todayDeliveryCount,
      lateDelivery: lateDeliveryCount,
      incomingOrders: incomingOrdersCount,
      totalCustomers: totalCustomersCount,
      totalRevenue,
      recentOrders: recentOrdersWithPayments,
      reminders,
      dailyStitching,
      karigarPerformance,
      machinePerformance
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ message: error.message });
  }
};
